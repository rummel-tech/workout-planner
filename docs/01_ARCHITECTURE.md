# Workout Planner - System Architecture

**Version:** 1.0
**Last Updated:** 2024-12-24

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐ │
│  │   iOS   │  │ Android │  │   Web   │  │  macOS  │  │ Linux  │ │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └───┬────┘ │
│       └────────────┴───────────┴───────────┴─────────────┘      │
│                              │                                   │
│                    Flutter Application                           │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │ HTTPS
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        API LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                      FastAPI Application                         │
│                              │                                   │
│  ┌──────────┐  ┌──────────┐  │  ┌──────────┐  ┌──────────┐      │
│  │   Auth   │  │  Goals   │  │  │  Health  │  │   Chat   │      │
│  │  Router  │  │  Router  │  │  │  Router  │  │  Router  │      │
│  └────┬─────┘  └────┬─────┘  │  └────┬─────┘  └────┬─────┘      │
│       └─────────────┴────────┴───────┴─────────────┘             │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│    PostgreSQL    │  │      Redis       │  │   AI Providers   │
│    (Database)    │  │     (Cache)      │  │ (OpenAI/Claude)  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

## Frontend Architecture

### Package Structure

The Flutter app uses a modular package architecture where each feature is isolated into its own package:

```
workout-planner/
├── lib/
│   ├── main.dart                    # App entry, routing, theme
│   ├── config/
│   │   └── env_config.dart          # API URL configuration
│   └── services/                    # Shared services
│
├── packages/
│   ├── home_dashboard_ui/           # Core package
│   │   ├── lib/
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   ├── welcome_screen.dart
│   │   │   │   ├── setup_wizard_screen.dart
│   │   │   │   └── day_edit_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── auth_service.dart
│   │   │   │   ├── health_sync.dart
│   │   │   │   ├── readiness_service.dart
│   │   │   │   └── secure_config_service.dart
│   │   │   └── widgets/
│   │   └── pubspec.yaml
│   │
│   ├── goals_ui/                    # Goal management
│   │   ├── lib/
│   │   │   ├── screens/
│   │   │   │   ├── goals_screen.dart
│   │   │   │   └── goal_plans_screen.dart
│   │   │   └── services/
│   │   │       └── goals_api_service.dart
│   │   └── pubspec.yaml
│   │
│   ├── weekly_plan_ui/              # Weekly planning
│   ├── todays_workout_ui/           # Quick logging
│   ├── ai_coach_chat/               # AI chat interface
│   ├── ai_insights_ui/              # AI insights display
│   ├── readiness_ui/                # Readiness components
│   ├── settings_profile_ui/         # Profile settings
│   ├── health_integration/          # HealthKit bridge
│   ├── notification_system/         # Push notifications
│   └── widgets/                     # Shared UI components
│
└── test/                            # Unit tests
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Screen    │    │   Screen    │    │   Screen    │     │
│  │  (Stateful) │    │  (Stateful) │    │  (Stateful) │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Service Layer                      │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │   │
│  │  │AuthService │  │GoalsService│  │HealthSync  │     │   │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘     │   │
│  └────────┼───────────────┼───────────────┼─────────────┘   │
│           │               │               │                 │
└───────────┼───────────────┼───────────────┼─────────────────┘
            │               │               │
            ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────┐
│                      HTTP Layer                              │
│                   (REST API Calls)                          │
└─────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend API                               │
└─────────────────────────────────────────────────────────────┘
```

### State Management

The app uses a simple state management approach:

| Pattern | Usage |
|---------|-------|
| StatefulWidget | Screen-level state with `setState()` |
| Service Classes | Business logic and API communication |
| Callbacks | Parent-child component communication |
| SharedPreferences | Persistent user preferences |
| flutter_secure_storage | Encrypted token/key storage |

## Backend Architecture

### Router Structure

```
main.py (FastAPI App)
│
├── Middleware Stack
│   ├── Security Headers
│   ├── Request Logging
│   ├── CORS
│   └── Rate Limiting
│
├── Core Endpoints
│   ├── GET  /           → API info
│   ├── GET  /health     → Liveness probe
│   ├── GET  /ready      → Readiness probe (DB + Redis)
│   └── GET  /metrics    → Prometheus metrics
│
└── Routers
    ├── /auth          → routers/auth.py
    │   ├── POST /register
    │   ├── POST /login
    │   ├── POST /refresh
    │   ├── POST /logout
    │   ├── GET  /me
    │   └── POST /validate-code
    │
    ├── /goals         → routers/goals.py
    │   ├── GET  /
    │   ├── POST /
    │   ├── GET  /{id}
    │   ├── PUT  /{id}
    │   ├── DELETE /{id}
    │   └── GET  /{id}/plans
    │
    ├── /health        → routers/health.py
    │   ├── POST /samples
    │   ├── GET  /samples
    │   ├── GET  /summary
    │   ├── GET  /metrics
    │   └── GET  /trends
    │
    ├── /readiness     → routers/readiness.py
    │   └── GET  /
    │
    ├── /daily-plans   → routers/daily_plans.py
    │   ├── GET  /{user_id}/{date}
    │   ├── PUT  /{user_id}/{date}
    │   └── DELETE /{user_id}/{date}
    │
    ├── /weekly-plans  → routers/weekly_plans.py
    │   ├── GET  /{user_id}
    │   ├── PUT  /{user_id}
    │   └── DELETE /{user_id}
    │
    ├── /chat          → routers/chat.py
    │   ├── POST /sessions
    │   ├── GET  /sessions
    │   ├── POST /messages
    │   └── GET  /messages/{session_id}
    │
    ├── /workouts      → routers/workouts.py
    ├── /strength      → routers/strength.py
    ├── /swim          → routers/swim.py
    ├── /murph         → routers/murph.py
    ├── /meals         → routers/meals.py
    └── /waitlist      → routers/waitlist.py
```

### Service Layer

```
┌─────────────────────────────────────────────────────────────┐
│                      API Routers                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ auth_service │  │ai_chat_svc   │  │ ai_engine    │       │
│  │              │  │              │  │              │       │
│  │ • login      │  │ • get_resp   │  │ • daily_plan │       │
│  │ • register   │  │ • context    │  │ • weekly_plan│       │
│  │ • tokens     │  │ • sessions   │  │ • readiness  │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │                │
└─────────┼─────────────────┼─────────────────┼────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  database.py │  │ redis_client │  │    cache     │       │
│  │              │  │              │  │              │       │
│  │ • get_conn   │  │ • blacklist  │  │ • decorator  │       │
│  │ • execute    │  │ • get/set    │  │ • invalidate │       │
│  │ • fetch      │  │ • client     │  │ • stats      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
          │                 │
          ▼                 ▼
┌──────────────────┐  ┌──────────────────┐
│   PostgreSQL /   │  │      Redis       │
│     SQLite       │  │                  │
└──────────────────┘  └──────────────────┘
```

### Caching Strategy

```
Request → Check Cache → [HIT] → Return Cached Response
              │
              └─[MISS]→ Execute Function → Store in Cache → Return

Cached Endpoints:
├── /health/summary    → TTL: 5 minutes
├── /health/trends     → TTL: 10 minutes
└── /readiness         → TTL: 5 minutes

Invalidation Triggers:
├── Health data ingestion → Invalidate user's health cache
├── Manual invalidation   → Pattern-based key deletion
└── TTL expiration        → Automatic
```

## Deployment Architecture

### Development

```
┌──────────────────┐     ┌──────────────────┐
│  Flutter App     │────▶│  FastAPI         │
│  (localhost)     │     │  (localhost:8000)│
└──────────────────┘     └────────┬─────────┘
                                  │
                         ┌────────┴────────┐
                         ▼                 ▼
                 ┌──────────────┐  ┌──────────────┐
                 │   SQLite     │  │ Redis (opt)  │
                 │ fitness.db   │  │ localhost    │
                 └──────────────┘  └──────────────┘
```

### Production

```
┌──────────────────┐
│   CDN / S3       │◀── Flutter Web Build
│  (Static Host)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│   Load Balancer  │────▶│   ECS Fargate    │
│   (ALB)          │     │   (API Cluster)  │
└──────────────────┘     └────────┬─────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
            ┌──────────────┐ ┌──────────┐ ┌──────────────┐
            │  RDS         │ │ElastiCache│ │ Secrets Mgr  │
            │ PostgreSQL   │ │  Redis   │ │              │
            └──────────────┘ └──────────┘ └──────────────┘
```

## Key Design Decisions

### Frontend

| Decision | Rationale |
|----------|-----------|
| Package-based architecture | Feature isolation, independent development |
| StatefulWidget over Bloc/Riverpod | Simplicity for current scale |
| flutter_secure_storage | Platform-native encryption for tokens |
| Service layer pattern | Separation of UI and business logic |

### Backend

| Decision | Rationale |
|----------|-----------|
| FastAPI | Modern Python, async support, auto-docs |
| SQLite for dev | Zero-config local development |
| PostgreSQL for prod | ACID compliance, scalability |
| Redis caching | Reduce DB load, faster responses |
| JWT with blacklist | Stateless auth with logout support |
| Router-based organization | Clean separation of concerns |

## Error Handling

### Frontend

```
API Call → Success → Update UI State
    │
    └── Failure → Check Error Type
                    │
                    ├── Connection Error → Show "Check connection" message
                    ├── 401 Unauthorized → Trigger logout, redirect to login
                    ├── 4xx Client Error → Show error message
                    └── 5xx Server Error → Show "Try again" message
```

### Backend

```
Request → Validation → Business Logic → Response
    │         │              │
    │         │              └── Exception → Error Handler
    │         │                                   │
    │         └── ValidationError → 422           │
    │                                             │
    └── Auth Failure → 401                        │
                                                  ▼
                                    ┌─────────────────────────┐
                                    │ Structured Error Response│
                                    │ {                        │
                                    │   "detail": "...",       │
                                    │   "error_code": "...",   │
                                    │   "request_id": "..."    │
                                    │ }                        │
                                    └─────────────────────────┘
```

## Monitoring & Observability

| Component | Tool | Endpoint |
|-----------|------|----------|
| Health Check | Built-in | `/health` |
| Readiness Probe | Built-in | `/ready` |
| Metrics | Prometheus | `/metrics` |
| Cache Stats | Built-in | `/cache/stats` |
| Request Logging | Structured JSON | Stdout |
| Correlation IDs | X-Request-ID header | All requests |
