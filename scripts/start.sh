#!/bin/bash
# Workout Planner - Development Start Script
# This script configures and starts the Flutter app with backend connection
#
# The backend API runs from the services project:
#   /home/shawn/_Projects/services/workout-planner/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env file if it exists
load_env_file() {
    local env_file="$PROJECT_DIR/.env"
    if [[ -f "$env_file" ]]; then
        print_info "Loading configuration from .env file"
        # Export variables from .env (skip comments and empty lines)
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            # Remove leading/trailing whitespace from key
            key=$(echo "$key" | xargs)
            # Remove surrounding quotes from value
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            # Only export if not already set
            if [[ -z "${!key}" ]]; then
                export "$key=$value"
            fi
        done < "$env_file"
    fi
}

# Pre-load env file before setting defaults (so env file values take precedence over defaults)
if [[ -f "$PROJECT_DIR/.env" ]]; then
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        if [[ -z "${!key}" ]]; then
            export "$key=$value"
        fi
    done < "$PROJECT_DIR/.env"
fi

SERVICES_DIR="${SERVICES_DIR:-$HOME/_Projects/services}"
BACKEND_DIR="$SERVICES_DIR/workout-planner"

# Default configuration
DEFAULT_API_URL="http://localhost:8000"
DEFAULT_WEB_PORT="8080"
DEFAULT_PLATFORM="web"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}       Workout Planner - Development${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --platform PLATFORM   Target platform: web, chrome, android, ios, linux (default: web)"
    echo "  -u, --api-url URL         Backend API URL (default: $DEFAULT_API_URL)"
    echo "  -w, --web-port PORT       Web server port (default: $DEFAULT_WEB_PORT)"
    echo "  -e, --email EMAIL         Email for auto-login (optional)"
    echo "  -P, --password PASSWORD   Password for auto-login (optional)"
    echo "  -r, --register            Register new account instead of login"
    echo "  -c, --check-backend       Only check backend connectivity"
    echo "  -s, --start-backend       Start the backend service first"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  API_BASE_URL              Override backend API URL"
    echo "  SERVICES_DIR              Services project location (default: ~/\_Projects/services)"
    echo "  WORKOUT_PLANNER_EMAIL     Default email for authentication"
    echo "  WORKOUT_PLANNER_PASSWORD  Default password for authentication"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start web app with defaults"
    echo "  $0 -p chrome                          # Start in Chrome browser"
    echo "  $0 -s                                 # Start backend first, then app"
    echo "  $0 -u http://api.example.com:8000     # Use custom backend"
    echo "  $0 -e user@example.com -P mypassword  # Auto-authenticate"
    echo "  $0 -c                                 # Check backend only"
    echo ""
    echo "Backend Service:"
    echo "  The backend runs from the services project at:"
    echo "  $BACKEND_DIR"
    echo ""
    echo "  To start manually:"
    echo "    cd $BACKEND_DIR"
    echo "    source .venv/bin/activate"
    echo "    uvicorn main:app --reload --port 8000"
}

# Parse command line arguments (env vars take precedence over defaults)
PLATFORM="${PLATFORM:-$DEFAULT_PLATFORM}"
API_URL="${API_BASE_URL:-$DEFAULT_API_URL}"
WEB_PORT="${WEB_PORT:-$DEFAULT_WEB_PORT}"
EMAIL="${WORKOUT_PLANNER_EMAIL:-}"
PASSWORD="${WORKOUT_PLANNER_PASSWORD:-}"
REGISTER_MODE=false
CHECK_ONLY=false
START_BACKEND=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -u|--api-url)
            API_URL="$2"
            shift 2
            ;;
        -w|--web-port)
            WEB_PORT="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -P|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -r|--register)
            REGISTER_MODE=true
            shift
            ;;
        -c|--check-backend)
            CHECK_ONLY=true
            shift
            ;;
        -s|--start-backend)
            START_BACKEND=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Start backend service
start_backend() {
    if [[ ! -d "$BACKEND_DIR" ]]; then
        print_error "Backend directory not found: $BACKEND_DIR"
        print_info "Set SERVICES_DIR environment variable to your services project location"
        return 1
    fi

    print_info "Starting backend service..."

    cd "$BACKEND_DIR"

    # Check for virtual environment
    if [[ ! -d ".venv" ]]; then
        print_info "Creating virtual environment..."
        python3 -m venv .venv
    fi

    # Start in background
    (
        source .venv/bin/activate
        pip install -q -r requirements.txt 2>/dev/null || true
        pip install -q -e ../common 2>/dev/null || true
        uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
    ) &

    # Wait for backend to be ready
    print_info "Waiting for backend to start..."
    for i in {1..30}; do
        if curl -s --connect-timeout 1 "$API_URL/health" > /dev/null 2>&1; then
            print_success "Backend started successfully"
            return 0
        fi
        sleep 1
    done

    print_error "Backend failed to start within 30 seconds"
    return 1
}

# Check backend connectivity
check_backend() {
    print_info "Checking backend connectivity at $API_URL..."

    # Try health endpoint first
    if curl -s --connect-timeout 5 "$API_URL/health" > /dev/null 2>&1; then
        print_success "Backend is reachable at $API_URL"
        return 0
    fi

    # Try root endpoint
    if curl -s --connect-timeout 5 "$API_URL/" > /dev/null 2>&1; then
        print_success "Backend is reachable at $API_URL"
        return 0
    fi

    print_error "Backend is not reachable at $API_URL"
    echo ""
    echo "Start the backend from the services project:"
    echo "  cd $BACKEND_DIR"
    echo "  source .venv/bin/activate"
    echo "  uvicorn main:app --reload --port 8000"
    echo ""
    echo "Or use: $0 -s  (to auto-start backend)"
    return 1
}

# Authenticate user
authenticate() {
    if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
        return 0
    fi

    print_info "Authenticating user: $EMAIL"

    local endpoint="$API_URL/auth/login"
    if [[ "$REGISTER_MODE" == true ]]; then
        endpoint="$API_URL/auth/register"
        print_info "Registering new account..."
    fi

    local response
    response=$(curl -s -X POST "$endpoint" \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}" \
        2>&1)

    if echo "$response" | grep -q "access_token"; then
        local token
        token=$(echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        print_success "Authentication successful"

        # Save token for the app to use
        echo "$token" > "$PROJECT_DIR/.auth_token"
        chmod 600 "$PROJECT_DIR/.auth_token"
        print_info "Token saved to .auth_token"

        export AUTH_TOKEN="$token"
        return 0
    else
        local error
        error=$(echo "$response" | grep -o '"detail":"[^"]*"' | cut -d'"' -f4)
        print_error "Authentication failed: ${error:-Unknown error}"

        if [[ "$REGISTER_MODE" != true ]]; then
            echo ""
            print_info "Try registering with: $0 -r -e $EMAIL -P <password>"
        fi
        return 1
    fi
}

# Start Flutter app
start_app() {
    cd "$PROJECT_DIR"

    print_info "Starting Workout Planner..."
    print_info "Platform: $PLATFORM"
    print_info "API URL: $API_URL"

    # Build dart-define arguments
    local dart_defines=(
        "--dart-define=API_BASE_URL=$API_URL"
        "--dart-define=ENABLE_DEBUG_LOGS=true"
    )

    # Pass credentials for auto-login if provided
    if [[ -n "$EMAIL" && -n "$PASSWORD" ]]; then
        dart_defines+=("--dart-define=AUTO_LOGIN_EMAIL=$EMAIL")
        dart_defines+=("--dart-define=AUTO_LOGIN_PASSWORD=$PASSWORD")
        print_info "Auto-login enabled for: $EMAIL"
    fi

    if [[ -n "$AUTH_TOKEN" ]]; then
        dart_defines+=("--dart-define=AUTH_TOKEN=$AUTH_TOKEN")
    fi

    case "$PLATFORM" in
        web)
            print_info "Web server port: $WEB_PORT"
            flutter run -d web-server \
                --web-port "$WEB_PORT" \
                "${dart_defines[@]}"
            ;;
        chrome)
            flutter run -d chrome \
                "${dart_defines[@]}"
            ;;
        android)
            flutter run -d android \
                "${dart_defines[@]}"
            ;;
        ios)
            flutter run -d ios \
                "${dart_defines[@]}"
            ;;
        linux)
            flutter run -d linux \
                "${dart_defines[@]}"
            ;;
        *)
            print_error "Unknown platform: $PLATFORM"
            echo "Supported platforms: web, chrome, android, ios, linux"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    print_header
    echo ""

    # Show .env status
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        print_success "Loaded configuration from .env"
    else
        print_info "No .env file found (using defaults)"
        print_info "Copy .env.example to .env to customize settings"
    fi
    echo ""

    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    print_success "Flutter found: $(flutter --version | head -1)"

    # Start backend if requested
    if [[ "$START_BACKEND" == true ]]; then
        if ! start_backend; then
            print_error "Failed to start backend"
            exit 1
        fi
        echo ""
    fi

    # Check backend
    if ! check_backend; then
        if [[ "$CHECK_ONLY" == true ]]; then
            exit 1
        fi
        print_warning "Continuing without backend (app may have limited functionality)"
        echo ""
    fi

    if [[ "$CHECK_ONLY" == true ]]; then
        exit 0
    fi

    # Note: Authentication is now handled by the app itself
    # when AUTO_LOGIN_EMAIL and AUTO_LOGIN_PASSWORD are passed via dart-define
    if [[ -n "$EMAIL" && -n "$PASSWORD" ]]; then
        print_info "Credentials configured - app will auto-login"
        echo ""
    fi

    # Get dependencies
    print_info "Getting dependencies..."
    cd "$PROJECT_DIR"
    flutter pub get > /dev/null 2>&1
    print_success "Dependencies ready"
    echo ""

    # Start the app
    start_app
}

main
