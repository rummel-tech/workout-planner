# Workout Planner - Security

**Version:** 1.0
**Last Updated:** 2024-12-24

---

## Overview

This document outlines the security architecture, requirements, and best practices for the Workout Planner platform.

## Authentication

### JWT Token Strategy

The system uses JSON Web Tokens (JWT) for stateless authentication.

**Token Types:**
| Type | Expiry | Purpose |
|------|--------|---------|
| Access Token | 24 hours | API authentication |
| Refresh Token | 30 days | Obtain new access tokens |

**Token Structure:**
```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "exp": 1704067200,
  "iat": 1703980800,
  "jti": "unique_token_id",
  "type": "access"
}
```

**Algorithm:** HS256 (HMAC-SHA256)

### Token Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │     │    API      │     │   Redis     │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │  POST /auth/login │                   │
       │──────────────────>│                   │
       │                   │                   │
       │  access + refresh │                   │
       │<──────────────────│                   │
       │                   │                   │
       │  GET /api (Bearer)│                   │
       │──────────────────>│                   │
       │                   │  Check blacklist  │
       │                   │──────────────────>│
       │                   │<──────────────────│
       │                   │                   │
       │  Response         │                   │
       │<──────────────────│                   │
       │                   │                   │
       │  POST /auth/logout│                   │
       │──────────────────>│                   │
       │                   │  Add to blacklist │
       │                   │──────────────────>│
       │                   │<──────────────────│
       │  Success          │                   │
       │<──────────────────│                   │
```

### Token Blacklisting

When a user logs out, their token's JTI is added to a Redis blacklist:

```python
# Blacklist entry
Key: "blacklist:{jti}"
Value: "1"
TTL: Token expiration time remaining
```

Every authenticated request checks the blacklist before proceeding.

### Password Security

**Hashing:**
- Algorithm: bcrypt
- Salt: Auto-generated per password
- Work factor: 12 rounds (default)

**Validation:**
- Minimum length: 8 characters
- Maximum length: 72 bytes (bcrypt limit)
- UTF-8 encoding validated before hashing

```python
# Password hashing flow
password → validate UTF-8 → bcrypt.hash(password, salt) → store hash
```

---

## Authorization

### Role-Based Access

| Role | Capabilities |
|------|-------------|
| User | Access own data, manage own goals/workouts |
| Admin | All user capabilities + manage registration codes, view waitlist |

### Resource Ownership

All user data is scoped by `user_id`:
- Users can only access their own data
- API validates `user_id` parameter matches authenticated user
- Admin endpoints have separate authorization checks

---

## API Security

### CORS Configuration

**Development:**
```python
CORS_ORIGINS = ["*"]  # Allow all origins
```

**Production:**
```python
CORS_ORIGINS = [
    "https://app.workoutplanner.com",
    "https://staging.workoutplanner.com"
]
```

### Security Headers

The API includes security headers on all responses:

```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains  # Production only
```

### Rate Limiting

| Endpoint | Development | Production |
|----------|-------------|------------|
| POST /auth/register | 10000/min | 5/min |
| POST /auth/login | 10000/min | 10/min |
| POST /auth/refresh | 10000/min | 10/min |
| GET /readiness | 10000/min | 60/min |
| All others | 10000/min | 100/min |

Rate limit responses return `429 Too Many Requests`.

### Input Validation

All API inputs are validated using Pydantic models:

```python
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)
    full_name: Optional[str] = Field(max_length=100)
    registration_code: Optional[str] = Field(max_length=50)
```

### SQL Injection Prevention

- All database queries use parameterized statements
- No string concatenation in SQL queries
- ORM queries preferred where possible

---

## Data Security

### Sensitive Data Storage

**Frontend (Flutter):**
```dart
// Secure storage for tokens and API keys
final storage = FlutterSecureStorage();

// Storing
await storage.write(key: 'access_token', value: token);

// Retrieving
final token = await storage.read(key: 'access_token');
```

**Backend:**
- Passwords stored as bcrypt hashes only
- JWT secret stored in environment variable
- Production secrets from AWS Secrets Manager

### Data in Transit

- All production traffic over HTTPS (TLS 1.2+)
- HTTP requests redirected to HTTPS
- Certificate managed by load balancer

### Data at Rest

- Database encryption handled by cloud provider (RDS)
- Redis data encrypted at rest (ElastiCache)
- Backup encryption enabled

---

## Environment Security

### Required Environment Variables

| Variable | Description | Required In |
|----------|-------------|-------------|
| JWT_SECRET | Token signing key (32+ chars) | Production |
| DATABASE_URL | Database connection string | All |
| REDIS_URL | Redis connection string | Production |

### Production Enforcement

```python
# settings.py
if ENVIRONMENT == "production":
    assert DATABASE_URL.startswith("postgresql://"), "Production must use PostgreSQL"
    assert JWT_SECRET and len(JWT_SECRET) >= 32, "Production requires strong JWT secret"
    assert DISABLE_AUTH == False, "Cannot disable auth in production"
```

### Development Mode

```python
# Development-only features
DISABLE_AUTH = True  # Allows unauthenticated access (dev only)
DEBUG = True         # Verbose error messages
```

---

## Registration Security

### Registration Code System

Access is controlled via registration codes:

```
User Registration Flow:
1. User enters email, password, registration code
2. System validates code:
   - Exists in database
   - Not already used
   - Not expired
3. If valid: Create account, mark code as used
4. If invalid: Add to waitlist
```

**Code Properties:**
- Unique alphanumeric string
- Optional expiration date
- Single use only
- Tracks: who distributed, when, to whom

### Waitlist

Users without valid codes are added to waitlist:
- Email stored for future invitation
- Admin can generate codes and invite
- Prevents unauthorized mass signups

---

## Logging & Monitoring

### Security Logging

All authentication events are logged:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "event": "login_success",
  "user_id": "uuid",
  "ip": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "request_id": "abc123"
}
```

**Logged Events:**
- Login success/failure
- Registration attempts
- Token refresh
- Logout
- Admin actions
- Rate limit violations

### Correlation IDs

Every request includes a correlation ID for tracing:

```http
X-Request-ID: abc123-def456-ghi789
```

---

## Security Checklist

### Development

- [ ] Use HTTPS in local development (optional but recommended)
- [ ] Never commit secrets to version control
- [ ] Use `.env` files for local configuration
- [ ] Test with DISABLE_AUTH=false before deploying

### Production Deployment

- [ ] JWT_SECRET is strong (32+ random characters)
- [ ] DATABASE_URL uses PostgreSQL
- [ ] DISABLE_AUTH is false
- [ ] CORS_ORIGINS is restrictive
- [ ] Rate limiting is enabled
- [ ] Security headers are configured
- [ ] HTTPS is enforced
- [ ] Secrets are in AWS Secrets Manager
- [ ] Logging is enabled
- [ ] Monitoring/alerting is configured

### Ongoing

- [ ] Rotate JWT_SECRET periodically
- [ ] Review access logs for anomalies
- [ ] Update dependencies for security patches
- [ ] Conduct periodic security reviews
- [ ] Test authentication flows after changes

---

## Incident Response

### Token Compromise

If tokens are suspected compromised:

1. **Immediate:** Add affected JTIs to blacklist
2. **Short-term:** Force logout affected users
3. **Long-term:** Rotate JWT_SECRET (invalidates all tokens)

### Database Breach

If database is compromised:

1. **Immediate:** Rotate all secrets
2. **Short-term:** Force password reset for all users
3. **Long-term:** Review access controls, enable additional logging

### API Key Leak

If AI provider keys are leaked:

1. **Immediate:** Revoke key at provider
2. **Short-term:** Generate new key, update configuration
3. **Long-term:** Review key storage practices

---

## Compliance Considerations

### Data Handling

- Health data is user-owned
- Provide data export capability (planned)
- Implement data deletion on request
- Minimize data collection

### Third-Party Services

| Service | Data Shared | Purpose |
|---------|-------------|---------|
| OpenAI | Chat messages, goals, health summary | AI coaching |
| Anthropic | Chat messages, goals, health summary | AI coaching |
| HealthKit | Read-only access | Health data sync |

Users must consent to AI provider usage during setup.
