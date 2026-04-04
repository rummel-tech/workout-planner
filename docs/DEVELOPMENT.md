# Development Guide

## Quick Start

```bash
./dev.sh status      # check everything is running
./dev.sh hot-reload  # apply code changes (~2s)
./dev.sh logs        # view live output
```

Backend: `http://localhost:8000` | API docs: `http://localhost:8000/docs`
Frontend: `http://localhost:8080`

---

## Prerequisites

- Flutter SDK ≥ 3.0
- Python 3.11+
- Backend running from `~/_Projects/services/workout-planner`

---

## Running Locally

### Backend

```bash
cd ~/_Projects/services/workout-planner
source .venv/bin/activate
uvicorn main:app --reload --port 8000
```

### Frontend

```bash
flutter pub get
flutter run -d chrome          # web
flutter run                    # connected device/emulator
flutter run -d macos           # desktop
flutter run -d chrome --dart-define=PRODUCTION_API_URL=http://<AWS_IP>:8000
```

### Environment

```bash
cp .env.example .env   # then edit values — never commit .env
```

---

## Dev Script Reference

| Command | Shortcut | What it does |
|---------|----------|--------------|
| `./dev.sh status` | `st` | Health check all services |
| `./dev.sh hot-reload` | `r` | Apply Dart changes (~2s) |
| `./dev.sh hot-restart` | | Full Flutter restart (~10s) |
| `./dev.sh start-all` | | Start frontend + backend |
| `./dev.sh stop-all` | | Stop all services |
| `./dev.sh logs` | `l` | Tail all logs |
| `./dev.sh test-all` | | Run all tests |
| `./dev.sh help` | | Full command list |

Log files: `/tmp/flutter-workout.log`, `/tmp/workout-planner.log`

---

## Project Structure

```
workout-planner/             ← monorepo root: ~/_Projects/workout-planner
├── lib/
│   ├── main.dart                  # App entry, routing
│   └── config/env_config.dart     # API URL resolution
├── packages/                      # Feature packages
│   ├── goals_ui/
│   ├── home_dashboard_ui/         # Auth lives here
│   ├── readiness_ui/
│   ├── todays_workout_ui/
│   ├── weekly_plan_ui/
│   ├── ai_insights_ui/
│   ├── ai_coach_chat/
│   ├── settings_profile_ui/
│   └── health_integration/
├── test/
├── integration_test/
├── docs/                          # All documentation here
├── dev.sh
└── pubspec.yaml
```

---

## iOS Signed Builds & CI

**Required GitHub Secrets:**
- `P12_BASE64` — base64 of your `.p12` certificate
- `P12_PASSWORD` — certificate export password
- `MOBILEPROVISION_BASE64` — base64 of provisioning profile
- `KEYCHAIN_PASSWORD` — any random string for ephemeral CI keychain

**Optional (TestFlight):** `APP_STORE_CONNECT_API_KEY`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_ID`

```bash
base64 -i your_cert.p12 | pbcopy
base64 -i your_profile.mobileprovision | pbcopy
# Add to: GitHub → Settings → Secrets and variables → Actions
```

Trigger: GitHub → Actions → "iOS Signed Build" → Run workflow.

---

## Deployment

```bash
gh workflow run deploy-workout-planner-frontend.yml --repo <your-org>/infrastructure
gh workflow run deploy-workout-planner-backend.yml  --repo <your-org>/infrastructure
```

- Frontend: `https://rummel-tech.github.io/workout-planner/`
- Backend: `https://api.rummeltech.com/workout-planner`

---

## Testing

```bash
./dev.sh test-all          # everything
flutter test               # unit tests
flutter test --coverage    # with coverage
pytest                     # backend (run from ~/_Projects/services/workout-planner)
```
