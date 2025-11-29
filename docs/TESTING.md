# Testing Guide for Fitness Agent

## Backend Tests (Python/FastAPI)

### Running Backend Tests

```bash
cd applications/backend/python_fastapi_server

# Install test dependencies
pip install pytest pytest-asyncio

# Run all tests
pytest test_api.py -v

# Run specific test class
pytest test_api.py::TestGoalsAPI -v

# Run with coverage
pytest test_api.py --cov=. --cov-report=html
```

### Test Coverage

**Goals API** (`TestGoalsAPI`)
- ✅ Create goal with target_unit
- ✅ Create goal without unit
- ✅ Update goal unit
- ✅ List goals by user
- ✅ Delete goal (soft delete)

**Goal Plans API** (`TestGoalPlansAPI`)
- ✅ Create plan for goal
- ✅ List plans for specific goal

**Health API** (`TestHealthAPI`)
- ✅ Ingest single sample
- ✅ Deduplication via source_uuid
- ✅ Batch ingest (10+ samples)
- ✅ List samples with filters
- ✅ Summary aggregation

**Readiness API** (`TestReadinessAPI`)
- ✅ Calculate readiness with real data
- ✅ Handle missing data gracefully

**Integration** (`TestIntegration`)
- ✅ Full workflow: goal → health → readiness

### Key Test Features

1. **Isolated Test Database**: Each test uses fresh `fitness_test.db`
2. **Deduplication Verification**: Tests ignore duplicate source_uuid
3. **Batch Processing**: Tests handle 100+ samples efficiently
4. **Error Handling**: Tests verify graceful degradation

---

## Frontend Tests (Flutter/Dart)

### Running Flutter Widget Tests

```bash
cd applications/frontend/apps/mobile_app

# Run all widget tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
flutter pub global activate coverage
genhtml coverage/lcov.info -o coverage/html
```

### Running Dart Unit Tests

```bash
cd applications/frontend/packages/home_dashboard_ui

# Run HealthSync unit tests
flutter test test/health_sync_test.dart -v
```

### Test Coverage

**Widget Tests** (`widget_test.dart`)
- ✅ App initialization and title display
- ✅ Home screen key sections (Goals, Metrics)
- ✅ Sync button presence and tap behavior
- ✅ Sync loading states
- ✅ Goals display and empty state
- ✅ Navigation to goals screen
- ✅ Metrics display (Workouts, Distance, Calories)
- ✅ Metrics loading and error states
- ✅ Readiness card presence
- ✅ Quick action buttons
- ✅ User profile display
- ✅ Auto-sync on startup
- ✅ Error handling and graceful degradation

**Unit Tests** (`health_sync_test.dart`)
- ✅ HealthSyncResult success/failure logic
- ✅ HealthSync configuration (userId, baseUrl, batchSize)
- ✅ Sample transformation (workouts, HR, HRV, sleep)
- ✅ Batch processing with configurable sizes
- ✅ Error collection during batch processing
- ✅ Deduplication support via source_uuid
- ✅ Sample type mapping correctness
- ✅ Empty data handling
- ✅ Performance optimizations

### Test Features

1. **Async Handling**: `pumpAndSettle` waits for data loading
2. **Loading States**: Verifies CircularProgressIndicator during sync
3. **Error Display**: Checks error messages shown to users
4. **Navigation**: Tests screen transitions
5. **Auto-sync**: Verifies 2-second startup delay

---

## Test Data

### Sample Goal (with unit)
```json
{
  "user_id": "test-user",
  "goal_type": "Marathon PR",
  "target_value": 26.2,
  "target_unit": "mi",
  "target_date": "2025-12-31",
  "notes": "Sub-4 hour goal"
}
```

### Sample Health Data
```json
{
  "user_id": "test-user",
  "sample_type": "heart_rate",
  "value": 72.0,
  "unit": "bpm",
  "start_time": "2025-11-16T08:00:00Z",
  "end_time": "2025-11-16T08:00:00Z",
  "source_app": "apple.health",
  "source_uuid": "unique-uuid-123"
}
```

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - run: pip install -r requirements.txt pytest
      - run: cd applications/backend/python_fastapi_server && pytest test_api.py -v

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd applications/frontend/apps/mobile_app && flutter test
```

---

## Manual Testing Checklist

### Backend API
- [ ] Start backend: `uvicorn main:app --reload`
- [ ] Create goal with unit via Postman/curl
- [ ] Update goal target_value and target_unit
- [ ] Ingest health samples (single and batch)
- [ ] Verify deduplication (re-send same source_uuid)
- [ ] Check readiness calculation with data
- [ ] Test CORS for mobile app

### Mobile App
- [ ] Launch app on physical iOS device
- [ ] Grant HealthKit permissions
- [ ] Tap Sync button manually
- [ ] Verify auto-sync after 2 seconds
- [ ] Create goal with suffixed value (e.g., "5k")
- [ ] Navigate to Goals screen
- [ ] Check metrics update after sync
- [ ] Verify readiness card shows data
- [ ] Test with airplane mode (error handling)

---

## Known Test Limitations

1. **Widget Tests**: Import errors shown are analysis-time only; tests run correctly with `flutter test`
2. **HealthSync Tests**: Some private methods (`_transform`, `_iso`) tested indirectly
3. **HealthKit Mocking**: Native MethodChannel not mocked; requires integration testing on device
4. **Backend Database**: Tests use SQLite only; Postgres dedup logic needs separate testing
5. **Network Mocking**: HTTP calls in HealthSync not mocked; requires backend running or custom HttpClient injection

---

## Future Test Enhancements

1. **E2E Tests**: Integrate Appium or Flutter Driver for full flow testing
2. **Load Testing**: Use `locust` to test batch ingestion at scale (1000+ samples)
3. **Sleep Consolidation**: Add tests for nightly sleep aggregation when implemented
4. **Training Load**: Test readiness weighting with distance/calories trends
5. **Background Sync**: Test iOS background fetch simulation
6. **Network Retry**: Test exponential backoff on ingestion failures

---

## Test Maintenance

- Update `test_api.py` when adding new backend endpoints
- Update `widget_test.dart` when changing home screen UI
- Add new unit test files for new services/utilities
- Keep test data realistic (actual HealthKit value ranges)
- Document breaking changes in test fixtures
