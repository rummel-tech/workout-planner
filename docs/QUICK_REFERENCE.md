# Fitness Agent - Quick Reference

![CI Status](https://github.com/REPLACE_OWNER/REPLACE_REPO/actions/workflows/ci.yml/badge.svg) <!-- Replace with actual owner/repo -->

Continuous Integration runs backend (pytest) and frontend (Flutter) tests on pushes and pull requests to `main`/`master` using GitHub Actions (`.github/workflows/ci.yml`).

## 🚀 Quick Start Commands

### Backend Development
```sh
cd applications/backend/python_fastapi_server
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development
```sh
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run
```

### Run Tests
```sh
# Backend (25+ passing including auth)
cd applications/backend/python_fastapi_server
pytest test_api.py test_auth.py -v

# Frontend
cd applications/frontend/apps/mobile_app
flutter test

# Backend End-to-End Scenario
cd applications/backend/python_fastapi_server
pytest test_e2e.py -v

# Flutter Integration (ensure integration_test dependency added)
cd applications/frontend/apps/mobile_app
flutter test integration_test/app_e2e_test.dart

# Coverage (Backend)
cd applications/backend/python_fastapi_server
pytest --cov=. --cov-report=term-missing --cov-report=xml -q

# Coverage (Frontend Flutter)
cd applications/frontend/apps/mobile_app
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html || echo "Install lcov to generate HTML"
```

### Docker Deployment
```sh
docker compose up --build
# API: http://localhost:8000
# Frontend: http://localhost
```

---

## 📊 Key Features at a Glance

| Feature | Status | Location |
|---------|--------|----------|
| Apple Health Sync | ✅ Complete | `integrations/swift_healthkit_module/` |
| Auto-Sync (15min) | ✅ Complete | `home_dashboard_ui/lib/screens/home_screen.dart` |
| Manual Sync Button | ✅ Complete | Home screen Metrics section |
| AI Coach Chatbot | ✅ Complete | `ai_coach_chat/` package |
| Dynamic Readiness | ✅ Complete | `/readiness` endpoint |
| Goal Tracking | ✅ Complete | `/goals` endpoints |
| Health Deduplication | ✅ Complete | `source_uuid` unique constraint |
| Comprehensive Tests | ✅ 15/15 passing | `test_api.py` |
| CI/CD Pipeline | ✅ Complete | `.github/workflows/ci.yml` |
| Coverage Reporting | ✅ Complete | pytest-cov + Flutter --coverage |

## 📐 Architecture

See **[ARCHITECTURE.md](./ARCHITECTURE.md)** for complete production deployment design including:
- Component deployment targets (AWS/GCP/Azure)
- Network architecture and security
- Scalability and disaster recovery
- Cost estimation
- Infrastructure as Code examples

---

## 🔗 API Endpoints Quick Reference

**Base URL**: `http://localhost:8000`

### Authentication
```
POST   /auth/register               Register new user
POST   /auth/login                  Login and get JWT tokens
POST   /auth/refresh                Refresh access token
GET    /auth/me                     Get current user info (protected)
POST   /auth/logout                 Logout (client-side token removal)
```

### Goals
```
POST   /goals                    Create goal
GET    /goals?user_id=X          List goals
GET    /goals/{id}               Get goal
PUT    /goals/{id}               Update goal
DELETE /goals/{id}               Soft delete
POST   /goals/plans              Create plan
GET    /goals/{id}/plans         List plans
```

### Health
```
POST   /health/samples           Bulk ingest (with dedup)
GET    /health/samples?user_id=X&sample_type=Y  List samples
GET    /health/summary?user_id=X&days=7         Summary
```

### Readiness
```
GET    /readiness?user_id=X      Calculate readiness
```

### Chat
```
POST   /chat/sessions            Create new session
GET    /chat/sessions?user_id=X  List sessions
GET    /chat/sessions/{id}       Get session details
DELETE /chat/sessions/{id}       Delete session
POST   /chat/messages            Send message, get AI response
GET    /chat/messages/{id}       Get messages in session
GET    /chat/context/{user_id}   Get user context (debug)
```

Embedded Chat Panel:
- The home dashboard shows a compact AI Coach chat panel beside the Goals section (stacked on narrow screens, side-by-side on wide).
- Source: `home_dashboard_ui/lib/ui_components/embedded_chat_panel.dart`
- Integrated in: `home_dashboard_ui/lib/screens/home_screen.dart` within the Goals card LayoutBuilder.

---

## 📱 Sample Data Structures

### Goal Creation
```json
{
  "user_id": "user-123",
  "goal_type": "Marathon PR",
  "target_value": 26.2,
  "target_unit": "mi",
  "target_date": "2025-12-31",
  "notes": "Sub-4 hour goal"
}
```

### Health Sample Ingestion
```json
{
  "samples": [{
    "user_id": "user-123",
    "sample_type": "heart_rate",
    "value": 72.0,
    "unit": "bpm",
    "start_time": "2025-11-16T08:00:00Z",
    "end_time": "2025-11-16T08:00:00Z",
    "source_app": "apple.health",
    "source_uuid": "uuid-hr-001"
  }]
}
```

### Readiness Response
```json
{
  "readiness": 0.85,
  "hrv": 55.0,
  "resting_hr": 52,
  "sleep_hours": 7.5
}
```

---

## 🗄️ Database Schema Essentials

### user_goals
```sql
id, user_id, goal_type, target_value, target_unit, 
target_date, notes, is_active, created_at, updated_at
```

### health_samples
```sql
id, user_id, sample_type, value, unit, start_time, 
end_time, source_app, source_uuid, created_at

UNIQUE (user_id, sample_type, start_time, source_uuid)
```

### goal_plans
```sql
id, goal_id, user_id, name, description, 
status, created_at, updated_at
```

---

## 🔐 Environment Variables

```env
DATABASE_URL=sqlite:///fitness_dev.db
# or: postgresql://user:pass@host:5432/db

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_service_role_key
SECRET_KEY=your_secret_key
```

---

## 📂 Key File Locations

| Component | Path |
|-----------|------|
| **Backend API** | `applications/backend/python_fastapi_server/main.py` |
| **Database Schema** | `applications/backend/python_fastapi_server/database.py` |
| **Health Router** | `applications/backend/python_fastapi_server/routers/health.py` |
| **Goals Router** | `applications/backend/python_fastapi_server/routers/goals.py` |
| **Readiness Router** | `applications/backend/python_fastapi_server/routers/readiness.py` |
| **Backend Tests** | `applications/backend/python_fastapi_server/test_api.py` |
| **Mobile App** | `applications/frontend/apps/mobile_app/lib/main.dart` |
| **Home Screen** | `applications/frontend/packages/home_dashboard_ui/lib/screens/home_screen.dart` |
| **Health Sync** | `applications/frontend/packages/home_dashboard_ui/lib/services/health_sync.dart` |
| **Swift HealthKit** | `integrations/swift_healthkit_module/HealthKitManager.swift` |
| **Flutter Bridge** | `integrations/swift_healthkit_module/FlutterBridge.swift` |
| **Widget Tests** | `applications/frontend/apps/mobile_app/test/widget_test.dart` |

---

## 🧪 Testing Quick Commands

```sh
# Backend: Run all tests
pytest test_api.py -v

# Backend: Run specific test class
pytest test_api.py::TestGoalsAPI -v
pytest test_api.py::TestHealthAPI -v

# Backend: With coverage
pytest test_api.py --cov=. --cov-report=html

# Frontend: All tests
flutter test

# Frontend: Specific test
flutter test test/widget_test.dart

# Frontend: With coverage
flutter test --coverage
```

---

## 🐛 Common Troubleshooting

### "Permissions denied" on sync
```sh
# Check iOS Settings → Privacy → Health
# Ensure app has requested permissions
# Re-launch app if needed
```

### "Method Not Allowed 405"
```sh
# Check router is registered in main.py:
app.include_router(health.router)
# Verify no duplicate router definitions
```

### "No data returned from HealthKit"
```swift
// Reset last fetch timestamps in iOS:
UserDefaults.standard.removeObject(forKey: "lastWorkoutFetch")
UserDefaults.standard.removeObject(forKey: "lastHeartRateFetch")
// Restart app
```

### Database schema mismatch
```sh
# Delete and reinitialize:
rm fitness_dev.db fitness_test.db
python -c "from database import init_sqlite; init_sqlite()"
```

---

## 📚 Full Documentation Links

- **Main README**: `README.md`
- **Testing Guide**: `TESTING.md`
- **Test Results**: `TEST_RESULTS.md`
- **Mobile App Guide**: `applications/frontend/apps/mobile_app/README.md`
- **HealthKit Module**: `integrations/swift_healthkit_module/README.md`
- **Health Integration**: `HEALTH_INTEGRATION.md`

---

## 🎯 Development Workflow

1. **Start Backend**:
   ```sh
   cd applications/backend/python_fastapi_server
   uvicorn main:app --reload
   ```

2. **Start Mobile App**:
   ```sh
   cd applications/frontend/apps/mobile_app
   flutter run
   ```

3. **Grant HealthKit Permissions** (first launch)

4. **Observe Auto-Sync** (2 seconds after launch)

5. **Manual Sync** (tap Sync button in Metrics section)

6. **Verify Data**:
   ```sh
   # Check database
   sqlite3 fitness_dev.db "SELECT COUNT(*) FROM health_samples;"
   
   # Test endpoint
   curl http://localhost:8000/health/summary?user_id=user-123
   ```

7. **Run Tests**:
   ```sh
   pytest test_api.py -v
   flutter test
   ```

---

## 🚀 Production Deployment Checklist

- [ ] Update `baseUrl` in `health_sync.dart` to production API
- [ ] Set environment variables (DATABASE_URL, SECRET_KEY)
- [ ] Run database migrations
- [ ] Build backend Docker image
- [ ] Build mobile app release: `flutter build ios --release`
- [ ] Configure HealthKit entitlements in Xcode
- [ ] Add App Store privacy declarations
- [ ] Test sync on physical device
- [ ] Monitor error rates and sync success
- [ ] Set up logging and alerting

---

## 📊 Metrics & Monitoring

**Backend Health Check**:
```sh
curl http://localhost:8000/docs  # Swagger UI
```

**Database Stats**:
```sql
SELECT sample_type, COUNT(*) FROM health_samples GROUP BY sample_type;
SELECT COUNT(*) FROM user_goals WHERE is_active = 1;
```

**App Logs** (iOS):
```sh
# View device logs in Xcode
# Window → Devices and Simulators → Select device → Open Console
```

---

## 🔄 Update Procedures

### Adding New Health Metric
1. Update Swift `HealthKitManager.swift`
2. Add case to `FlutterBridge.swift`
3. Add Dart wrapper in `healthkit_bridge.dart`
4. Update transformation in `health_sync.dart`
5. Backend accepts automatically (sample_type is TEXT)

### Adding New Goal Field
1. Update `database.py` schema
2. Add migration check for new column
3. Update Pydantic models in `routers/goals.py`
4. Update Dart model in `goal_model.dart`
5. Update UI in `goals_screen.dart`
6. Add test in `test_api.py`

---

**Last Updated**: November 16, 2025  
**Version**: 1.0  
**Tests Passing**: 15/15 backend, Widget tests ready
