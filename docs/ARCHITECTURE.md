# Workout Planner — Architecture

This is the top-level architecture summary. The workout-planner has extensive detailed documentation in this directory:

- [Full Architecture](01_ARCHITECTURE.md) — complete system design
- [Data Models](02_DATA_MODELS.md) — all entities and relationships
- [API Specification](03_API_SPECIFICATION.md) — all endpoints
- [UI Specification](04_UI_SPECIFICATION.md) — screens and navigation
- [Security](05_SECURITY.md) — auth, encryption, compliance
- [Integrations](06_INTEGRATIONS.md) — HealthKit, AI, cross-module

## Summary

The workout-planner is a Flutter/FastAPI full-stack app for AI-powered fitness coaching.

```
workout-planner/ (Flutter app)
        │
        ▼
services/workout-planner/ (FastAPI :8000)
        │
        ├── PostgreSQL (prod) / SQLite (dev)
        ├── OpenAI GPT-4 (AI coaching)
        └── HealthKit (iOS/macOS — Apple Health data)
```

**Frontend** (`workout-planner/`): Flutter 3.x, cross-platform (iOS, Android, Web, macOS). Feature packages in `packages/`. HealthKit integration in `packages/health_integration/`.

**Backend** (`services/workout-planner/`): FastAPI, SQLAlchemy, dual-mode DB. 15 test files, Alembic migrations. Port 8000.

**Artemis integration**: Implements the Artemis Module Contract — exposes `/artemis/manifest`, `/artemis/widget`, and agent tool endpoints. Dual-mode `require_token` accepts standalone HS256 or Artemis RS256 JWTs.

## Key Design Decisions

- Offline-first: local state cached, synced on reconnect
- Dual-mode auth: works standalone or as Artemis module
- HealthKit is best-effort (iOS/macOS only, permission-gated)
- AI coach uses streaming responses via SSE
- Cross-module: provides `calories_burned` to meal-planner (non-blocking)

See [01_ARCHITECTURE.md](01_ARCHITECTURE.md) for full detail.
