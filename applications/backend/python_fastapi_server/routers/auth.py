"""Authentication router with registration, login, and token management."""
from fastapi import APIRouter, Depends, HTTPException, status, Header, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
from datetime import datetime
import uuid
from database import get_db, get_cursor
from logging_config import get_logger
import metrics
from slowapi import Limiter
from slowapi.util import get_remote_address
from settings import get_settings

log = get_logger("api.auth")
limiter = Limiter(key_func=get_remote_address)
from auth_service import (
    UserCreate, UserLogin, User, Token, TokenData,
    get_password_hash, verify_password,
    create_access_token, create_refresh_token, decode_token
)
from redis_client import is_token_blacklisted, blacklist_token
import time

router = APIRouter(prefix="/auth", tags=["authentication"])
security = HTTPBearer(auto_error=False)  # Don't auto-error so we can handle dev mode


def get_current_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> TokenData:
    """Dependency to extract and validate current user from JWT token.

    In development mode with DISABLE_AUTH=true, returns a stub user without authentication.
    """
    settings = get_settings()

    # Development mode bypass
    if settings.disable_auth and settings.environment == "development":
        log.info("auth_bypassed_dev_mode", extra={"stub_user": "user-123"})
        return TokenData(
            user_id="user-123",
            email="dev@example.com",
            jti="dev-stub-token",
            exp=None
        )

    # Production mode - require authentication
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_403_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    token_data = decode_token(token)
    if token_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if token is blacklisted
    if token_data.jti and is_token_blacklisted(token_data.jti):
        log.warning("auth_token_blacklisted", extra={"jti": token_data.jti, "user_id": token_data.user_id})
        metrics.record_domain_event("auth_token_blacklisted")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return token_data


def get_user_by_email(email: str):
    """Fetch user from database by email."""
    with get_db() as conn:
        cur = get_cursor(conn)
        cur.execute("SELECT * FROM users WHERE email = ?", (email,))
        row = cur.fetchone()
        if row:
            return dict(row)
    return None


def get_user_by_id(user_id: str):
    """Fetch user from database by ID."""
    with get_db() as conn:
        cur = get_cursor(conn)
        cur.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        row = cur.fetchone()
        if row:
            return dict(row)
    return None


def create_user(user: UserCreate, registration_code: str) -> dict:
    """Create new user in database."""
    user_id = str(uuid.uuid4())
    hashed_password = get_password_hash(user.password)
    
    with get_db() as conn:
        cur = get_cursor(conn)
        cur.execute(
            """INSERT INTO users (id, email, hashed_password, full_name, is_active, created_at, updated_at)
               VALUES (?, ?, ?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)""",
            (user_id, user.email, hashed_password, user.full_name)
        )
        cur.execute("UPDATE registration_codes SET is_used = 1, used_by_user_id = ? WHERE code = ?", (user_id, registration_code))
        conn.commit()
    
    return get_user_by_id(user_id)


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register(request: Request, user: UserCreate):
    """Register a new user account."""
    # Check if user already exists
    existing_user = get_user_by_email(user.email)
    if existing_user:
        log.warning("auth_register_email_exists", extra={"email": user.email})
        metrics.record_domain_event("auth_register_email_exists")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Check for valid registration code
    with get_db() as conn:
        cur = get_cursor(conn)
        cur.execute("SELECT * FROM registration_codes WHERE code = ? AND is_used = 0", (user.registration_code,))
        code_row = cur.fetchone()
        if not code_row:
            log.warning("auth_register_invalid_code", extra={"email": user.email, "code": user.registration_code})
            metrics.record_domain_event("auth_register_invalid_code")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or used registration code."
            )
    
    # Create user
    db_user = create_user(user, user.registration_code)
    
    # Generate tokens
    access_token = create_access_token(data={"sub": db_user["id"], "email": db_user["email"]})
    refresh_token = create_refresh_token(data={"sub": db_user["id"], "email": db_user["email"]})
    
    log.info("auth_register_success", extra={"user_id": db_user["id"], "email": db_user["email"]})
    metrics.record_domain_event("auth_register_success")
    return Token(access_token=access_token, refresh_token=refresh_token)


@router.post("/login", response_model=Token)
@limiter.limit("10/minute")
async def login(request: Request, credentials: UserLogin):
    """Authenticate user and return JWT tokens."""
    # Find user
    user = get_user_by_email(credentials.email)
    if not user:
        log.warning("auth_login_invalid_email", extra={"email": credentials.email})
        metrics.record_domain_event("auth_login_invalid_email")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Verify password
    if not verify_password(credentials.password, user["hashed_password"]):
        log.warning("auth_login_bad_password", extra={"email": credentials.email})
        metrics.record_domain_event("auth_login_bad_password")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Check if user is active
    if not user["is_active"]:
        log.warning("auth_login_inactive", extra={"user_id": user["id"]})
        metrics.record_domain_event("auth_login_inactive")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive"
        )
    
    # Generate tokens
    access_token = create_access_token(data={"sub": user["id"], "email": user["email"]})
    refresh_token = create_refresh_token(data={"sub": user["id"], "email": user["email"]})
    
    log.info("auth_login_success", extra={"user_id": user["id"], "email": user["email"]})
    metrics.record_domain_event("auth_login_success")
    return Token(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=Token)
@limiter.limit("20/minute")
async def refresh_token(request: Request, credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Refresh access token using refresh token."""
    token = credentials.credentials
    token_data = decode_token(token)
    
    if token_data is None:
        log.warning("auth_refresh_invalid_token")
        metrics.record_domain_event("auth_refresh_invalid_token")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    # Verify user still exists and is active
    user = get_user_by_id(token_data.user_id)
    if not user or not user["is_active"]:
        log.warning("auth_refresh_user_invalid", extra={"user_id": token_data.user_id})
        metrics.record_domain_event("auth_refresh_user_invalid")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    # Generate new tokens
    access_token = create_access_token(data={"sub": user["id"], "email": user["email"]})
    refresh_token = create_refresh_token(data={"sub": user["id"], "email": user["email"]})
    
    log.info("auth_refresh_success", extra={"user_id": user["id"]})
    metrics.record_domain_event("auth_refresh_success")
    return Token(access_token=access_token, refresh_token=refresh_token)


@router.get("/me", response_model=User)
async def get_current_user_info(current_user: TokenData = Depends(get_current_user)):
    """Get current authenticated user information."""
    user = get_user_by_id(current_user.user_id)
    if not user:
        log.warning("auth_me_not_found", extra={"user_id": current_user.user_id})
        metrics.record_domain_event("auth_me_not_found")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return User(
        id=user["id"],
        email=user["email"],
        full_name=user.get("full_name"),
        is_active=bool(user["is_active"]),
        created_at=user["created_at"]
    )


@router.post("/logout")
async def logout(current_user: TokenData = Depends(get_current_user)):
    """Logout user and blacklist the current token."""
    # Blacklist the token using its JTI
    if current_user.jti and current_user.exp:
        # Calculate TTL (time until token naturally expires)
        now = int(time.time())
        ttl_seconds = max(current_user.exp - now, 60)  # Minimum 60 seconds

        # Add token to blacklist
        blacklist_success = blacklist_token(current_user.jti, ttl_seconds)

        if blacklist_success:
            log.info("auth_logout_blacklisted", extra={
                "user_id": current_user.user_id,
                "jti": current_user.jti,
                "ttl": ttl_seconds
            })
        else:
            log.warning("auth_logout_blacklist_failed", extra={
                "user_id": current_user.user_id,
                "jti": current_user.jti
            })

    log.info("auth_logout", extra={"user_id": current_user.user_id})
    metrics.record_domain_event("auth_logout")
    return {"message": "Successfully logged out"}
