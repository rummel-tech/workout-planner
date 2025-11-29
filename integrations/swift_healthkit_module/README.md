# Swift HealthKit Module

Native iOS module providing HealthKit permission handling and comprehensive health data fetching, bridged to Flutter via method channel `healthkit_bridge`.

## 🎯 Current Implementation Status

### ✅ Implemented Methods
- `requestPermissions` - Requests read authorization for all configured workout and quantity types
- `fetchWorkouts` - Returns recent workouts with distance, calories, type since last fetch
- `fetchHeartRate` - Returns heart rate samples (bpm) with timestamps
- `fetchHRV` - Returns HRV/SDNN samples (ms) for recovery monitoring
- `fetchRestingHeartRate` - Returns resting heart rate samples (bpm)
- `fetchSleep` - Returns sleep stage analysis (deep, light, REM, awake)

### 📊 Health Data Types Supported
- **Workouts**: All types (running, cycling, swimming, strength, etc.)
- **Heart Metrics**: Heart rate, HRV (SDNN), Resting heart rate
- **Sleep**: Sleep stages (categoryType sleep analysis)
- **Future**: Step count, VO2 max, body mass, active energy (structure in place)

## 🏗️ Architecture

### Components

**HealthKitManager.swift**
- Manages HealthKit authorization and data queries
- Implements fetch methods for each sample type
- Maintains last fetch timestamps in UserDefaults for incremental syncing
- Provides generic `fetchQuantitySamples` for easy extension

**HealthDataSerializer.swift**
- Converts HKSample objects to Flutter-compatible dictionaries
- Handles workouts, quantity samples, and sleep category samples
- Includes UUID, timestamps, values, units, and source information

**FlutterBridge.swift**
- Bridges Swift methods to Flutter via MethodChannel
- Routes method calls to appropriate HealthKitManager functions
- Returns serialized data as `FlutterResult`

## 📱 Usage from Flutter

### Request Permissions
```dart
import 'package:healthkit_bridge.dart';

final bridge = HealthKitBridge();
final granted = await bridge.requestPermissions();
if (granted) {
  print('HealthKit access granted');
}
```

### Fetch Health Data
```dart
// Fetch workouts
final workouts = await bridge.fetchWorkouts();
for (var workout in workouts) {
  print('${workout['type']}: ${workout['distance']}m, ${workout['calories']} kcal');
}

// Fetch heart rate
final heartRate = await bridge.fetchHeartRate();

// Fetch HRV
final hrv = await bridge.fetchHRV();

// Fetch resting HR
final restingHr = await bridge.fetchRestingHeartRate();

// Fetch sleep
final sleep = await bridge.fetchSleep();
```

### Data Structure
Each method returns `List<Map<String, dynamic>>` with structure:
```dart
{
  'uuid': 'HKSample-UUID',
  'start': 1700000000.0,  // Unix timestamp (seconds)
  'end': 1700003600.0,
  'value': 72.0,          // Sample value
  'unit': 'bpm',          // Unit string
  'source': 'Apple Watch',
  'type': 'workout'       // Sample type
}
```

## 🔧 Adding New Health Metrics

### 1. Update HealthKitManager
Add quantity type to `typesToRead` in `requestPermissions`:
```swift
HKObjectType.quantityType(forIdentifier: .stepCount)!,
HKObjectType.quantityType(forIdentifier: .bodyMass)!,
```

Add fetch method:
```swift
func fetchStepCount(completion: @escaping ([HKQuantitySample]) -> Void) {
    let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let unit = HKUnit.count()
    fetchQuantitySamples(type: type, unit: unit, lastFetchKey: "lastStepFetch", completion: completion)
}
```

### 2. Add Serialization Support
If needed, extend `HealthDataSerializer`:
```swift
static func serializeStepSamples(_ samples: [HKQuantitySample]) -> [[String: Any]] {
    return serializeQuantitySamples(samples, unit: HKUnit.count())
}
```

### 3. Register in FlutterBridge
Add case to `setMethodCallHandler`:
```swift
case "fetchStepCount":
    healthKitManager.fetchStepCount { samples in
        let serialized = HealthDataSerializer.serializeQuantitySamples(samples, unit: .count())
        result(serialized)
    }
```

### 4. Add Flutter Wrapper
Update `healthkit_bridge.dart`:
```dart
Future<List<Map<String, dynamic>>> fetchStepCount() async {
  final result = await _channel.invokeMethod('fetchStepCount');
  return (result as List).cast<Map<String, dynamic>>();
}
```

### 5. Update Backend Schema
Ensure `health_samples` table accepts new `sample_type`:
```python
# No schema change needed - sample_type is TEXT
# Just ingest with sample_type='step_count'
```

## 🔒 Privacy & Permissions

### Info.plist Requirements
```xml
<key>NSHealthShareUsageDescription</key>
<string>We use your health data to provide personalized workout recommendations and track your recovery.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>We update your health metrics to keep your training insights current.</string>
```

### Permission Scope
Request only necessary permissions:
- **Always required**: Workouts
- **For readiness**: Heart rate, HRV, Resting HR, Sleep
- **Optional**: Step count, VO2 max, Body mass

### User Controls
- Allow users to pause/resume sync in app settings
- Provide transparency about what data is collected
- Offer data deletion options

## 🧪 Testing

### Simulator Limitations
- HealthKit data is limited in simulator
- Use Health app to manually add test data
- Best tested on real device with actual health data

### Test Data Generation
```swift
// Add test workout (development builds only)
let workout = HKWorkout(
    activityType: .running,
    start: Date().addingTimeInterval(-3600),
    end: Date(),
    duration: 3600,
    totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 400),
    totalDistance: HKQuantity(unit: .meter(), doubleValue: 5000),
    metadata: nil
)
healthStore.save(workout) { success, error in
    print("Test workout saved: \(success)")
}
```

### Reset Last Fetch
```swift
// Clear all last fetch timestamps
UserDefaults.standard.removeObject(forKey: "lastWorkoutFetch")
UserDefaults.standard.removeObject(forKey: "lastHeartRateFetch")
UserDefaults.standard.removeObject(forKey: "lastHRVFetch")
UserDefaults.standard.removeObject(forKey: "lastRestingHRFetch")
UserDefaults.standard.removeObject(forKey: "lastSleepFetch")
```

## 📊 Data Flow

```
iOS HealthKit
    ↓ (HealthKitManager fetch)
Swift HKSample objects
    ↓ (HealthDataSerializer)
Dictionary [[String: Any]]
    ↓ (FlutterBridge MethodChannel)
Dart List<Map<String, dynamic>>
    ↓ (HealthSyncManager transform)
Backend payload format
    ↓ (HTTP POST /health/samples)
SQLite/Postgres health_samples table
    ↓ (Aggregation queries)
Readiness & Metrics APIs
```

## 🐛 Troubleshooting

**Authorization fails**:
- Check Info.plist has required privacy descriptions
- Verify HealthKit capability enabled in Xcode signing
- Ensure running on real device (not simulator)

**No data returned**:
- Check Health app has actual data
- Verify sample types are authorized
- Reset last fetch timestamps to fetch historical data

**Build errors**:
- Ensure HealthKit framework linked: Xcode → General → Frameworks
- Clean build folder: Product → Clean Build Folder
- Update deployment target to iOS 15.0+

## 🚀 Future Enhancements

- [ ] Background fetch support (iOS background modes)
- [ ] Batch size optimization for large datasets
- [ ] Custom date range queries (override last fetch)
- [ ] Write support for workout logging
- [ ] Observer queries for real-time updates
- [ ] Unit preferences (imperial/metric conversion)
