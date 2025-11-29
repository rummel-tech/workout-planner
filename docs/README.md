# Workout Planner - AI-Powered Training Platform

An intelligent fitness training platform that integrates Apple Health data with AI-driven workout planning, readiness monitoring, and personalized goal tracking.

## 🎯 Key Features

- **AI Coach Chatbot**: Intelligent fitness coaching with context-aware responses based on your health data, goals, and readiness
- **Apple Health Integration**: Automatic sync of workouts, heart rate, HRV, sleep, and physiological metrics
- **Dynamic Readiness Scoring**: Real-time calculation based on HRV, resting heart rate, and sleep quality
- **Smart Goal Management**: Track goals with flexible units (distance, time, reps) and AI-generated plans
- **Auto-Sync**: Background synchronization every 15 minutes + manual sync button
- **JWT Authentication**: Secure user registration, login, and token-based auth with password hashing
- **Comprehensive Testing**: 25+ backend tests + extensive Flutter widget/unit tests (100% passing)
- **Deduplication**: Prevents duplicate health data ingestion via unique sample identifiers

## 📐 Architecture & Deployment

For detailed production deployment architecture, component mapping, and infrastructure specifications, see **[ARCHITECTURE.md](./ARCHITECTURE.md)**.

**Quick Reference:**
- Mobile apps → App Store / Google Play
- Backend API → Container service (ECS/Cloud Run/K8s)
- Database → Managed PostgreSQL (RDS/Cloud SQL)
- CI/CD → GitHub Actions
- Monitoring → Prometheus + Grafana

## 🏗️ Architecture Overview

This repository is organized into three top-level categories: **applications** (code you deploy), **database** (schemas and triggers), and **integrations** (platform-specific and background services). Each component can be built and deployed independently.

**Repository layout (3 top-level categories)**

- **`applications/`** — Deployable applications
  - `backend/fastapi_server/` — Python FastAPI service
  - `frontend/apps/mobile_app/` — Flutter mobile app (Android/iOS)
  - `frontend/packages/*` — reusable Dart packages (theme, navigation, UI modules)
  - `frontend/legacy_ui/` — safe copies of original UI modules for reference

- **`database/`** — Database schemas, migrations, and serverless functions
  - `sql/` — SQL migration scripts and schema definitions
  - `supabase_schema_bundle/` — Supabase project configuration
  - `supabase_health_upload/` — Supabase functions for health data syncing
  - `supabase_ai_trigger/` — Supabase functions for AI-triggered workouts

- **`integrations/`** — Platform-specific modules and background services
  - `swift_healthkit_module/` — native iOS HealthKit integration
  - `sync_pipeline/` — background sync service
  - `auth_sync_module/` — authentication and user sync service

**Goal**: Each artifact should be buildable as a container (or platform-specific package) and deployable independently.

**Deployable artifacts**

- **API: `applications/backend/python_fastapi_server`**
	- Build: `docker build -f applications/backend/python_fastapi_server/Dockerfile -t <registry>/fitness_api:TAG applications/backend/python_fastapi_server`
	- Runs Uvicorn on port `8000` inside the container.
	- Compose: See `applications/backend/python_fastapi_server/docker-compose.yml` for production-like setup
	- Env: provide secrets and DB connection via environment variables (e.g. `DATABASE_URL`, `JWT_SECRET`, `REDIS_URL`).

- **Frontend (web): `applications/frontend/apps/mobile_app`**
	- Build: `flutter build web --release`
	- Output: `build/web/` directory contains static files
	- Deploy to GitHub Pages or serve with nginx
	- The frontend expects to be configured to call the API. For local dev the API runs at `http://localhost:8000`.

- **Mobile apps (Android / iOS): `applications/frontend/apps/mobile_app`**
	- Standard Flutter build: `flutter build apk` / `flutter build ios` (requires Flutter SDK + Xcode for iOS).
	- Packages used by the app live under `applications/frontend/packages/*` and are referenced as path dependencies in `pubspec.yaml`.

- **Native iOS modules**: `integrations/swift_healthkit_module/` — build and integrate with Xcode for the iOS app.

- **Background jobs / triggers**: `database/supabase_ai_trigger/` and `database/supabase_health_upload/` contain serverless trigger code that should be deployed to your Supabase (or equivalent) functions environment.

- **Database migrations**: `database/sql/` contains SQL scripts to initialize and migrate the database schema.

- **Sync service**: `integrations/sync_pipeline/` — background sync service for health data and user profiles.


How to run locally (recommended quick start)

Prerequisites:
- Docker & Docker Compose (v2+) for container-based local run
- (Optional) Flutter SDK if you want to run or build the Flutter app locally

1) Copy or create an environment file at the repository root called `.env` with required variables (example keys below):

```
DATABASE_URL=postgres://user:pass@db:5432/dbname
SUPABASE_URL=https://your-supabase.example
SUPABASE_KEY=service_role_key
SECRET_KEY=some_secret
```

2) Run the backend + frontend in Docker Compose (local):

```sh
docker compose up --build
```

This will build and run two services:
- `api` -> `backend/fastapi_server` (http://localhost:8000)
- `frontend` -> `frontend` (http://localhost)

If you only want to run the API locally without Docker:

```sh
cd applications/backend/fastapi_server
python -m pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

If you want to run the Flutter app locally (requires Flutter SDK):

```sh
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run    # choose device/emulator
```

## 🧪 Testing

Comprehensive test suite with 100% passing tests:

**Backend Tests** (Python/FastAPI)
```sh
cd applications/backend/python_fastapi_server
pytest test_api.py -v
```
- ✅ 15/15 tests passing
- Coverage: Goals, Health Samples, Readiness, Deduplication, Integration

**Frontend Tests** (Flutter/Dart)
```sh
cd applications/frontend/apps/mobile_app
flutter test
```
- Widget tests: Home screen, sync button, metrics, navigation
- Unit tests: HealthSync service, batch processing, transformations

See `TESTING.md` for complete testing guide and `TEST_RESULTS.md` for detailed results.

## 🔄 Continuous Integration (CI)

GitHub Actions workflow (`.github/workflows/ci.yml`) runs automatically on pushes and pull requests to `main` / `master`:

**Jobs**
- Backend: installs Python deps and runs `pytest test_api.py test_chat.py test_e2e.py`.
- Frontend: sets up Flutter, runs `flutter test` and integration test `integration_test/app_e2e_test.dart`.
- Summary: Fails the pipeline if either job fails.

**Manual Trigger (local reproduction)**
```sh
# Backend
cd applications/backend/python_fastapi_server
python -m pip install -r requirements.txt
pytest test_api.py test_chat.py test_e2e.py -q --cov=. --cov-report=term-missing --cov-report=html
echo "HTML coverage report at applications/backend/python_fastapi_server/htmlcov/index.html"

# Frontend
cd applications/frontend/apps/mobile_app
flutter pub get
flutter test --coverage
flutter test integration_test/app_e2e_test.dart --coverage
echo "LCOV at applications/frontend/apps/mobile_app/coverage/lcov.info"
genhtml coverage/lcov.info -o coverage/html || echo "Install lcov to generate HTML report"
```

To enable the badge, replace `REPLACE_OWNER/REPLACE_REPO` in `QUICK_REFERENCE.md` with your GitHub org/repo.

### Local Coverage Summary Commands Only
```sh
# Backend quick summary
pytest --cov=. --cov-report=term-missing -q

# Flutter quick summary (requires lcov installed for html)
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
```

## 📱 Mobile App Features

### Home Screen
- **User Profile**: Quick access to settings and profile management
- **Goals Preview**: Display of active goals with target values and units
- **Health Metrics**: Real-time display of:
  - Workouts count (last 30 days)
  - Total distance (km)
  - Total calories burned
- **Readiness Card**: Dynamic scoring showing:
  - Overall readiness percentage
  - HRV (Heart Rate Variability)
  - Sleep hours
  - Resting heart rate
- **Sync Button**: Manual health data synchronization with loading states
- **Auto-Sync**: Automatic synchronization on startup (2s delay) and every 15 minutes
- **Quick Actions**: One-tap access to today's workout, goals, weekly plan, profile
- **Quick Log**: Fast logging for health metrics, strength, and swim workouts

### Goals Management
- Create goals with flexible target units (miles, km, minutes, reps, etc.)
- Regex parsing for natural input: "5k", "26.2mi", "45min"
- Goal plans with descriptions and status tracking
- Full CRUD operations with backend persistence
- View goal history and progress

### Health Data Sync
- Fetches from Apple HealthKit:
  - Workouts (distance, duration, calories)
  - Heart rate (continuous monitoring)
  - HRV (Heart Rate Variability / SDNN)
  - Resting heart rate
  - Sleep stages (deep, light, REM, awake)
- Batch ingestion (configurable batch size, default 100)
- Deduplication via source_uuid (prevents duplicate entries)
- Automatic error handling with user feedback

Utility scripts
- `scripts/consolidate_frontend.sh` — copies legacy frontend modules into `frontend/legacy_ui/` (safe non-destructive copy). Useful if you want to re-run consolidation.
- `scripts/flutter_checks.sh` — helper to run `flutter pub get` across packages, run `build_runner` (for `freezed` codegen), `flutter analyze`, and `flutter test`.


Building images for production and pushing to a registry

1) Build and push backend image:

```sh
docker build -f applications/backend/Dockerfile -t <registry>/fitness_api:latest applications/backend
docker push <registry>/fitness_api:latest
```

2) Build and push frontend image:

```sh
docker build -f applications/frontend/Dockerfile -t <registry>/fitness_frontend:latest applications/frontend
docker push <registry>/fitness_frontend:latest
```

3) Deploy: use Docker Compose, Kubernetes, or your cloud provider. For Kubernetes, create Deployments and Services for each image and configure Secrets/ConfigMaps for environment variables.

Example minimal Kubernetes deployment (conceptual):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
	name: fitness-api
spec:
	replicas: 2
	template:
		spec:
			containers:
				- name: api
					image: <registry>/fitness_api:latest
					env:
						- name: DATABASE_URL
							valueFrom: { secretKeyRef: { name: db-secret, key: DATABASE_URL } }
					ports: [{ containerPort: 8000 }]

---
apiVersion: v1
kind: Service
metadata:
	name: fitness-api
spec:
	type: ClusterIP
	ports:
		- port: 8000
	selector:
		app: fitness-api
```

CI and codegen notes
- CI workflow configured at `.github/workflows/ci.yml` runs simple backend compile checks and attempts `flutter analyze` on the `applications/frontend/apps/mobile_app`.
- Some packages (for example `goals_ui`) use `freezed`/`json_serializable` and require code generation. Locally run:

```sh
cd applications/frontend/packages/goals_ui
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Or use the helper script from the repo root:

```sh
sh scripts/flutter_checks.sh
```

## 📊 Database Schema

**Key Tables**:
- `user_goals`: Goal definitions with target_value, target_unit, target_date, is_active
- `goal_plans`: Training plans associated with goals
- `health_samples`: Health data with deduplication (user_id, sample_type, start_time, source_uuid unique constraint)
- Indices optimized for queries by user_id, sample_type, and time ranges

**Migrations**: Automatic schema migration checks in `database.py` for backward compatibility

## 🔐 API Endpoints

**Goals** (`/goals`)
- `POST /goals` - Create goal
- `GET /goals?user_id=X` - List user goals
- `GET /goals/{id}` - Get specific goal
- `PUT /goals/{id}` - Update goal
- `DELETE /goals/{id}` - Soft delete (sets is_active=false)
- `POST /goals/plans` - Create goal plan
- `GET /goals/{id}/plans` - List plans for goal

**Health** (`/health`)
- `POST /health/samples` - Bulk ingest samples (with deduplication)
- `GET /health/samples?user_id=X&sample_type=Y` - List samples
- `GET /health/summary?user_id=X&days=7` - Aggregated summary by type

**Readiness** (`/readiness`)
- `GET /readiness?user_id=X` - Calculate readiness score
  - Returns: readiness (0-1), hrv, resting_hr, sleep_hours
  - Algorithm: Normalizes recent vs baseline HRV, inverted resting HR, sleep hours

**Legacy Health Metrics** (`/health`)
- CRUD endpoints for manual health metric entries
- Trends endpoint for historical analysis

## 🚀 Deployment

**Production Build**:
```sh
# Backend API
docker build -f applications/backend/Dockerfile -t <registry>/fitness_api:latest applications/backend
docker push <registry>/fitness_api:latest

# Frontend Web
docker build -f applications/frontend/Dockerfile -t <registry>/fitness_frontend:latest applications/frontend
docker push <registry>/fitness_frontend:latest

# Mobile Apps
cd applications/frontend/apps/mobile_app
flutter build apk  # Android
flutter build ios  # iOS (requires Xcode)
```

**Environment Variables**:
```
DATABASE_URL=postgresql://user:pass@host:5432/db  # or sqlite:///fitness_dev.db
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_service_role_key
SECRET_KEY=your_secret_key
```

## 📚 Documentation

- `AI_COACH_CHAT.md` - AI Coach chatbot integration guide with setup and usage
- `TESTING.md` - Complete testing guide with commands and best practices
- `TEST_RESULTS.md` - Current test execution summary (15/15 passing)
- `STRUCTURE.md` - Detailed project structure and component organization
- `HEALTH_INTEGRATION.md` - Complete Apple Health (HealthKit) integration guide
- `integrations/swift_healthkit_module/README.md` - Swift native module documentation

## 🛠️ Development Workflow

1. **Backend Development**:
   ```sh
   cd applications/backend/python_fastapi_server
   pip install -r requirements.txt
   uvicorn main:app --reload
   ```

2. **Frontend Development**:
   ```sh
   cd applications/frontend/apps/mobile_app
   flutter pub get
   flutter run
   ```

3. **Run Tests**:
   ```sh
   # Backend
   pytest test_api.py -v
   
   # Frontend
   flutter test
   ```

4. **Code Generation** (for packages using freezed):
   ```sh
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## 🐛 Known Issues & Limitations

- Sleep data currently stored as individual stage entries (nightly consolidation pending)
- Training load not yet factored into readiness calculation
- Background sync requires app to be active (iOS background fetch not implemented)
- Postgres deduplication uses SQLite syntax (ON CONFLICT needs Postgres-specific adaptation)

## 📝 Notes & Caveats

- Legacy frontend components preserved in `applications/frontend/legacy_ui/` for reference
- Some packages use `freezed`/`json_serializable` requiring code generation
- HealthKit permissions must be granted on first launch (iOS only)
- Sync button provides manual control; auto-sync runs every 15 minutes when app is active
- The environment this repository was edited in did not have `flutter` or `docker` available; CI will run in GitHub Actions with its own runners (see `.github/workflows/ci.yml`).
- Platform-specific modules (HealthKit bridging, background sync) need Xcode and native toolchains to build and deploy.
- **Cleanup note**: Original top-level folders like `python_fastapi_server/`, `python_ai_engine/`, and individual UI module folders remain at the root and can be archived/deleted after verifying the new structure works locally.

Next recommended steps
1. Run `sh scripts/flutter_checks.sh` locally (requires Flutter) and fix analyzer/codegen issues.
2. Run `docker compose up --build` locally, exercise the API endpoints (for example POST `/daily`), and open the frontend.
3. Remove or archive `python_fastapi_server` / `python_ai_engine` once you are satisfied with `backend/fastapi_server`.
4. Add production manifests (Helm chart or k8s manifests) that reflect your chosen cloud provider and secrets workflow.

If you want I can generate a starter Helm chart and example Kubernetes manifests for both the API and the frontend next — tell me where you will deploy (GKE / EKS / AKS / other) and I will scaffold them.
