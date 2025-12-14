# Fitness Agent Mobile App

AI-powered fitness training platform with Apple Health integration, dynamic readiness monitoring, and intelligent goal tracking.

## 🎯 Features

### Core Functionality
- **Apple Health Sync**: Automatic ingestion of workouts, heart rate, HRV, sleep, and physiological metrics
- **Dynamic Metrics Dashboard**: Real-time display of workouts, distance, calories from actual health data
- **Readiness Monitoring**: Computed from recent HRV, resting HR, and sleep compared to baseline
- **Goal Management**: Full CRUD with flexible units (5k, 26.2mi, 45min, etc.)
- **Auto-Sync**: Background sync every 15 minutes + manual sync button with loading states
- **Deduplication**: Prevents duplicate health data via unique source identifiers

### Home Screen Components
- User profile card with quick settings access
- Goals preview (first 3 active goals)
- Health metrics section:
  - Workouts count (last 30 days)
  - Total distance (km)
  - Total calories (kcal)
- Readiness card with HRV, sleep, resting HR breakdown
- Sync button (manual trigger with loading indicator)
- Quick action buttons (Today's Workout, Goals, Weekly Plan, Profile)
- Quick log shortcuts (Health, Strength, Swim)

## 🏗️ Architecture

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Local packages
  home_dashboard_ui:
    path: ../../../packages/home_dashboard_ui
  goals_ui:
    path: ../../../packages/goals_ui
  todays_workout_ui:
    path: ../../../packages/todays_workout_ui
  weekly_plan_ui:
    path: ../../../packages/weekly_plan_ui
  settings_profile_ui:
    path: ../../../packages/settings_profile_ui
  readiness_ui:
    path: ../../../packages/readiness_ui
```

### Key Services
- `HealthSyncManager` (home_dashboard_ui): Batch health data sync with native HealthKit bridge
- `GoalsApiService`: Backend CRUD for goals and plans
- `HealthService`: Health samples list/summary endpoints
- `ReadinessService`: Readiness calculation endpoint

### Native Bridge (iOS)
- **Channel**: `healthkit_bridge`
- **Methods**:
  - `requestPermissions` → Bool
  - `fetchWorkouts` → List<Map>
  - `fetchHeartRate` → List<Map>
  - `fetchHRV` → List<Map>
  - `fetchRestingHeartRate` → List<Map>
  - `fetchSleep` → List<Map>

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.16.0+
- Xcode 15+ (for iOS)
- iOS 16+ device or simulator
- Backend API running at `http://localhost:8000`

### Installation

1. **Install dependencies**:
   ```sh
   flutter pub get
   ```

2. **Configure backend URL** (if different from localhost):
   Edit `lib/main.dart` or use environment variables:
   ```dart
   const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
   ```

3. **iOS Setup**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Ensure HealthKit capability is enabled
   - Add required privacy usage descriptions in `Info.plist`:
     ```xml
     <key>NSHealthShareUsageDescription</key>
     <string>We need access to your health data to provide personalized workout recommendations.</string>
     <key>NSHealthUpdateUsageDescription</key>
     <string>We need to update your health data to track workout progress.</string>
     ```

4. **Run the app**:
   ```sh
   flutter run
   ```

## 🧪 Testing

### Run Tests
```sh
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

### Test Coverage
- **Widget Tests** (10 groups):
  - App initialization
  - Sync button functionality
  - Goals display and navigation
  - Metrics display with loading/error states
  - Readiness card
  - Navigation buttons
  - User profile
  - Auto-sync behavior
  - Error handling

See `../../../../docs/TESTING.md` for complete testing guide.

## 📱 Usage

### First Launch
1. Grant HealthKit permissions when prompted
2. App performs initial sync after 2-second delay
3. Home screen displays metrics and readiness from actual health data

### Manual Sync
- Tap **Sync** button in Metrics section
- Loading indicator shows sync progress
- Snackbar confirms success: "Synced X/Y samples"
- Metrics and readiness refresh automatically

### Auto-Sync Behavior
- Triggers automatically 2 seconds after app launch
- Re-syncs every 15 minutes while app is active
- Prevents concurrent syncs (waits for current sync to complete)

### Creating Goals
1. Navigate to Goals screen (tap "View All" or Goals button)
2. Tap "+" to create new goal
3. Enter goal details:
   - Type: Marathon, 5K, Weight Loss, etc.
   - Target: Use natural input like "5k", "26.2mi", "45min"
   - Date: Target completion date
   - Notes: Additional context
4. Goal appears on Home screen with unit displayed

## 🔧 Development

### Backend API Configuration
Update `home_dashboard_ui/lib/services/health_sync.dart`:
```dart
HealthSync(
  userId: 'user-123',
  baseUrl: 'https://your-api.example.com',  // Change this
  batchSize: 100
)
```

### Adjusting Sync Interval
Edit `home_dashboard_ui/lib/screens/home_screen.dart`:
```dart
_syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _performSync());
// Change Duration to adjust frequency
```

### Adding New Health Sample Types
1. Extend Swift `HealthKitManager.swift` with new fetch method
2. Add case to `FlutterBridge.swift`
3. Add Dart wrapper in `healthkit_bridge.dart`
4. Update `health_sync.dart` transformation logic
5. Backend: ensure `health_samples` table accepts new sample_type

## 🐛 Troubleshooting

**Sync fails with "Permissions denied"**:
- Check HealthKit permissions in Settings → Privacy → Health
- Ensure app has requested permissions on first launch

**Metrics show zeros**:
- Verify backend is running and accessible
- Check health data exists in Apple Health
- Tap Sync button manually to force refresh
- Check for errors in sync snackbar

**Build errors**:
```sh
# Clean and rebuild
flutter clean
flutter pub get
flutter build ios
```

**Native bridge errors**:
- Verify `healthkit_bridge` channel name matches in Swift and Dart
- Check Xcode console for Swift method invocation errors
- Ensure HealthKit framework is linked in Xcode project

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [Project Testing Guide](../../../../docs/TESTING.md)
- [Backend API Documentation](../../../backend/python_fastapi_server/README.md)
- [HealthKit Integration Details](../../../../integrations/swift_healthkit_module/README.md)
