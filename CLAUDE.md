# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Workout Planner is an AI-powered fitness coaching platform with:
- **Backend**: FastAPI (Python 3.11+) with SQLite (dev) / PostgreSQL (prod)
- **Frontend**: Flutter mobile app with modular package architecture
- **AI Integration**: OpenAI GPT-4 and Anthropic Claude for personalized coaching
- **Infrastructure**: AWS ECS deployment with GitHub Actions CI/CD
- **Multi-App Support**: Configurable ports and context paths for running alongside other applications

## Development Commands

### Backend (FastAPI)

```bash
# Setup and run
cd applications/backend/python_fastapi_server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

# Run on custom port (for multi-app development)
PORT=8001 uvicorn main:app --reload --host 0.0.0.0 --port 8001

# Or use the helper script
PORT=8001 APP_NAME=workout-planner-dev ../../../scripts/run-with-context.sh

# Testing
pytest                                    # Run all tests
pytest test_api.py -v                    # Run specific test file
pytest --cov=. --cov-report=term        # Run with coverage
pytest -k "test_name" -v                 # Run single test by name
pytest tests/test_auth.py::test_register # Run specific test function

# Development with environment variables
# Note: Load env from config/secrets/local.env or use SECRETS_ENV_PATH
export SECRETS_ENV_PATH=/path/to/.env
uvicorn main:app --reload --port 8000

# Docker (local testing)
docker build -t fitness_api:latest .
docker run -p 8000:8000 --env-file .env fitness_api:latest
```

### Frontend (Flutter)

```bash
# Setup and run
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run                              # Run on connected device/emulator
flutter run -d chrome                    # Run web version
flutter run -d macos                     # Run desktop version

# Testing
flutter test                             # Run all unit tests
flutter test test/widget_test.dart       # Run specific test
flutter test --coverage                  # Generate coverage report

# Package management (when modifying local packages)
cd ../../packages/goals_ui               # Navigate to package
flutter pub get                          # Install package dependencies
cd ../../apps/mobile_app && flutter pub get  # Update app references

# Build
flutter build apk                        # Android APK
flutter build ios                        # iOS build (requires Xcode)
flutter build web                        # Web build
```

### Database Operations

The backend automatically initializes the database schema on startup. No manual migration commands needed for basic usage.

For manual database inspection:
```bash
# SQLite (development)
cd applications/backend/python_fastapi_server
sqlite3 fitness_dev.db
.schema                                  # View all tables
.tables                                  # List tables

# PostgreSQL (production)
# Connection string from DATABASE_URL environment variable
```

## Architecture & Code Structure

### Backend Architecture

**Key Principle**: Router-based modular design with shared database connection pool.

```
applications/backend/python_fastapi_server/
├── main.py                 # FastAPI app, middleware, router registration
├── database.py             # Database abstraction (SQLite/PostgreSQL)
├── settings.py             # Pydantic settings (env vars)
├── auth_service.py         # JWT authentication
├── ai_engine.py            # Workout planning engine
├── ai_chat_service.py      # Multi-provider AI chat (OpenAI/Anthropic)
├── cache.py                # Redis caching layer
├── redis_client.py         # Redis connection management
├── metrics.py              # Prometheus metrics
├── logging_config.py       # Structured logging with correlation IDs
├── error_handlers.py       # Global error handling
├── routers/                # API route handlers
│   ├── auth.py             # /register, /login, /logout
│   ├── goals.py            # /goals CRUD endpoints
│   ├── health.py           # /health/samples, /health/summary
│   ├── readiness.py        # /readiness/score, /readiness/history
│   ├── chat.py             # /chat/sessions, /chat/messages
│   ├── daily_plans.py      # /daily-plans CRUD
│   ├── weekly_plans.py     # /weekly-plans CRUD
│   ├── meals.py            # /meals endpoints
│   └── [strength|swim|murph].py  # Workout-specific calculations
└── tests/                  # Pytest test suite
    ├── test_auth.py
    ├── test_daily_plans.py
    ├── test_weekly_plans.py
    └── test_integration.py
```

**Database Access Pattern**:
- Use `get_db()` context manager for connections: `with get_db() as conn:`
- Use `get_cursor(conn)` to get SQLite or PostgreSQL cursor (returns dict-like rows)
- Database is abstracted to support both SQLite (dev) and PostgreSQL (prod)
- Schema is automatically initialized on startup

**Authentication Flow**:
- JWT tokens managed in `auth_service.py`
- Protected routes use `Depends(get_current_user)` dependency
- Token blacklist stored in Redis (see `redis_client.py`)

**AI Integration**:
- `ai_chat_service.py` provides unified interface for OpenAI and Anthropic
- Falls back between providers if one is unavailable
- Uses structured prompts with context about user health data

### Frontend Architecture

**Key Principle**: Modular package architecture for reusability and separation of concerns.

```
applications/frontend/
├── apps/mobile_app/             # Main Flutter application
│   ├── lib/main.dart            # App entry point, navigation
│   └── lib/services/            # API clients, auth service
└── packages/                    # Reusable UI/logic packages
    ├── app_theme/               # Global theming (colors, typography)
    ├── widgets/                 # Shared UI components
    ├── goals_ui/                # Goal setting screens
    ├── home_dashboard_ui/       # Home screen, login screen
    ├── readiness_ui/            # Readiness score display
    ├── todays_workout_ui/       # Daily workout view
    ├── weekly_plan_ui/          # Weekly plan calendar
    ├── ai_insights_ui/          # AI recommendations
    ├── ai_coach_chat/           # Chat interface
    ├── settings_profile_ui/     # User settings
    └── health_integration/      # HealthKit/Google Fit bridge
```

**Package Dependencies**:
- All packages are referenced by path in `pubspec.yaml`
- Changes to packages require `flutter pub get` in both package and app
- Keep packages lightweight and single-purpose

**Navigation Pattern**:
- Bottom navigation bar in `main.dart` switches between major screens
- Each screen is provided by a corresponding package's exported widget

### Cross-Cutting Concerns

**Logging**:
- Backend uses structured JSON logging via `logging_config.py`
- Correlation IDs (`X-Request-ID`) track requests through the system
- Log levels: `log.info()`, `log.warning()`, `log.error()`

**Monitoring**:
- Prometheus metrics exposed at `/metrics` endpoint
- Custom metrics defined in `metrics.py`: request duration, error rates, etc.
- Use `metrics.observe_request()` and `metrics.record_error()` in code

**Caching**:
- Redis-backed caching in `cache.py`
- Cache keys are namespaced by user and resource type
- TTL varies by resource (readiness: 15min, AI responses: 1hr)
- Cache stats available at `/cache/stats`

**Rate Limiting**:
- Enforced via `slowapi` (disabled in dev, enabled in prod)
- Default limits configured per endpoint in routers
- Limiter available as `request.app.state.limiter`

**Security**:
- Security headers added via middleware (main.py:65)
- HSTS enabled in production only
- CORS configured dynamically based on environment
- Passwords hashed with bcrypt via `passlib`

## Deployment

Deployment is managed through a separate [infrastructure repository](https://github.com/srummel/infrastructure).

**Manual Deployment**:
```bash
# Backend
gh workflow run deploy-workout-planner-backend.yml --repo srummel/infrastructure

# Frontend (GitHub Pages)
gh workflow run deploy-workout-planner-frontend.yml --repo srummel/infrastructure
```

**Production URLs**:
- Frontend: https://srummel.github.io/workout-planner/
- Backend: AWS ECS (http://<ECS_IP>:8000)

**Environment Variables** (Backend):
```bash
# Required
DATABASE_URL=sqlite:///fitness_dev.db  # or postgresql://...
SECRET_KEY=your-secret-key-here

# Optional
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_ENABLED=true
ENVIRONMENT=development  # or production
DEBUG=true
```

## Testing Strategy

**Backend Testing**:
- Unit tests for individual routers (e.g., `test_auth.py`)
- Integration tests with real database (`test_integration.py`)
- Test fixtures use SQLite in-memory database
- Mock external APIs (OpenAI, Anthropic) in tests

**Test Patterns**:
```python
# Use TestClient from fastapi.testclient
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)
response = client.get("/endpoint")
assert response.status_code == 200
```

**Frontend Testing**:
- Widget tests in `test/widget_test.dart`
- Integration tests in `integration_test/app_e2e_test.dart`
- Run `flutter test` before committing changes

## Common Development Workflows

### Adding a New API Endpoint

1. Create or modify router in `applications/backend/python_fastapi_server/routers/`
2. Add Pydantic models for request/response
3. Use `get_db()` context manager for database access
4. Add authentication with `Depends(get_current_user)` if needed
5. Write tests in `tests/test_<router>.py`
6. Register router in `main.py` if new

### Adding a New Frontend Screen

1. Create new package in `applications/frontend/packages/`
2. Add `pubspec.yaml` with dependencies
3. Create screen widget in `lib/screens/`
4. Export screen from `lib/<package_name>.dart`
5. Add package dependency to `mobile_app/pubspec.yaml`
6. Integrate into navigation in `mobile_app/lib/main.dart`

### Working with the Database

**Adding a New Table**:
1. Add CREATE TABLE statement in `database.py` in both `init_sqlite()` and `init_postgres()`
2. Add indexes for frequently queried columns
3. Schema will auto-initialize on next app start
4. For production migrations, coordinate with DBA or use Alembic

**Querying Data**:
```python
with get_db() as conn:
    cur = get_cursor(conn)  # Returns dict-like cursor
    cur.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    user = cur.fetchone()  # Returns dict-like row
```

### Debugging Production Issues

1. **Check logs**: `aws logs tail /ecs/workout-planner --follow`
2. **Check health**: `curl http://<ECS_IP>:8000/health`
3. **Check readiness**: `curl http://<ECS_IP>:8000/ready`
4. **Check metrics**: `curl http://<ECS_IP>:8000/metrics`
5. **Check cache stats**: `curl http://<ECS_IP>:8000/cache/stats`

Correlation IDs in logs help trace requests across the system. Look for `X-Request-ID` header in responses.

## Key Files to Know

- `main.py`: Application entry point, middleware setup, router registration
- `database.py`: Database abstraction and schema initialization
- `settings.py`: Environment configuration (reads from .env)
- `auth_service.py`: JWT token generation and validation
- `ai_chat_service.py`: Multi-provider AI chat orchestration
- `routers/auth.py`: User registration, login, logout endpoints
- `routers/chat.py`: AI coach chat session management
- `.github/workflows/ci.yml`: Backend CI pipeline (pytest, coverage)
- `.github/workflows/deploy-backend.yml`: ECS deployment workflow

For detailed architecture and deployment information, see `docs/ARCHITECTURE.md` and `docs/DEPLOYMENT.md`.
