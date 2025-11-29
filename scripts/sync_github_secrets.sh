#!/usr/bin/env sh
# Sync secrets from config/secrets/ci.secrets.env to GitHub Actions repository secrets using gh CLI.
# Usage: ./scripts/sync_github_secrets.sh [owner/repo]
# Requires: gh CLI authenticated (gh auth login)

set -eu

REPO=${1:-}
FILE="config/secrets/ci.secrets.env"

if [ ! -f "$FILE" ]; then
  echo "Missing $FILE. Copy ci.secrets.example.env to ci.secrets.env and fill values." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install from https://cli.github.com/" >&2
  exit 1
fi

if [ -z "$REPO" ]; then
  # Try to detect repo from git
  if git remote -v | grep -q origin; then
    REPO=$(git remote get-url origin | sed -E 's#(git@|https://)([^/:]+)[:/](.+)\.git#\3#')
  fi
fi

if [ -z "$REPO" ]; then
  echo "Provide repo as owner/repo, e.g. ./scripts/sync_github_secrets.sh yourname/fitness-agent" >&2
  exit 1
fi

# Read key=value pairs, ignore comments and empty lines
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ''|'#'*) continue ;;
  esac
  KEY=$(printf "%s" "$line" | cut -d '=' -f1)
  VAL=$(printf "%s" "$line" | cut -d '=' -f2-)
  if [ -z "$KEY" ]; then continue; fi
  echo "Setting secret $KEY in $REPO"
  printf "%s" "$VAL" | gh secret set "$KEY" --repo "$REPO" -b- >/dev/null
done < "$FILE"

echo "All secrets processed. Verify in GitHub → Settings → Secrets and variables → Actions."
