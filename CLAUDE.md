# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter application** for the Workout Planner - an AI-powered fitness coaching platform. The backend API is in a separate [services repository](https://github.com/rummel-tech/services/tree/main/workout-planner).

## Quick Start - Local Development

**Use the dev script for all local development tasks:**

```bash
# Check service status
./dev.sh status

# After code changes (hot reload - fastest)
./dev.sh hot-reload

# Full restart if needed
./dev.sh hot-restart

# View logs
./dev.sh logs

# Run tests
./dev.sh test-all

# See all commands
./dev.sh help
```

**See [DEV_QUICK_START.md](./DEV_QUICK_START.md) for complete guide.**

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome                    # Web
flutter run                              # Connected device/emulator
flutter run -d macos                     # Desktop

# Run with production backend
flutter run -d chrome --dart-define=PRODUCTION_API_URL=http://<AWS_IP>:8000

# Testing
flutter test                             # Unit tests
flutter test --coverage                  # With coverage

# Build for production
flutter build web --release
flutter build apk --release
flutter build ios --release
```

## Code Structure

```
workout-planner/
├── lib/                         # Main application code
│   ├── main.dart                # App entry point, navigation
│   ├── config/
│   │   └── env_config.dart      # API URL configuration
│   └── services/                # API clients
├── packages/                    # Reusable UI packages
│   ├── goals_ui/                # Goal setting screens
│   ├── home_dashboard_ui/       # Home screen, login, auth
│   ├── readiness_ui/            # Readiness score display
│   ├── todays_workout_ui/       # Daily workout view
│   ├── weekly_plan_ui/          # Weekly plan calendar
│   ├── ai_insights_ui/          # AI recommendations
│   ├── ai_coach_chat/           # Chat interface
│   ├── settings_profile_ui/     # User settings
│   └── health_integration/      # HealthKit/Google Fit
├── test/                        # Unit tests
├── integration_test/            # Integration tests
├── ios/                         # iOS platform
├── linux/                       # Linux platform
├── web/                         # Web platform
├── docs/                        # Flutter-specific documentation
├── pubspec.yaml                 # Dependencies
└── analysis_options.yaml        # Dart analysis rules
```

## API Configuration

The app reads API URL from environment variables. See `lib/config/env_config.dart`:

**Priority:**
1. `API_BASE_URL` - Direct override
2. `PRODUCTION_API_URL` - Production URL
3. Platform-specific: `WEB_API_URL`, `ANDROID_API_URL`, `IOS_API_URL`
4. Default: `http://localhost:8000`

**Build examples:**
```bash
flutter run -d chrome                                                    # localhost
flutter build web --dart-define=PRODUCTION_API_URL=http://<IP>:8000     # production
```

## Package Architecture

Each feature is a separate package in `packages/`. Packages reference each other by path:

```yaml
dependencies:
  goals_ui:
    path: packages/goals_ui
```

**Working with packages:**
```bash
cd packages/goals_ui
# make changes
flutter pub get

cd ../..
flutter pub get  # update main app
```

## Common Workflows

### Adding a New Screen

1. Create package in `packages/`
2. Add `pubspec.yaml`
3. Create screen in `lib/screens/`
4. Export from `lib/<package>.dart`
5. Add to `pubspec.yaml`
6. Add to navigation in `lib/main.dart`

### Updating API Calls

Services are in each package (e.g., `packages/home_dashboard_ui/lib/services/auth_service.dart`). They use `http` package and accept `baseUrl` parameter.

## Key Files

- `lib/main.dart` - App entry, navigation
- `lib/config/env_config.dart` - API URL config
- `packages/home_dashboard_ui/lib/services/auth_service.dart` - Authentication
- `packages/goals_ui/lib/services/goals_api_service.dart` - Goals API
- `pubspec.yaml` - Dependencies

## Backend

Backend API is in a separate repository at `/home/shawn/APP_DEV/services/workout-planner/`. To run locally:

```bash
cd /home/shawn/APP_DEV/services/workout-planner
source .venv/bin/activate
uvicorn main:app --reload --port 8000
```

Key endpoints: `/auth/login`, `/auth/register`, `/goals`, `/daily-plans`, `/weekly-plans`, `/chat/messages`, `/health/summary`, `/readiness`

## Deployment

Frontend deploys to GitHub Pages via infrastructure repo:

```bash
gh workflow run deploy-workout-planner-frontend.yml --repo rummel-tech/infrastructure
```
