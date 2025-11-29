#!/usr/bin/env bash
# Run database migrations for the project.
# Supports:
# - SQL files in database/sql/ (applied in alphabetical order)
# - Alembic migrations if `alembic.ini` is present under applications/backend/fastapi_server
#
# Usage: set DATABASE_URL in env (Postgres URL)
# Example: DATABASE_URL=postgres://user:pass@host:5432/db ./scripts/run_migrations.sh

set -euo pipefail

DATABASE_URL=${DATABASE_URL:-}
SLEEP=${SLEEP:-2}
RETRIES=${RETRIES:-3}

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL must be set (e.g. postgres://user:pass@host:5432/db)"
  exit 2
fi

# Helper to run psql with retries
psql_exec() {
  local sqlfile=$1
  local attempt=0
  if command -v psql >/dev/null 2>&1; then
    until psql "$DATABASE_URL" -f "$sqlfile" >/dev/null 2>&1; do
      attempt=$((attempt+1))
      if [ $attempt -ge $RETRIES ]; then
        echo "Failed to apply $sqlfile after $RETRIES attempts"
        return 1
      fi
      echo "psql failed for $sqlfile, retrying in $SLEEP seconds... (attempt $attempt)"
      sleep $SLEEP
    done
    echo "Applied $sqlfile"
    return 0
  else
    # Fallback: try to run psql inside a running Postgres container
    echo "psql not found locally; attempting to use container runtime fallback..."
    # Prefer Podman if available and responsive, otherwise fall back to Docker.
    DB_CONTAINER=""
    RUNTIME_CMD=""
    if command -v podman >/dev/null 2>&1; then
      # Test podman responsiveness
      if podman ps >/dev/null 2>&1; then
        DB_CONTAINER=$(podman ps --filter "ancestor=postgres:15" --format '{{.Names}}' | head -n1 || true)
        RUNTIME_CMD=podman
      fi
    fi
    if [ -z "$RUNTIME_CMD" ] && command -v docker >/dev/null 2>&1; then
      # Test docker responsiveness (may fail if socket permission denied)
      if docker ps >/dev/null 2>&1; then
        DB_CONTAINER=$(docker ps --filter "ancestor=postgres:15" --format '{{.Names}}' | head -n1 || true)
        RUNTIME_CMD=docker
      else
        # docker present but not usable (socket permission or daemon not running)
        echo "Docker CLI present but not usable (socket or daemon issue)."
      fi
    fi
    if [ -z "$RUNTIME_CMD" ]; then
      echo "Neither Podman nor Docker is available/usable to run container psql fallback."
      echo "If you have Docker but see 'permission denied', run with sudo or add your user to the 'docker' group:" 
      echo "  sudo usermod -aG docker \$(whoami) && newgrp docker"
      return 1
    fi

    if [ -z "$DB_CONTAINER" ]; then
      echo "No running Postgres container found (ancestor=postgres:15). Will try a temporary client container connecting to host:5432"
      # Try temporary podman container using host network (works on Linux)
      if command -v podman >/dev/null 2>&1; then
        echo "Attempting: podman run --rm -i --network host -e PGPASSWORD=$POSTGRES_PASSWORD postgres:15 psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB -f - < $sqlfile"
        attempt=0
        until podman run --rm -i --network host -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:15 psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f - < "$sqlfile" >/dev/null 2>&1; do
          attempt=$((attempt+1))
          if [ $attempt -ge $RETRIES ]; then
            echo "Failed to apply $sqlfile via temporary podman client after $RETRIES attempts"
            return 1
          fi
          echo "Temporary podman psql failed for $sqlfile, retrying in $SLEEP seconds... (attempt $attempt)"
          sleep $SLEEP
        done
        echo "Applied $sqlfile via temporary podman container"
        continue
      fi
      # Try temporary docker container as fallback (may require docker socket access)
      if command -v docker >/dev/null 2>&1; then
        echo "Attempting: docker run --rm -i --network host -e PGPASSWORD=$POSTGRES_PASSWORD postgres:15 psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB -f - < $sqlfile"
        attempt=0
        until docker run --rm -i --network host -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:15 psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f - < "$sqlfile" >/dev/null 2>&1; do
          attempt=$((attempt+1))
          if [ $attempt -ge $RETRIES ]; then
            echo "Failed to apply $sqlfile via temporary docker client after $RETRIES attempts"
            return 1
          fi
          echo "Temporary docker psql failed for $sqlfile, retrying in $SLEEP seconds... (attempt $attempt)"
          sleep $SLEEP
        done
        echo "Applied $sqlfile via temporary docker container"
        continue
      fi
      echo "No container runtime available to run a temporary psql client. Cannot apply $sqlfile"
      return 1
    fi
    attempt=0
    until $RUNTIME_CMD exec -i "$DB_CONTAINER" psql -U postgres -d "$POSTGRES_DB" -f - < "$sqlfile" >/dev/null 2>&1; do
      attempt=$((attempt+1))
      if [ $attempt -ge $RETRIES ]; then
        echo "Failed to apply $sqlfile inside container $DB_CONTAINER after $RETRIES attempts"
        return 1
      fi
      echo "Container psql failed for $sqlfile, retrying in $SLEEP seconds... (attempt $attempt)"
      sleep $SLEEP
    done
    echo "Applied $sqlfile via container $DB_CONTAINER"
    return 0
  fi
}

# 1) Apply SQL files if present
SQL_DIR="database/sql"
if [ -d "$SQL_DIR" ]; then
  echo "Looking for SQL migration files in $SQL_DIR"
  sql_files=( $(ls "$SQL_DIR"/*.sql 2>/dev/null || true) )
  if [ ${#sql_files[@]} -gt 0 ]; then
    echo "Found ${#sql_files[@]} SQL files. Applying in order..."
    for f in "${sql_files[@]}"; do
      echo "Applying $f"
      psql_exec "$f" || exit 1
    done
  else
    echo "No .sql files found in $SQL_DIR"
  fi
else
  echo "SQL directory $SQL_DIR not present"
fi

# 2) If Alembic is present, run Alembic upgrade head
ALEMBIC_INI="applications/backend/fastapi_server/alembic.ini"
if [ -f "$ALEMBIC_INI" ]; then
  echo "Detected Alembic configuration at $ALEMBIC_INI. Running Alembic migrations."
  # Ensure alembic is available; try to use pip in venv or globally
  if command -v alembic >/dev/null 2>&1; then
    alembic -c "$ALEMBIC_INI" upgrade head
  else
    echo "Alembic not found in PATH. Attempting to run via python -m alembic"
    if python -m alembic -c "$ALEMBIC_INI" upgrade head >/dev/null 2>&1; then
      echo "Alembic migrations applied"
    else
      echo "Failed to run alembic migrations. Please ensure alembic is installed in CI environment."
      exit 1
    fi
  fi
else
  echo "No Alembic configuration found at $ALEMBIC_INI"
fi

echo "Migrations completed successfully"
exit 0
