# Workout Planner - Running Locally

**Status**: ✅ **RUNNING**
**Last Started**: 2026-01-22

## 🚀 Quick Start - Use the Dev Script!

**The easiest way to manage local development:**

```bash
# Check if services are running
./dev.sh status

# After making code changes
./dev.sh hot-reload

# View logs
./dev.sh logs

# See all commands
./dev.sh help
```

**📖 Complete Guide**: See [DEV_QUICK_START.md](./DEV_QUICK_START.md)

---

## Quick Access

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **DevTools**: http://127.0.0.1:41179/StEvPV9OX2A=/devtools/

## Dev Script Quick Reference

| Task | Command |
|------|---------|
| Check status | `./dev.sh status` or `./dev.sh st` |
| Hot reload (fast) | `./dev.sh hot-reload` or `./dev.sh r` |
| Hot restart | `./dev.sh hot-restart` |
| View logs | `./dev.sh logs` |
| Start all | `./dev.sh start-all` |
| Stop all | `./dev.sh stop-all` |
| Restart all | `./dev.sh restart-all` |
| Run tests | `./dev.sh test-all` |

## System Status

### Backend (FastAPI)

```
URL:          http://localhost:8000
Status:       ✅ Running
PID:          28654
Database:     SQLite (fitness_dev.db)
Migrations:   ✅ Up to date (561152f2b473)
Log File:     /tmp/workout-planner.log
```

**Health Check Endpoints:**
- `GET /health` - Basic health
- `GET /healthz` - Liveness probe
- `GET /readyz` - Readiness probe
- `GET /health/db` - Database health with latency

**Test Backend:**
```bash
curl http://localhost:8000/healthz | jq .
```

### Frontend (Flutter Web)

```
URL:          http://localhost:8080
Status:       ✅ Running
PID:          32456
Backend:      http://localhost:8000 (configured)
Log File:     /tmp/flutter-workout.log
```

**Test Frontend:**
```bash
curl -s http://localhost:8080 -w "Status: %{http_code}\n"
```

## Architecture

```
┌─────────────────────────────────────┐
│  Flutter Web App                    │
│  http://localhost:8080              │
│                                     │
│  Features:                          │
│  • User Auth (Login/Register)      │
│  • Goal Setting                     │
│  • Health Data Integration          │
│  • Workout Planning                 │
│  • AI Coach Chat                    │
│  • Readiness Score                  │
└──────────────┬──────────────────────┘
               │ HTTP REST API
               ↓
┌─────────────────────────────────────┐
│  FastAPI Backend                    │
│  http://localhost:8000              │
│                                     │
│  • JWT Authentication               │
│  • RESTful API                      │
│  • Health Checks                    │
│  • Prometheus Metrics               │
│  • Alembic Migrations               │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  SQLite Database                    │
│  fitness_dev.db                     │
│                                     │
│  • 15 tables                        │
│  • Migration version: 561152f2b473  │
│  • Auto-initialized                 │
└─────────────────────────────────────┘
```

## Using the App

### 1. Open the App

Navigate to http://localhost:8080 in your browser (should already be open in Chrome).

### 2. Register/Login

**Register a new account:**
1. Click "Register" or "Sign Up"
2. Enter email and password
3. Optionally add your name

**Or use the API directly:**
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123",
    "full_name": "Test User"
  }'
```

### 3. Set Goals

1. Navigate to Goals section
2. Set your fitness goals (weight, strength, endurance, etc.)
3. Let the AI generate a personalized plan

### 4. Track Progress

- **Health Data**: Import from HealthKit/Google Fit or enter manually
- **Readiness Score**: View your daily readiness based on HRV, sleep, etc.
- **Workout Plans**: Follow your personalized daily/weekly plans
- **AI Coach**: Chat with the AI for guidance and adjustments

## Development Workflow

### Hot Reload (Flutter)

The Flutter app supports hot reload for fast development:

1. Make changes to Flutter code
2. Save the file
3. App automatically reloads in browser

### API Changes (Backend)

The backend runs with `--reload`, so changes are automatically detected:

1. Edit Python files
2. Save changes
3. Backend automatically restarts
4. Check logs: `tail -f /tmp/workout-planner.log`

### Database Changes

Use Alembic for schema changes:

```bash
# Create migration
cd /home/shawn/_Projects/services/workout-planner
alembic revision -m "add_new_column"

# Edit migration file
# migrations/versions/<revision>_add_new_column.py

# Apply migration
alembic upgrade head

# Rollback if needed
alembic downgrade -1
```

## Management Commands

### Stop Services

```bash
# Stop Flutter app
kill 32456

# Stop backend
kill 28654

# Stop both
killall flutter uvicorn
```

### Restart Services

**Backend:**
```bash
cd /home/shawn/_Projects/services/workout-planner
source .venv/bin/activate
uvicorn main:app --reload --port 8000 > /tmp/workout-planner.log 2>&1 &
```

**Frontend:**
```bash
cd /home/shawn/_Projects/modules/planners/workout-planner
flutter run -d chrome --web-port 8080 > /tmp/flutter-workout.log 2>&1 &
```

### View Logs

```bash
# Backend logs
tail -f /tmp/workout-planner.log

# Frontend logs
tail -f /tmp/flutter-workout.log

# Both
tail -f /tmp/workout-planner.log /tmp/flutter-workout.log
```

### Check Status

```bash
# Check if services are running
ps aux | grep -E "(flutter|uvicorn)" | grep -v grep

# Check ports
lsof -i :8080 -i :8000

# Test health
curl http://localhost:8000/healthz | jq .
curl http://localhost:8080 -w "\nStatus: %{http_code}\n"
```

## Testing

### Backend Tests

```bash
cd /home/shawn/_Projects/services/workout-planner
source .venv/bin/activate

# Run all tests
pytest

# Run specific test file
pytest tests/test_health.py

# Run with coverage
pytest --cov=. --cov-report=html
```

### Frontend Tests

```bash
cd /home/shawn/_Projects/modules/planners/workout-planner

# Run unit tests
flutter test

# Run integration tests
flutter drive --driver=test_driver/integration_test.dart
```

### Manual Testing

**Test Registration Flow:**
1. Open http://localhost:8080
2. Click "Register"
3. Fill in details
4. Submit
5. Should redirect to app

**Test API Directly:**
```bash
# Register user
TOKEN=$(curl -s -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123"}' \
  | jq -r '.access_token')

# Get user info
curl http://localhost:8000/auth/me \
  -H "Authorization: Bearer $TOKEN" | jq .

# Create goal
curl -X POST http://localhost:8000/goals \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "your_user_id",
    "goal_type": "weight_loss",
    "target_value": 75,
    "target_unit": "kg",
    "target_date": "2026-06-01"
  }'
```

## Configuration

### Backend Configuration

Environment variables (`.env` file):

```bash
# Database
DATABASE_URL=sqlite:///fitness_dev.db

# Development mode
ENVIRONMENT=development
DEBUG=true
DISABLE_AUTH=false

# API Keys (optional for development)
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
```

### Frontend Configuration

The Flutter app reads API URL from environment:

```dart
// lib/config/env_config.dart
static String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:8000';  // Development default
  }
  // ... platform-specific configs
}
```

**Override at runtime:**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://custom:8000
```

## Monitoring

### Backend Metrics

View Prometheus metrics:
```bash
curl http://localhost:8000/metrics
```

Key metrics:
- `workout_planner_request_count_total` - Total requests
- `workout_planner_request_duration_seconds` - Request latency
- `process_cpu_seconds_total` - CPU usage
- `process_resident_memory_bytes` - Memory usage

### DevTools

Flutter DevTools are available at:
http://127.0.0.1:41179/StEvPV9OX2A=/devtools/

Features:
- Widget inspector
- Timeline profiler
- Memory profiler
- Network profiler
- Logging view

## Troubleshooting

### Frontend Won't Load

```bash
# Check if running
ps aux | grep flutter

# Check logs
tail -50 /tmp/flutter-workout.log

# Restart
kill 32456
cd /home/shawn/_Projects/modules/planners/workout-planner
flutter run -d chrome --web-port 8080
```

### Backend Errors

```bash
# Check logs
tail -50 /tmp/workout-planner.log

# Test health
curl http://localhost:8000/health/db

# Restart
kill 28654
cd /home/shawn/_Projects/services/workout-planner
source .venv/bin/activate
uvicorn main:app --reload --port 8000
```

### "Cannot connect to backend"

1. **Check backend is running:**
   ```bash
   curl http://localhost:8000/health
   ```

2. **Check frontend config:**
   ```bash
   grep apiBaseUrl lib/config/env_config.dart
   ```

3. **Check CORS settings:**
   Backend allows `http://localhost:8080` by default

4. **Check browser console:**
   Open DevTools (F12) and look for network errors

### Database Issues

```bash
# Check database file
ls -lh fitness_dev.db

# Check migration status
alembic current

# View tables
sqlite3 fitness_dev.db ".tables"

# Reset database (CAREFUL!)
rm fitness_dev.db
alembic upgrade head
```

## Production Deployment

When ready to deploy:

1. **Backend**: See `/home/shawn/_Projects/services/workout-planner/MIGRATION_READINESS_SUMMARY.md`
2. **Frontend**: Build production web bundle:
   ```bash
   flutter build web --release
   ```

3. **Deploy**: See infrastructure repository deployment workflows

## Support & Documentation

- **Backend Docs**: `/home/shawn/_Projects/services/workout-planner/README.md`
- **Migration Guide**: `/home/shawn/_Projects/services/workout-planner/migrations/README.md`
- **Flutter Docs**: `/home/shawn/_Projects/modules/planners/workout-planner/CLAUDE.md`
- **API Reference**: http://localhost:8000/docs

---

**Full Stack Status**: ✅ Running
**Frontend**: http://localhost:8080
**Backend**: http://localhost:8000
**Ready for Development** 🚀
