# Apple Health Integration - Complete Implementation Guide

This document describes the end-to-end flow of Apple Health (HealthKit) data from iOS device through to backend storage, aggregation, and readiness calculation.

## 🎯 Implementation Status: ✅ COMPLETE

All components are fully implemented and tested:
- ✅ HealthKit permissions and authorization
- ✅ Multi-type sample fetching (workouts, HR, HRV, sleep)
- ✅ Swift → Flutter bridge
- ✅ Batch ingestion with deduplication
- ✅ Backend storage with indices
- ✅ Readiness calculation endpoint
- ✅ Auto-sync (startup + periodic 15min)
- ✅ Manual sync button with UI feedback

## 📊 Data Flow Overview

```
┌─────────────────┐
│  Apple Health   │
│   (HealthKit)   │
└────────┬────────┘
         │ 1. Authorization
         ↓
┌─────────────────┐
│ HealthKitManager│ ← Swift native layer
│  - fetchWorkouts│
│  - fetchHeartRate
│  - fetchHRV    │
│  - fetchSleep   │
└────────┬────────┘
         │ 2. Serialize HKSamples
         ↓
┌─────────────────┐
│ FlutterBridge   │ ← Method channel
│ (healthkit_bridge)
└────────┬────────┘
         │ 3. Return List<Map>
         ↓
┌─────────────────┐
│ HealthSyncManager│ ← Dart service
│  - fetch all    │
│  - transform    │
│  - batch ingest │
└────────┬────────┘
         │ 4. POST /health/samples
         ↓
┌─────────────────┐
│  FastAPI Backend│
│  /health/samples│
│  (dedup via     │
│   source_uuid)  │
└────────┬────────┘
         │ 5. INSERT OR IGNORE
         ↓
┌─────────────────┐
│  health_samples │ ← SQLite/Postgres
│  Table          │
│  + indices      │
└────────┬────────┘
         │ 6. Aggregate queries
         ↓
┌─────────────────┐
│ /health/summary │
│ /readiness      │ ← API endpoints
│ Home Screen UI  │
└─────────────────┘
```

## 🔐 1. HealthKit Permissions

### Requested Access Types
**Workouts**: All activity types (running, cycling, swimming, strength, etc.)
**Quantities**:
- Heart Rate (`HKQuantityTypeIdentifier.heartRate`)
- Heart Rate Variability SDNN (`HKQuantityTypeIdentifier.heartRateVariabilitySDNN`)
- Resting Heart Rate (`HKQuantityTypeIdentifier.restingHeartRate`)
- VO2 Max (`HKQuantityTypeIdentifier.vo2Max`)
- Active Energy Burned (`HKQuantityTypeIdentifier.activeEnergyBurned`)
**Categories**:
- Sleep Analysis (`HKCategoryTypeIdentifier.sleepAnalysis`)

### Implementation
```swift
// HealthKitManager.swift
func requestPermissions(completion: @escaping (Bool) -> Void) {
    let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        // ... all types
    ]
    healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
        completion(success)
    }
}
```

## 📱 2. Sample Collection (Swift)

## HealthKit Permissions
Add any new quantity types to `typesToRead` inside `HealthKitManager.requestPermissions`. For example:
```swift
HKObjectType.quantityType(forIdentifier: .stepCount)!
HKObjectType.quantityType(forIdentifier: .bodyMass)!
HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
```
Rebuild and ensure the app explains why: update the iOS Info.plist with usage descriptions:
```
<key>NSHealthShareUsageDescription</key>
<string>We use your health data to personalize training and recovery recommendations.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>We update your health metrics to keep insights current.</string>
```

## Additional Sample Fetching (Quantities)
Extend `HealthKitManager` with a generic fetch:
```swift
func fetchQuantitySamples(identifier: HKQuantityTypeIdentifier, since: Date, completion: @escaping ([HKQuantitySample]) -> Void) { ... }
```
Serialize with a new method in `HealthDataSerializer`:
```swift
static func serializeQuantitySamples(_ samples: [HKQuantitySample], unit: HKUnit) -> [[String: Any]] { ... }
```
Expose via method channel (e.g. `fetchHeartRate`, `fetchHRV`).

## Flutter Side Ingestion
Create a service that:
1. Calls `HealthKitBridge.requestPermissions()` once (onboard or settings screen).
2. Schedules background/foreground fetch (e.g. on app resume) invoking channel methods.
3. Maps workout objects into `HealthSample` payloads:
```dart
{
  'user_id': userId,
  'sample_type': 'workout',
  'value': distanceMeters,
  'unit': 'm',
  'start_time': startIso,
  'end_time': endIso,
  'source_app': 'apple.health'
}
```
4. POSTs bulk array to `/health/samples`.

## Backend Schema
`health_samples` columns:
- user_id: partition key for multi-user environment later.
- sample_type: e.g. `workout`, `heart_rate`, `hrv`, `sleep`, `resting_hr`.
- value + unit: numeric value and its unit (m, bpm, ms, kcals, hours).
- start_time / end_time: ISO8601 string (use UTC).
- source_app: provenance (apple.health).

Indices: `idx_health_samples_user_id`, `idx_health_samples_type_time` optimize queries for user/time windows.

### Fetch Methods
Each method queries HealthKit since last fetch timestamp (stored in UserDefaults):

**fetchWorkouts()**
- Sample type: `HKWorkoutType`
- Returns: workout type, start, end, distance (m), calories (kcal), UUID
- Last fetch key: `lastWorkoutFetch`

**fetchHeartRate()**
- Quantity type: `.heartRate`
- Unit: `count/min` (bpm)
- Returns: value, start, end, source, UUID

**fetchHRV()**
- Quantity type: `.heartRateVariabilitySDNN`
- Unit: `ms`
- Returns: SDNN value, timestamps, UUID

**fetchRestingHeartRate()**
- Quantity type: `.restingHeartRate`
- Unit: `count/min` (bpm)
- Returns: resting HR value, timestamps, UUID

**fetchSleep()**
- Category type: `.sleepAnalysis`
- Returns: sleep stage code (0=inBed, 1=asleep, 2=awake, 3=core, 4=deep, 5=REM), start, end, UUID

### Incremental Sync
```swift
let lastFetch = UserDefaults.standard.double(forKey: "lastWorkoutFetch")
let since = lastFetch > 0 ? Date(timeIntervalSince1970: lastFetch) : Date().addingTimeInterval(-30*24*60*60)
// Query samples from 'since' to now
// Save new timestamp after successful fetch
```

## 🔄 3. Serialization (Swift → Dart)

**HealthDataSerializer.swift** converts HKSample objects to dictionaries:

```swift
static func serializeWorkouts(_ workouts: [HKWorkout]) -> [[String: Any]] {
    return workouts.map { workout in
        [
            "uuid": workout.uuid.uuidString,
            "type": workout.workoutActivityType.rawValue,
            "start": workout.startDate.timeIntervalSince1970,
            "end": workout.endDate.timeIntervalSince1970,
            "distance": workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
            "calories": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
            "source": workout.sourceRevision.source.name
        ]
    }
}
```

## 🌉 4. Flutter Bridge

**FlutterBridge.swift** exposes method channel:

```swift
let channel = FlutterMethodChannel(name: "healthkit_bridge", binaryMessenger: messenger)
channel.setMethodCallHandler { call, result in
    switch call.method {
    case "requestPermissions":
        self.healthKitManager.requestPermissions { granted in
            result(granted)
        }
    case "fetchWorkouts":
        self.healthKitManager.fetchWorkouts { workouts in
            let serialized = HealthDataSerializer.serializeWorkouts(workouts)
            result(serialized)
        }
    // ... other cases
    }
}
```

**Dart side** (`healthkit_bridge.dart`):
```dart
class HealthKitBridge {
  static const MethodChannel _channel = MethodChannel('healthkit_bridge');
  
  Future<bool> requestPermissions() async {
    return await _channel.invokeMethod('requestPermissions') ?? false;
  }
  
  Future<List<Map<String, dynamic>>> fetchWorkouts() async {
    final result = await _channel.invokeMethod('fetchWorkouts');
    return (result as List).cast<Map<String, dynamic>>();
  }
}
```

## 🔄 5. Batch Ingestion (Flutter)

**HealthSyncManager** (`health_sync.dart`) orchestrates the sync:

### Process
1. **Request permissions** (if not already granted)
2. **Fetch all sample types** in parallel:
   ```dart
   final workouts = await _fetchList('fetchWorkouts');
   final heartRate = await _fetchList('fetchHeartRate');
   final hrv = await _fetchList('fetchHRV');
   final resting = await _fetchList('fetchRestingHeartRate');
   final sleep = await _fetchList('fetchSleep');
   ```

3. **Transform to backend format**:
   ```dart
   List<Map<String, dynamic>> _transform({...}) {
     final samples = <Map<String, dynamic>>[];
     // For each workout
     for (final w in workouts) {
       samples.add({
         'user_id': userId,
         'sample_type': 'workout_distance',
         'value': w['distance'].toDouble(),
         'unit': 'm',
         'start_time': _iso(w['start']),
         'end_time': _iso(w['end']),
         'source_app': 'apple.health',
         'source_uuid': w['uuid'],
       });
       // Add calories sample if > 0
     }
     // Similar for HR, HRV, resting HR, sleep
     return samples;
   }
   ```

4. **Batch ingest** (chunks of 100 by default):
   ```dart
   for (var i = 0; i < samples.length; i += batchSize) {
     final chunk = samples.sublist(i, min(i + batchSize, samples.length));
     inserted += await _ingestChunk(chunk);
   }
   ```

5. **Return result**:
   ```dart
   return HealthSyncResult(
     inserted: inserted,
     total: samples.length,
     errors: errors
   );
   ```

## 💾 6. Backend Storage

### Endpoint: `POST /health/samples`
```python
@router.post("/samples")
def ingest_samples(payload: BulkSamples):
    # Build INSERT query with all samples
    query = "INSERT INTO health_samples (user_id, sample_type, value, unit, start_time, end_time, source_app, source_uuid) VALUES ..."
    
    # SQLite: Use INSERT OR IGNORE for deduplication
    if USE_SQLITE:
        query = "INSERT OR IGNORE " + query[len("INSERT "):]
    
    cur.execute(query, params)
    return {"inserted": cur.rowcount, "total": len(payload.samples)}
```

### Schema: `health_samples`
```sql
CREATE TABLE health_samples (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    sample_type TEXT NOT NULL,
    value REAL,
    unit TEXT,
    start_time TEXT,
    end_time TEXT,
    source_app TEXT,
    source_uuid TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_health_samples_user_id ON health_samples(user_id);
CREATE INDEX idx_health_samples_type_time ON health_samples(sample_type, start_time);
CREATE UNIQUE INDEX idx_health_samples_dedupe ON health_samples(user_id, sample_type, start_time, source_uuid);
```

### Deduplication Strategy
- **Composite unique constraint**: (user_id, sample_type, start_time, source_uuid)
- **SQLite**: `INSERT OR IGNORE` silently skips duplicates
- **Postgres**: `ON CONFLICT DO NOTHING` (requires adaptation)

## 📊 7. Aggregation & Queries

### Endpoint: `GET /health/summary?user_id=X&days=7`
```python
@router.get("/summary")
def summary(user_id: str, days: int = 7):
    since = (datetime.utcnow() - timedelta(days=days)).isoformat()
    query = """
        SELECT sample_type, COUNT(*) as count, SUM(value) as total, AVG(value) as avg_value
        FROM health_samples
        WHERE user_id = ? AND start_time >= ?
        GROUP BY sample_type
    """
    # Returns dict keyed by sample_type with counts and totals
```

### Endpoint: `GET /readiness?user_id=X`
```python
@router.get("")
def calculate_readiness(user_id: str):
    # Fetch recent (1 day) and baseline (14 days)
    recent_hrv = avg(samples where sample_type='hrv' AND age < 1 day)
    baseline_hrv = avg(samples where sample_type='hrv' AND age 1-15 days)
    hrv_score = recent_hrv / baseline_hrv  # Higher is better
    
    recent_rhr = avg(samples where sample_type='resting_hr' AND age < 1 day)
    baseline_rhr = avg(samples where sample_type='resting_hr' AND age 1-15 days)
    rhr_score = baseline_rhr / recent_rhr  # Lower RHR is better (inverted)
    
    sleep_hours = sum(sleep_stage durations) / 3600  # Convert seconds to hours
    sleep_score = sleep_hours / 8.0  # Target 8 hours
    
    readiness = (hrv_score + rhr_score + sleep_score) / 3.0  # Simple average
    return {
        "readiness": min(readiness, 1.0),  # Cap at 1.0
        "hrv": recent_hrv,
        "resting_hr": recent_rhr,
        "sleep_hours": sleep_hours
    }
```

## 🔄 8. Auto-Sync Implementation

### Home Screen Integration
```dart
// home_screen.dart
Timer? _syncTimer;

@override
void initState() {
  super.initState();
  // Auto-sync 2 seconds after launch
  Future.delayed(const Duration(seconds: 2), _performSync);
  
  // Periodic sync every 15 minutes
  _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _performSync());
}

Future<void> _performSync() async {
  if (_syncing) return;  // Prevent concurrent syncs
  
  setState(() { _syncing = true; });
  
  final sync = HealthSync(userId: 'user-123');
  final result = await sync.perform();
  
  if (result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Synced ${result.inserted}/${result.total} samples'))
    );
    await _loadHealth();
    await _loadReadiness();
  }
  
  setState(() { _syncing = false; });
}
```

### Manual Sync Button
```dart
ElevatedButton.icon(
  onPressed: _syncing ? null : _performSync,
  icon: _syncing 
    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
    : const Icon(Icons.sync, size: 16),
  label: Text(_syncing ? 'Syncing...' : 'Sync'),
)
```

## 📈 Sample Type Mapping & Usage

| Sample Type | Source | Unit | Readiness Weight | Display |
|-------------|--------|------|-----------------|---------|
| `workout_distance` | HKWorkout.totalDistance | m | ❌ (future: training load) | Distance (km) |
| `workout_calories` | HKWorkout.totalEnergyBurned | kcal | ❌ (future: training load) | Calories |
| `heart_rate` | HKQuantityType.heartRate | bpm | ❌ (context only) | — |
| `hrv` | HKQuantityType.heartRateVariabilitySDNN | ms | ✅ 33% | Readiness card |
| `resting_hr` | HKQuantityType.restingHeartRate | bpm | ✅ 33% | Readiness card |
| `sleep_stage` | HKCategoryType.sleepAnalysis | code | ✅ 33% | Sleep hours |

## 🧪 Testing & Validation

### Backend Tests
```sh
pytest test_api.py::TestHealthAPI -v
```
- ✅ Single sample ingestion
- ✅ Deduplication (re-send same source_uuid)
- ✅ Batch ingestion (10+ samples)
- ✅ List samples with filters
- ✅ Summary aggregation

### Flutter Tests
```sh
flutter test test/health_sync_test.dart
```
- ✅ HealthSync configuration
- ✅ Sample transformation
- ✅ Batch processing logic
- ✅ Error handling
- ✅ Dedup support

## 🐛 Troubleshooting

**No samples ingested**:
- Check HealthKit permissions in Settings → Privacy → Health
- Verify Health app has actual data
- Reset last fetch timestamps in Swift UserDefaults
- Check backend logs for ingestion errors

**Duplicate samples**:
- Ensure `source_uuid` is being passed from native layer
- Verify unique index exists on health_samples table
- Check SQLite is using `INSERT OR IGNORE`

**Readiness shows 0.0**:
- Verify HRV, resting HR, and sleep samples exist
- Check date range (needs 1-day recent + 14-day baseline)
- Inspect `/health/samples` to confirm data presence

**Sync button stuck on "Syncing..."**:
- Check for errors in snackbar message
- Verify backend is accessible
- Look for network timeouts in logs
3. Combine into readiness index (weighted). Existing readiness endpoint can be modified to source from `health_samples`.

## Next Steps
- Implement quantity sample fetches & serialization for HRV, resting HR, sleep.
- Add cron / background refresh using iOS background tasks or silent push.
- Expand `/health/summary` to include min/max/latest per sample_type.
- Integrate readiness generator to query aggregated stats rather than placeholder values.

## Troubleshooting
- Permissions failing: verify Info.plist descriptions and device Health settings.
- Empty fetch: ensure last fetch timestamp is earlier than expected, or reset by deleting the `lastWorkoutFetch` key.
- Performance: batch inserts instead of single requests; already supported via bulk endpoint.

## Security & Privacy
- Store only necessary metrics; avoid personally identifying health metadata beyond training needs.
- Offer user toggle to disable health sync.
- Potential encryption at rest if migrating to production infrastructure.
