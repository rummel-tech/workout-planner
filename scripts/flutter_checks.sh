#!/bin/sh
# Helper script to run Flutter package gets, codegen, analysis and tests locally.
# Run from repository root: sh scripts/flutter_checks.sh

set -e

APP_DIR="frontend/apps/mobile_app"
PACKAGES_DIR="frontend/packages"

echo "==> Running flutter checks (requires Flutter installed locally)"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter not found in PATH. Install Flutter and retry." >&2
  exit 2
fi

# Get packages for app
echo "-> pub get for app"
cd "$APP_DIR"
flutter pub get

# Get packages for each local package
cd "../../"
for pkg in "$PACKAGES_DIR"/*; do
  if [ -d "$pkg" ]; then
    echo "-> pub get for package: $(basename "$pkg")"
    cd "$pkg"
    flutter pub get || true
    cd - >/dev/null
  fi
done

# Run code generation for packages that use freezed/json_serializable
# This will run where `build_runner` is configured (e.g. goals_ui)
if [ -d "$PACKAGES_DIR/goals_ui" ]; then
  echo "-> Running build_runner in goals_ui"
  cd "$PACKAGES_DIR/goals_ui"
  flutter pub run build_runner build --delete-conflicting-outputs || true
  cd - >/dev/null
fi

# Run flutter analyze and tests for the app
echo "-> Analyzing app"
cd "$APP_DIR"
flutter analyze || true

# Optional: run tests if present
if [ -d "test" ]; then
  echo "-> Running flutter tests"
  flutter test || true
fi

echo "Flutter checks complete. Review output for issues."
