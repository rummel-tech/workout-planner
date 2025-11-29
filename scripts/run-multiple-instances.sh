#!/bin/bash
# Example: Running multiple instances of the application
# This demonstrates running workout-planner on different ports

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Multi-Instance Workout Planner Demo ===${NC}"
echo ""
echo "This script demonstrates running multiple instances:"
echo "  - Instance 1: Port 8000 (development)"
echo "  - Instance 2: Port 8001 (staging)"
echo "  - Instance 3: Port 8002 (testing)"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all instances${NC}"
echo ""

# Trap to clean up background processes
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# Instance 1: Development on port 8000
echo -e "${BLUE}Starting Instance 1 (Development) on port 8000...${NC}"
PORT=8000 APP_NAME="workout-planner-dev" APP_CONTEXT="" \
    bash "$(dirname "$0")/run-with-context.sh" &
sleep 2

# Instance 2: Staging on port 8001
echo -e "${BLUE}Starting Instance 2 (Staging) on port 8001...${NC}"
PORT=8001 APP_NAME="workout-planner-staging" APP_CONTEXT="/api/v1" \
    bash "$(dirname "$0")/run-with-context.sh" &
sleep 2

# Instance 3: Testing on port 8002
echo -e "${BLUE}Starting Instance 3 (Testing) on port 8002...${NC}"
PORT=8002 APP_NAME="workout-planner-test" APP_CONTEXT="" \
    bash "$(dirname "$0")/run-with-context.sh" &

# Wait for all background processes
wait
