#!/usr/bin/env sh
# Helper to bring up local dev stack: DB, run migrations, start backend and optionally build+serve frontend
# Usage: ./scripts/run_local.sh

set -eu

# Optional first argument to force runtime: "docker" or "podman"
FORCE_RUNTIME="${1:-}"

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
COMPOSE_FILE="$ROOT_DIR/docker-compose.local.yml"

echo "Starting local dev environment..."

# Stop old local servers to ensure a clean restart
echo "Stopping any existing local servers (backend/web)..."
pkill -f "uvicorn .*python_fastapi_server\.main:app" >/dev/null 2>&1 || true
pkill -f "python3 -m http\.server 38541" >/dev/null 2>&1 || true

# Set DATABASE_URL for migrations and backend
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/fitness_dev"

# 1) Start docker compose
RUNTIME_CMD=""
COMPOSE_CMD=""

# Simple help
if [ "$FORCE_RUNTIME" = "-h" ] || [ "$FORCE_RUNTIME" = "--help" ]; then
  echo "Usage: $0 [docker|podman]"
  echo "  With an argument, force the container runtime used for compose."
  echo "  Without an argument, runtime is auto-detected."
  exit 0
fi

# If user forces runtime, honor it
if [ -n "$FORCE_RUNTIME" ]; then
  if [ "$FORCE_RUNTIME" = "docker" ]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      RUNTIME_CMD=docker
      if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
      else
        COMPOSE_CMD="docker compose"
      fi
    else
      echo "ERROR: Docker requested but not available or daemon not running."
      exit 2
    fi
  elif [ "$FORCE_RUNTIME" = "podman" ]; then
    if command -v podman >/dev/null 2>&1; then
      RUNTIME_CMD=podman
      if podman compose version >/dev/null 2>&1 2>/dev/null; then
        COMPOSE_CMD="podman compose"
      elif command -v podman-compose >/dev/null 2>&1; then
        COMPOSE_CMD="podman-compose"
      else
        COMPOSE_CMD="podman compose"
      fi
    else
      echo "ERROR: Podman requested but not available."
      exit 2
    fi
  else
    echo "Unknown runtime: $FORCE_RUNTIME"
    echo "Usage: $0 [docker|podman]"
    exit 2
  fi
fi

# If not forced, auto-detect
if [ -z "$RUNTIME_CMD" ]; then
  # Prefer Docker if available and daemon running
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    RUNTIME_CMD=docker
    if command -v docker-compose >/dev/null 2>&1; then
      COMPOSE_CMD="docker-compose"
    else
      COMPOSE_CMD="docker compose"
    fi
  fi
  # If Docker not usable, try Podman
  if [ -z "$RUNTIME_CMD" ] && command -v podman >/dev/null 2>&1; then
    RUNTIME_CMD=podman
    if podman compose version >/dev/null 2>&1 2>/dev/null; then
      COMPOSE_CMD="podman compose"
    elif command -v podman-compose >/dev/null 2>&1; then
      COMPOSE_CMD="podman-compose"
    else
      COMPOSE_CMD="podman compose"
    fi
  fi
fi

if [ -z "$RUNTIME_CMD" ]; then
  echo "ERROR: neither Docker nor Podman found or usable. Please install one of them."
  exit 2
fi

PROJECT_NAME="fitnessagent_local"
echo "Using container runtime: ${RUNTIME_CMD:-none}, compose command: ${COMPOSE_CMD:-none}"
echo "Bringing up Postgres & Adminer via: COMPOSE_PROJECT_NAME=$PROJECT_NAME $COMPOSE_CMD -f $COMPOSE_FILE up -d"
if ! COMPOSE_PROJECT_NAME="$PROJECT_NAME" $COMPOSE_CMD -f "$COMPOSE_FILE" up -d 2> /tmp/compose_err.log; then
  cat /tmp/compose_err.log || true
  echo "$COMPOSE_CMD command failed."
  # If the error looks like a Docker/Podman network label mismatch, try to remove conflicting network
  if grep -q "incorrect label com.docker.compose.network" /tmp/compose_err.log 2>/dev/null; then
    CONFLICT_NET="$(echo "$PROJECT_NAME" | tr -c '[:alnum:]' '_' )_default"
    echo "Detected network label mismatch for network: $CONFLICT_NET"
    if command -v docker >/dev/null 2>&1; then
      echo "Attempting to remove Docker network $CONFLICT_NET"
      if docker network rm "$CONFLICT_NET" >/dev/null 2>&1; then
        echo "Removed Docker network $CONFLICT_NET. Retrying compose..."
        if COMPOSE_PROJECT_NAME="$PROJECT_NAME" $COMPOSE_CMD -f "$COMPOSE_FILE" up -d; then
          echo "Compose succeeded after removing conflicting network."
        else
          echo "Compose still failed after removing network. Inspect /tmp/compose_err.log" 
          exit 1
        fi
      else
        echo "Could not remove Docker network $CONFLICT_NET. You may need to remove it manually or choose a different project name."
        echo "Manual command: docker network rm $CONFLICT_NET"
        exit 1
      fi
    elif command -v podman >/dev/null 2>&1; then
      echo "Attempting to remove Podman network $CONFLICT_NET"
      if podman network rm "$CONFLICT_NET" >/dev/null 2>&1; then
        echo "Removed Podman network $CONFLICT_NET. Retrying compose..."
        if COMPOSE_PROJECT_NAME="$PROJECT_NAME" $COMPOSE_CMD -f "$COMPOSE_FILE" up -d; then
          echo "Compose succeeded after removing conflicting network."
        else
          echo "Compose still failed after removing network. Inspect /tmp/compose_err.log" 
          exit 1
        fi
      else
        echo "Could not remove Podman network $CONFLICT_NET. You may need to remove it manually or choose a different project name."
        echo "Manual command: podman network rm $CONFLICT_NET"
        exit 1
      fi
    else
      echo "Network conflict detected but neither docker nor podman CLI available to remove it."
      echo "Please remove the conflicting network named like '<project>_default' (e.g. fitnessagent_default) and re-run."
      exit 1
    fi
  fi

  # If using Podman, try to start the user socket and retry once
  if [ "$RUNTIME_CMD" = "podman" ]; then
    echo "Detected Podman runtime. Attempting to start Podman user socket (systemctl --user start podman.socket) and retry..."
    if command -v systemctl >/dev/null 2>&1; then
      if systemctl --user start podman.socket >/dev/null 2>&1; then
        echo "Started podman.socket; waiting briefly for socket to be ready..."
        sleep 2
        if $COMPOSE_CMD -f "$COMPOSE_FILE" up -d; then
          echo "podman compose succeeded after starting podman.socket."
        else
          echo "podman compose still failed after starting podman.socket."
          echo "You can try: podman system service -t 0 & then re-run the script, or install podman-compose." 
          exit 1
        fi
      else
        echo "Failed to start podman.socket via systemctl --user. You can try: systemctl --user start podman.socket" 
        echo "Or start a background service: podman system service -t 0 &" 
        exit 1
      fi
    else
      echo "systemctl not available to start podman.socket. Try: podman system service -t 0 & then re-run this script."
      exit 1
    fi
  else
    echo "If using Podman on Fedora, ensure 'podman-compose' or 'podman compose' is installed and functional."
    exit 1
  fi
fi

POSTGRES_DB=fitness_dev
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

echo "Waiting for Postgres to accept connections..."
TRIES=0
MAX_TRIES=12
SLEEP=2
while :; do
  # Prefer pg_isready if available
  if command -v pg_isready >/dev/null 2>&1; then
    if pg_isready -h localhost -p 5432 -U "$POSTGRES_USER" >/dev/null 2>&1; then
      break
    fi
  else
    # Try runtime exec into postgres container
    DB_CONTAINER=$($RUNTIME_CMD ps --filter "ancestor=postgres:15" --format '{{.Names}}' | head -n1 || true)
    if [ -n "$DB_CONTAINER" ]; then
      if $RUNTIME_CMD exec "$DB_CONTAINER" pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1; then
        break
      fi
    fi
  fi
  TRIES=$((TRIES+1))
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo "Postgres did not become ready after $MAX_TRIES attempts"
    exit 1
  fi
  echo "Postgres not ready yet, sleeping $SLEEP seconds... ($TRIES/$MAX_TRIES)"
  sleep $SLEEP
done

# Export variables expected by scripts/run_migrations.sh
echo "Postgres ready. Running migrations..."
# Export variables expected by scripts/run_migrations.sh
export DATABASE_URL="postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5432/$POSTGRES_DB"
export POSTGRES_DB="$POSTGRES_DB"
chmod +x "$ROOT_DIR/scripts/run_migrations.sh"
"$ROOT_DIR/scripts/run_migrations.sh"

echo "Starting backend (FastAPI) in background"
cd "$ROOT_DIR" || exit 1
mkdir -p "$ROOT_DIR/logs"
echo "Logs directory: $ROOT_DIR/logs"
if [ ! -d ".venv_local" ]; then
  python3 -m venv .venv_local
fi
. .venv_local/bin/activate
pip install -r applications/backend/python_fastapi_server/requirements.txt >/dev/null 2>&1 || true
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/fitness_dev"
nohup uvicorn applications.backend.python_fastapi_server.main:app --host 0.0.0.0 --port 8000 --reload > "$ROOT_DIR/logs/backend.log" 2>&1 &
echo "Backend started ($ROOT_DIR/logs/backend.log)"

echo "Frontend: attempting to build Flutter web (optional)."
cd "$ROOT_DIR/applications/frontend/apps/mobile_app" || exit 1
if command -v flutter >/dev/null 2>&1; then
  echo "Running 'flutter pub get' and 'flutter build web'"
  flutter pub get
  flutter build web
  echo "Serving built web app on port 38541"
  # Serve build/web using a simple Python HTTP server
  cd build/web || exit 1
  # Ensure no stale web server is running
  pkill -f "python3 -m http\.server 38541" >/dev/null 2>&1 || true
  nohup python3 -m http.server 38541 > "$ROOT_DIR/logs/frontend.log" 2>&1 &
  echo "Frontend served at http://localhost:38541 (logs at $ROOT_DIR/logs/frontend.log)"
else
  echo "Flutter not found. To run frontend you can install Flutter and run:" 
  echo "  cd applications/frontend/apps/mobile_app && flutter run -d web-server --web-hostname=0.0.0.0 --web-port=38541"
fi

echo "All done. Backend: http://localhost:8000 , Frontend: http://localhost:38541"
echo "To stop services: docker compose -f $COMPOSE_FILE down"

exit 0
