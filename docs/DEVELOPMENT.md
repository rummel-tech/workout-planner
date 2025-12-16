# Development Guide

This document covers development setup, building, testing, and deployment for the Workout Planner application.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run in development (connects to localhost:8000 by default)
flutter run -d chrome

# Run with production backend
flutter run -d chrome --dart-define=PRODUCTION_API_URL=http://<AWS_IP>:8000
```

## Project Structure

```
workout-planner/
├── lib/                         # Main application code
│   ├── main.dart                # App entry point
│   ├── config/                  # Environment configuration
│   └── services/                # API clients
├── packages/                    # Reusable UI packages
│   ├── goals_ui/                # Goal setting screens
│   ├── home_dashboard_ui/       # Home screen, auth
│   ├── readiness_ui/            # Readiness score display
│   ├── todays_workout_ui/       # Daily workout view
│   ├── weekly_plan_ui/          # Weekly plan calendar
│   ├── ai_insights_ui/          # AI recommendations
│   ├── ai_coach_chat/           # Chat interface
│   ├── settings_profile_ui/     # User settings
│   └── health_integration/      # HealthKit/Google Fit
├── test/                        # Unit tests
├── integration_test/            # Integration tests
├── ios/                         # iOS platform files
├── web/                         # Web platform files
├── linux/                       # Linux platform files
├── resources/                   # Shared design assets (submodule)
├── docs/                        # Documentation
└── pubspec.yaml                 # Flutter dependencies
```

## Backend API

The backend is deployed to AWS ECS via the [services repository](https://github.com/rummel-tech/services).

**API Endpoints:**
- Production: `http://<ECS_PUBLIC_IP>:8000`
- Development: `http://localhost:8000` (run backend locally from services repo)

**Configuring API URL:**

```bash
# Development (default - localhost)
flutter run -d chrome

# Production build with AWS backend
flutter build web --dart-define=PRODUCTION_API_URL=http://<AWS_IP>:8000
```

See `.env.example` for all configuration options.

## Running Tests

```bash
flutter test
```

## Working with Packages

Each UI feature is a separate package for modularity:

```bash
# Update a package
cd packages/goals_ui
flutter pub get

# Then update the main app
cd ../..
flutter pub get
```

## Building for Production

```bash
# Web (deployed to GitHub Pages)
flutter build web --release

# Android
flutter build apk --release

# iOS (requires Xcode)
flutter build ios --release
```

## Deployment

### Production Checklist

Before deploying to production, complete the checklist in [`RELEASE_CHECKLIST.md`](../RELEASE_CHECKLIST.md). This includes:

- Backend endpoint implementation (OAuth, password reset)
- Platform-specific configuration (iOS, Android, Web)
- Security review and compliance
- App store submission preparation

See [`PRODUCTION_DEPLOYMENT.md`](../PRODUCTION_DEPLOYMENT.md) for detailed deployment procedures.

**Production URL:** https://rummel-tech.github.io/workout-planner/

## Related Repositories

- **[services](https://github.com/rummel-tech/services)** - Backend API (FastAPI)
- **[infrastructure](https://github.com/rummel-tech/infrastructure)** - CI/CD workflows
- **[resources](https://github.com/rummel-tech/resources)** - Shared design assets
- **[documentation](https://github.com/rummel-tech/documentation)** - Platform documentation
