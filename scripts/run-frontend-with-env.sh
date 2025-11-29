#!/bin/bash
# Run Flutter frontend with custom environment configuration

set -e

# Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
APP_NAME="${APP_NAME:-Workout Planner}"
PLATFORM="${1:-chrome}"  # chrome, macos, ios, android

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Starting Flutter Frontend ===${NC}"
echo "API Base URL: $API_BASE_URL"
echo "App Name: $APP_NAME"
echo "Platform: $PLATFORM"
echo ""

# Navigate to frontend directory
cd "$(dirname "$0")/../applications/frontend/apps/mobile_app"

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get

# Build with dart-define for environment variables
echo -e "${GREEN}Starting on $PLATFORM...${NC}"
flutter run -d "$PLATFORM" \
    --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=APP_NAME="$APP_NAME" \
    --dart-define=ENABLE_DEBUG_LOGS=true
