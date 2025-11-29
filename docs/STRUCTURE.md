# Repository Structure

This repository is organized into **3 top-level categories** for clean separation of concerns:

## `applications/`

Deployable applications and their supporting code.

```
applications/
├── backend/
│   ├── fastapi_server/          # FastAPI web service
│   │   ├── ai_engine/           # AI models (readiness, daily plan, etc.)
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── ...
│   ├── python_fastapi_server/   # Legacy original FastAPI (for reference)
│   ├── python_ai_engine/        # Legacy original AI engine (for reference)
│   ├── backend_integration_layer/
│   ├── Dockerfile               # Multi-stage build for FastAPI
│   └── ...
├── frontend/
│   ├── apps/
│   │   └── mobile_app/          # Flutter mobile app (Android/iOS/Web)
│   │       ├── lib/main.dart
│   │       ├── pubspec.yaml
│   │       └── ...
│   ├── packages/                # Reusable Dart packages
│   │   ├── app_theme/           # Theme & typography
│   │   ├── navigation/          # Navigation drawer & router
│   │   ├── widgets/             # Shared widgets
│   │   ├── goals_ui/
│   │   ├── readiness_ui/
│   │   ├── home_dashboard_ui/
│   │   ├── notification_system/
│   │   ├── settings_profile_ui/
│   │   ├── todays_workout_ui/
│   │   ├── weekly_plan_ui/
│   │   └── ai_insights_ui/
│   ├── lib/                     # Shared lib utilities
│   ├── Dockerfile               # Multi-stage build for Flutter web + Nginx
│   └── ...
```

## `database/`

Database schemas, migrations, and serverless functions.

```
database/
├── sql/                         # SQL migration scripts & schema definitions
├── supabase_schema_bundle/      # Supabase project configuration & schema
├── supabase_health_upload/      # Supabase functions for health data syncing
├── supabase_ai_trigger/         # Supabase functions for AI-triggered recommendations
└── ...
```

## `integrations/`

Platform-specific native modules.

```
integrations/
└── swift_healthkit_module/      # Native iOS HealthKit integration
    ├── HealthKitManager.swift
    ├── HealthDataSerializer.swift
    ├── FlutterBridge.swift
    └── README.md
```

See [integrations/swift_healthkit_module/README.md](../integrations/swift_healthkit_module/README.md) for HealthKit integration details.

## Root-level files

- `.github/workflows/ci.yml` — GitHub Actions CI workflow
- `scripts/` — Helper scripts
  - `consolidate_frontend.sh` — Consolidate legacy UI modules (POSIX-safe)
  - `flutter_checks.sh` — Run Flutter pub get, codegen, analyze, tests
- `docker-compose.local.yml` — Local PostgreSQL database for development
- `README.md` — Main documentation
- `design.mmd` — Design diagrams (Mermaid)

---

## Key Takeaways

- **3 folders = 3 concerns**: Applications (code to deploy), Database (schemas & triggers), Integrations (platform-specific)
- **No duplicates**: Legacy/original modules are kept in `applications/frontend/legacy_ui/` for reference, not duplicated.
- **Independent deployment**: Each artifact can be built and deployed separately.
- **Clear paths**: All Docker, CI, and script references point to the organized structure.
