#!/usr/bin/env bash
# Simple smoke test for POC: checks frontend and API health endpoints
# Usage: API_URL and/or FRONTEND_URL must be set in environment

set -euo pipefail

API_URL=${API_URL:-}
FRONTEND_URL=${FRONTEND_URL:-}
RETRIES=${RETRIES:-5}
SLEEP=${SLEEP:-5}

echo "Starting smoke tests..."

fail() {
  echo "SMOKE TEST FAILED: $1"
  exit 1
}

check_url() {
  local url=$1
  local name=$2

  if [ -z "$url" ]; then
    echo "No URL provided for $name; skipping."
    return 0
  fi

  echo "Checking $name at $url"

  local i=0
  while [ $i -lt $RETRIES ]; do
    if curl -sSf --max-time 5 "$url" >/dev/null; then
      echo "$name is healthy"
      return 0
    fi
    i=$((i+1))
    echo "Attempt $i/$RETRIES failed for $name; retrying in $SLEEP seconds..."
    sleep $SLEEP
  done

  fail "$name did not respond successfully at $url"
}

# Check API health (prefer /health endpoint)
if [ -n "$API_URL" ]; then
  if curl -sSf --max-time 5 "$API_URL/health" >/dev/null 2>&1; then
    echo "API /health responded OK"
  else
    # fallback to root
    check_url "$API_URL" "API"
  fi
else
  echo "API_URL not set; skipping API checks"
fi

# Check frontend
if [ -n "$FRONTEND_URL" ]; then
  check_url "$FRONTEND_URL" "Frontend"
else
  echo "FRONTEND_URL not set; skipping Frontend checks"
fi

echo "All smoke tests passed"
exit 0
