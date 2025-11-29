#!/bin/sh
# Quick setup and run script for Flutter frontend locally

set -e

cd "$(dirname "$0")"

APP_DIR="applications/frontend/apps/mobile_app"

echo "==> Flutter Frontend Local Setup"
echo ""
echo "Prerequisites:"
echo "  - Flutter SDK (flutter.dev/docs/get-started/install)"
echo "  - Android SDK or Xcode (iOS) or Chrome (web)"
echo ""

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: Flutter SDK not found. Please install Flutter first:"
  echo "  https://flutter.dev/docs/get-started/install"
  exit 1
fi

flutter --version

echo ""
echo "==> Updating packages in app and local packages"
cd "$APP_DIR"
flutter pub get

echo ""
echo "==> Running Flutter app"
echo "Available devices/emulators:"
flutter devices

echo ""
echo "To run on a device, use:"
echo "  flutter run -d <device-id>"
echo ""
echo "To run on Android emulator:"
echo "  flutter emulators --launch <emulator-id>  # if not already running"
echo "  flutter run"
echo ""
echo "To run on iOS:"
echo "  flutter run -d macos      # macOS"
echo "  open ios/Runner.xcworkspace  # then build in Xcode"
echo ""
echo "To run as web (requires Chrome):"
echo "  flutter run -d chrome"
echo ""
echo "Starting interactive session. Type 'r' to hot-reload, 'q' to quit."
flutter run
