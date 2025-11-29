#!/bin/bash
# Run Workout Planner with custom context/port for multi-app development

set -e

# Configuration
APP_NAME="${APP_NAME:-workout-planner}"
APP_CONTEXT="${APP_CONTEXT:-}"
PORT="${PORT:-8000}"
HOST="${HOST:-0.0.0.0}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starting Workout Planner ===${NC}"
echo "App Name: $APP_NAME"
echo "App Context: ${APP_CONTEXT:-none}"
echo "Host: $HOST"
echo "Port: $PORT"
echo ""

# Navigate to backend directory
cd "$(dirname "$0")/../applications/backend/python_fastapi_server"

# Check if .env exists, if not copy from example
if [ ! -f .env ]; then
    echo -e "${YELLOW}No .env file found, creating from .env.example${NC}"
    cp .env.example .env
fi

# Export environment variables
export APP_NAME="$APP_NAME"
export APP_CONTEXT="$APP_CONTEXT"
export HOST="$HOST"
export PORT="$PORT"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install/update dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install -r requirements.txt -q

# Start the server
echo -e "${GREEN}Starting server on http://${HOST}:${PORT}${APP_CONTEXT}${NC}"
echo ""

uvicorn main:app --host "$HOST" --port "$PORT" --reload
