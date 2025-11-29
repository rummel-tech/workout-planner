# iOS Build and Deployment Guide for Workout Planner

This guide covers building, testing, and deploying the Workout Planner iOS app.

## Prerequisites

### Required Software (macOS only)
- **macOS** 12.0 or later
- **Xcode** 15.0 or later
- **Flutter SDK** 3.38.1 or later
- **CocoaPods** (installed automatically by Flutter)

### Apple Developer Account Requirements
- Apple Developer Program membership ($99/year)
- iOS App Store Connect access
- Signing certificates and provisioning profiles

## Local Development (macOS)

### 1. Setup Flutter for iOS

```bash
# Install Flutter (if not already installed)
# Download from https://flutter.dev/docs/get-started/install/macos

# Verify Flutter installation
flutter doctor

# Expected output should show:
# [✓] Flutter
# [✓] Xcode - develop for iOS and macOS
# [✓] Chrome - develop for the web
# [✓] Connected device

# Configure iOS tooling
flutter config --enable-ios
```

### 2. Install Dependencies

```bash
cd /path/to/workout-planner/applications/frontend/apps/mobile_app

# Install Flutter packages
flutter pub get

# Install iOS CocoaPods dependencies
cd ios && pod install && cd ..
```

### 3. Open in Xcode (Optional)

```bash
# Open the iOS project in Xcode
open ios/Runner.xcworkspace
```

In Xcode:
1. Select your development team in Signing & Capabilities
2. Update Bundle Identifier if needed: `com.rummel.workoutplanner`
3. Verify HealthKit capability is enabled

### 4. Run on iOS Simulator

```bash
# List available simulators
flutter devices

# Run on iPhone simulator (default)
flutter run

# Run on specific simulator
flutter run -d "iPhone 15 Pro"

# Run in release mode
flutter run --release
```

### 5. Run on Physical iOS Device

```bash
# Connect your iPhone via USB
# Unlock the device and trust the computer

# List connected devices
flutter devices

# Run on connected device
flutter run -d <device-id>

# First time: Trust developer certificate on device
# Settings > General > VPN & Device Management > Trust "Apple Development: ..."
```

### 6. Build iOS Archive (Local)

```bash
# Build iOS app without code signing (for testing)
flutter build ios --release --no-codesign

# Build with code signing (for distribution)
flutter build ios --release

# Build IPA for distribution
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ~/workout-planner.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath ~/workout-planner.xcarchive \
  -exportPath ~/workout-planner-ipa \
  -exportOptionsPlist exportOptions.plist
```

## CI/CD Deployment (GitHub Actions)

The iOS app can be built and deployed automatically via GitHub Actions.

### Setup GitHub Secrets

Required secrets for TestFlight deployment (in `infrastructure` repository):

1. **IOS_CERTIFICATE_BASE64** - Base64 encoded .p12 certificate
2. **IOS_CERTIFICATE_PASSWORD** - Password for .p12 certificate
3. **IOS_PROVISIONING_PROFILE_BASE64** - Base64 encoded .mobileprovision
4. **APP_STORE_CONNECT_API_KEY_ID** - App Store Connect API Key ID
5. **APP_STORE_CONNECT_API_ISSUER_ID** - App Store Connect Issuer ID
6. **APP_STORE_CONNECT_API_KEY** - App Store Connect API Key (base64)

### Generate Required Credentials

#### 1. Export Certificate (.p12)

```bash
# In Keychain Access (macOS):
# 1. Find "Apple Distribution" or "Apple Development" certificate
# 2. Right-click > Export
# 3. Save as .p12 file with password
# 4. Convert to base64:

base64 -i YourCertificate.p12 | pbcopy
# Paste into GitHub secret: IOS_CERTIFICATE_BASE64
```

#### 2. Export Provisioning Profile

```bash
# Download from Apple Developer Portal:
# https://developer.apple.com/account/resources/profiles

# Convert to base64:
base64 -i YourProfile.mobileprovision | pbcopy
# Paste into GitHub secret: IOS_PROVISIONING_PROFILE_BASE64
```

#### 3. Create App Store Connect API Key

1. Go to https://appstoreconnect.apple.com/access/api
2. Click "+" to generate a new key
3. Select "App Manager" role
4. Download the .p8 key file
5. Note the Key ID and Issuer ID

```bash
# Convert API key to base64:
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
# Paste into GitHub secret: APP_STORE_CONNECT_API_KEY
```

### Trigger Deployment

#### Option 1: Manual Workflow Dispatch

```bash
# Using GitHub CLI
gh workflow run deploy-workout-planner-ios.yml \
  --repo srummel/infrastructure \
  -f repo_ref=main \
  -f deploy_target=artifact

# For TestFlight deployment
gh workflow run deploy-workout-planner-ios.yml \
  --repo srummel/infrastructure \
  -f repo_ref=main \
  -f deploy_target=testflight
```

#### Option 2: Repository Dispatch (from workout-planner repo)

```bash
# From workout-planner repository
gh api repos/srummel/infrastructure/dispatches \
  -f event_type=deploy-workout-planner-ios \
  -f client_payload[ref]=main
```

### Download Build Artifacts

After a successful build with `deploy_target=artifact`:

1. Go to GitHub Actions in `infrastructure` repository
2. Find the workflow run
3. Download "workout-planner-ios-build" artifact
4. Extract and find `Runner.app`

## App Store Submission

### 1. Update Version and Build Number

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Increment for each release
```

### 2. Prepare App Metadata

Required for App Store Connect:
- App name: Workout Planner
- Bundle ID: com.rummel.workoutplanner
- Primary category: Health & Fitness
- Screenshots (required sizes: 6.7", 6.5", 5.5")
- App description and keywords
- Privacy policy URL

### 3. Build and Upload to TestFlight

```bash
# Option A: Use GitHub Actions (recommended)
gh workflow run deploy-workout-planner-ios.yml \
  --repo srummel/infrastructure \
  -f deploy_target=testflight

# Option B: Manual upload via Xcode
# 1. Build archive in Xcode: Product > Archive
# 2. Window > Organizer > Archives
# 3. Select archive > Distribute App > App Store Connect
# 4. Follow wizard to upload
```

### 4. Submit for Review

1. Go to https://appstoreconnect.apple.com
2. Select Workout Planner app
3. Go to TestFlight > iOS builds
4. Wait for build processing (~10-30 minutes)
5. Add build to TestFlight internal testing
6. Submit for App Store review when ready

## Troubleshooting

### "Unable to boot simulator"

```bash
# Reset simulators
xcrun simctl shutdown all
xcrun simctl erase all
```

### "Code signing failed"

```bash
# Clean build
flutter clean
cd ios && pod install && cd ..
flutter pub get

# Verify signing in Xcode
open ios/Runner.xcworkspace
# Check Signing & Capabilities tab
```

### "HealthKit not available"

- HealthKit only works on physical devices, not simulators
- Ensure `Runner.entitlements` includes HealthKit capability
- Verify Info.plist has HealthKit usage descriptions

### "Flutter build ios failed"

```bash
# Clean and rebuild
flutter clean
flutter pub get
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..
flutter build ios --release
```

### "App Store Connect API authentication failed"

- Verify API key has "App Manager" role
- Ensure API key is not expired
- Check Key ID and Issuer ID match

## Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
# Run on simulator
flutter test integration_test/app_e2e_test.dart

# Run on device
flutter test integration_test/app_e2e_test.dart -d <device-id>
```

### TestFlight Beta Testing

1. Upload build via GitHub Actions or Xcode
2. Go to App Store Connect > TestFlight
3. Add internal testers (Apple ID required)
4. Testers receive invite via email
5. Install TestFlight app on iOS device
6. Accept invite and download beta app

## Additional Resources

- [Flutter iOS Deployment](https://flutter.dev/docs/deployment/ios)
- [Apple Developer Documentation](https://developer.apple.com/ios/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

## Current Status

- ✅ iOS project structure initialized
- ✅ HealthKit permissions configured
- ✅ App branding updated to "Workout Planner"
- ✅ GitHub Actions workflow created
- ⏳ App Store submission pending
- ⏳ TestFlight beta testing pending

## Next Steps

1. Configure Apple Developer Account
2. Generate signing certificates and provisioning profiles
3. Add GitHub secrets to infrastructure repository
4. Test GitHub Actions deployment workflow
5. Submit app to TestFlight for internal testing
6. Gather beta tester feedback
7. Submit to App Store for review
