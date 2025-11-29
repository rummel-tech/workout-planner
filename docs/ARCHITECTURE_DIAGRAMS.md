# Fitness Agent - Architecture Diagrams

## 1. System Overview Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        END USERS / CLIENTS                                 │
├─────────────┬──────────────────┬─────────────┬──────────────────┬─────────┤
│   Mobile    │   Web Browser    │  iOS Health │  External APIs   │ Admin   │
│   User      │   Dashboard      │  Platform   │  (3rd Party)     │ Portal  │
└─────────────┴──────────────────┴─────────────┴──────────────────┴─────────┘
              │                        │                │              │
              └────────────┬───────────┴────────────────┴──────────────┘
                           │
              ┌────────────▼────────────────┐
              │    API Gateway / CDN        │
              │  (CloudFront/nginx)         │
              │  SSL/TLS Termination        │
              │  Rate Limiting              │
              │  Load Balancing             │
              └────────────┬────────────────┘
                           │
          ┌────────────────┼───────────────┐
          │                │               │
    ┌─────▼─────┐    ┌──────▼────┐   ┌──────▼──────┐
    │ Frontend   │    │  Backend  │   │ Integrations│
    │ Service    │    │  API      │   │ & Services  │
    │            │    │  (FastAPI)│   │             │
    │ • Nginx    │    │           │   │ • HealthKit │
    │ • Static   │    │ • Auth    │   │ • Sync      │
    │   Content  │    │ • Workouts│   │ • Push Notif│
    │            │    │ • AI/ML   │   │ • Email     │
    └────────────┘    │ • Readiness│   └─────────────┘
                      │ • Goals   │
                      └──────┬────┘
                             │
                    ┌────────▼────────┐
                    │  Supabase / AWS │
                    │   (Data Layer)   │
                    │                  │
                    │ • PostgreSQL DB  │
                    │ • Auth Service   │
                    │ • Real-time Subs │
                    │ • Storage        │
                    │ • Edge Functions │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼────┐      ┌─────▼────┐      ┌─────▼─────┐
    │Background │      │ Logging &│      │ Monitoring│
    │ Services  │      │Analytics │      │ & Alerts  │
    │           │      │          │      │           │
    │ • Sync    │      │ • Logs   │      │ • Metrics │
    │ • Cron    │      │ • Events │      │ • Traces  │
    │ • Queue   │      │ • Traces │      │ • Dashbrd │
    │ • Jobs    │      │          │      │           │
    └───────────┘      └──────────┘      └───────────┘
```

---

## 2. Frontend Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    FLUTTER FRONTEND LAYER                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │         PRESENTATION LAYER (UI/Screens)            │    │
│  ├──────────┬──────────┬──────────┬──────────┬────────┤    │
│  │  Home    │  Goals   │ Readiness│ Workouts │Settings│    │
│  │ Dashboard│ Screen   │ Screen   │ Screen   │Screen  │    │
│  └────┬─────┴────┬─────┴────┬─────┴────┬─────┴────┬───┘    │
│       │          │          │          │          │         │
│  ┌────▼──────────▼──────────▼──────────▼──────────▼──┐     │
│  │       BUSINESS LOGIC LAYER (Services)            │     │
│  ├──────────┬──────────┬──────────┬────────────────┤     │
│  │ Auth     │ Workout  │ Readiness│ Sync Service  │     │
│  │ Service  │ Service  │ Service  │               │     │
│  └────┬─────┴────┬─────┴────┬─────┴────┬──────────┘     │
│       │          │          │          │                 │
│  ┌────▼──────────▼──────────▼──────────▼──┐             │
│  │   NETWORK LAYER (API Communication)   │             │
│  │  • HTTP/REST Client                   │             │
│  │  • WebSocket for Real-time Updates    │             │
│  │  • GraphQL (optional)                 │             │
│  └────┬─────────────────────────────────┘             │
│       │                                                 │
│  ┌────▼──────────────────────────────┐                │
│  │ LOCAL STORAGE / CACHE             │                │
│  │ • SQLite (Offline Data)           │                │
│  │ • Shared Preferences (Settings)   │                │
│  │ • Image Cache                     │                │
│  └───────────────────────────────────┘                │
│                                                        │
└────────────────────────────────────────────────────────┘

PACKAGES STRUCTURE:
├── app_theme/
│   ├── screens/
│   └── ui_components/
│       ├── app_theme.dart
│       ├── brand_colors.dart
│       └── typography.dart
├── goals_ui/
│   ├── screens/
│   │   └── goals_screen.dart
│   └── ui_components/
│       ├── goal_tile.dart
│       └── goal_model.dart
├── home_dashboard_ui/
│   ├── screens/
│   │   └── home_screen.dart
│   └── ui_components/
│       ├── readiness_card.dart
│       ├── todays_workout_preview.dart
│       └── weekly_plan_preview.dart
├── readiness_ui/
│   └── ui_components/
│       └── readiness_card.dart
├── settings_profile_ui/
│   ├── screens/
│   │   └── profile_screen.dart
│   └── ui_components/
│       └── settings_tile.dart
├── todays_workout_ui/
│   └── screens/
│       └── todays_workout_screen.dart
├── weekly_plan_ui/
│   └── screens/
│       └── weekly_plan_screen.dart
├── ai_insights_ui/
│   ├── screens/
│   │   └── ai_insights_screen.dart
│   └── ui_components/
│       └── insight_card.dart
├── notification_system/
│   └── ui_components/
│       └── notification_service.dart
└── widgets/
    └── ui_components/
        └── placeholder_card.dart
```

---

## 3. Backend Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   FASTAPI BACKEND SERVICE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           API LAYER (REST Endpoints)                   │   │
│  ├────────┬────────┬──────────┬────────┬────────┬────────┤   │
│  │ /auth  │/users  │ /workouts│/goals  │/readins│/insights│   │
│  │        │        │          │        │ess    │        │   │
│  └────┬───┴────┬───┴────┬─────┴───┬────┴──┬───┴────┬────┘   │
│       │        │        │         │       │        │         │
│  ┌────▼────────▼────────▼─────────▼───────▼────────▼──┐     │
│  │      SERVICE LAYER (Business Logic)               │     │
│  ├──────────┬──────────┬──────────┬─────────────────┤     │
│  │ Auth     │ Workout  │ Readiness│ AI/ML Service   │     │
│  │ Service  │ Service  │ Service  │                 │     │
│  │          │          │          │ • Models        │     │
│  │ • JWT    │ • CRUD   │ • Calc   │ • Inference     │     │
│  │ • OAuth  │ • Sync   │ • Trends │ • Predictions   │     │
│  │ • MFA    │          │          │                 │     │
│  └────┬─────┴────┬─────┴────┬─────┴────────┬────────┘     │
│       │          │          │             │               │
│  ┌────▼──────────▼──────────▼─────────────▼──┐            │
│  │      MIDDLEWARE & UTILITIES               │            │
│  │ • Authentication (JWT)                   │            │
│  │ • Authorization (RBAC)                   │            │
│  │ • Rate Limiting                          │            │
│  │ • Error Handling                         │            │
│  │ • Logging                                │            │
│  │ • Validation (Pydantic)                  │            │
│  └────┬─────────────────────────────────────┘            │
│       │                                                   │
│  ┌────▼──────────────────────────────────┐              │
│  │   DATA ACCESS LAYER (ORM/Queries)     │              │
│  │   • SQLAlchemy ORM                    │              │
│  │   • Database Connections              │              │
│  │   • Connection Pooling                │              │
│  │   • Migrations (Alembic)              │              │
│  └────┬───────────────────────────────────┘              │
│       │                                                   │
│  ┌────▼──────────────────────────────────┐              │
│  │      EXTERNAL INTEGRATIONS            │              │
│  │ • Supabase SDK                        │              │
│  │ • Health Platform APIs                │              │
│  │ • Email Service (SendGrid/SES)        │              │
│  │ • Push Notification Service           │              │
│  │ • Analytics Service                   │              │
│  └────────────────────────────────────────┘              │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 4. Database Schema & Architecture

```
┌──────────────────────────────────────────────────────────────┐
│               POSTGRESQL DATABASE SCHEMA                      │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐                                        │
│  │     USERS        │                                        │
│  ├──────────────────┤                                        │
│  │ • id (PK)        │                                        │
│  │ • email          │                                        │
│  │ • username       │                                        │
│  │ • password_hash  │                                        │
│  │ • created_at     │                                        │
│  │ • updated_at     │                                        │
│  │ • profile_pic    │                                        │
│  │ • bio            │                                        │
│  └────────┬─────────┘                                        │
│           │1                                                 │
│           │ N                                                │
│  ┌────────▼─────────────────┐   ┌─────────────────────────┐ │
│  │   USER_PROFILES          │   │  WORKOUTS               │ │
│  ├──────────────────────────┤   ├─────────────────────────┤ │
│  │ • id (PK)                │   │ • id (PK)               │ │
│  │ • user_id (FK)           │   │ • user_id (FK)          │ │
│  │ • age                    │   │ • type (strength, cardio│ │
│  │ • height                 │   │ • duration_minutes      │ │
│  │ • weight                 │   │ • intensity (1-5)       │ │
│  │ • fitness_level          │   │ • calories_burned       │ │
│  │ • preferences            │   │ • notes                 │ │
│  └──────────────────────────┘   │ • completed_at          │ │
│                                  │ • created_at            │ │
│                                  └────────┬────────────────┘ │
│                                           │1                  │
│  ┌──────────────────────────┐           N │                  │
│  │   HEALTH_METRICS         │  ┌─────────▼──────────────┐   │
│  ├──────────────────────────┤  │ WORKOUT_EXERCISES      │   │
│  │ • id (PK)                │  ├────────────────────────┤   │
│  │ • user_id (FK)           │  │ • id (PK)              │   │
│  │ • heart_rate             │  │ • workout_id (FK)      │   │
│  │ • sleep_hours            │  │ • exercise_name        │   │
│  │ • hrv                    │  │ • sets                 │   │
│  │ • resting_heart_rate     │  │ • reps                 │   │
│  │ • recovery_level         │  │ • weight_lbs           │   │
│  │ • steps                  │  │ • duration_seconds     │   │
│  │ • measured_at            │  └────────────────────────┘   │
│  │ • created_at             │                                │
│  └──────────────────────────┘   ┌────────────────────────┐   │
│                                  │      GOALS             │   │
│  ┌──────────────────────────┐   ├────────────────────────┤   │
│  │   AI_INSIGHTS            │   │ • id (PK)              │   │
│  ├──────────────────────────┤   │ • user_id (FK)         │   │
│  │ • id (PK)                │   │ • goal_type            │   │
│  │ • user_id (FK)           │   │ • target_value         │   │
│  │ • insight_type           │   │ • current_value        │   │
│  │ • title                  │   │ • target_date          │   │
│  │ • detail                 │   │ • status (active/done) │   │
│  │ • recommendation         │   │ • progress_pct         │   │
│  │ • generated_at           │   │ • created_at           │   │
│  │ • expires_at             │   │ • updated_at           │   │
│  └──────────────────────────┘   └────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         DATABASE INDEXES & CONSTRAINTS               │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ • users.email (UNIQUE)                              │   │
│  │ • workouts.user_id, completed_at (COMPOSITE)        │   │
│  │ • health_metrics.user_id, measured_at (COMPOSITE)   │   │
│  │ • ai_insights.user_id, expires_at (COMPOSITE)       │   │
│  │ • goals.user_id, target_date (COMPOSITE)            │   │
│  │ • Foreign Key Constraints (Referential Integrity)   │   │
│  │ • Check Constraints (Data Validation)               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. Deployment Pipeline

```
┌────────────────────────────────────────────────────────────────┐
│                    CI/CD PIPELINE                              │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Developer                                                      │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  git push origin feature-branch                      │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  GitHub Actions Triggered                                     │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 1: Checkout Code & Setup                     │     │
│  │  - Clone repository                                │     │
│  │  - Setup Python/Flutter environments               │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 2: Lint & Format Checks                      │     │
│  │  - flake8 / black (Python)                         │     │
│  │  - dartfmt / analyze (Dart)                        │     │
│  │  - Security scanning                               │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 3: Unit & Integration Tests                  │     │
│  │  - pytest (Python backend)                         │     │
│  │  - flutter test (Dart frontend)                    │     │
│  │  - Coverage reports                                │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 4: Build Docker Images                       │     │
│  │  - docker build (API)                              │     │
│  │  - docker build (Frontend)                         │     │
│  │  - Tag with commit SHA                             │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 5: Push to Container Registry                │     │
│  │  - ECR / Docker Hub / GCR                          │     │
│  │  - Scan for vulnerabilities                        │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  Pull Request Opened                                         │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 6: Deploy to Staging                         │     │
│  │  - Update staging ECS tasks                        │     │
│  │  - Run smoke tests                                 │     │
│  │  - Generate deployment preview URL                 │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  Code Review & QA Testing                                    │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 7: Manual Approval Gate                      │     │
│  │  - Require 2 code reviews                          │     │
│  │  - QA sign-off on staging                          │     │
│  │  - Merge to main branch                            │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  Production Deployment Triggered                             │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 8: Deploy to Production                      │     │
│  │  - Blue-green deployment                           │     │
│  │  - Gradual rollout (canary: 10% → 50% → 100%)     │     │
│  │  - Health checks every 30 seconds                  │     │
│  │  - Automatic rollback on failures                  │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  STEP 9: Post-Deployment                           │     │
│  │  - Smoke tests on production                       │     │
│  │  - Verify metrics and logs                         │     │
│  │  - Notify team on Slack                            │     │
│  └─────────┬──────────────────────────────────────────┘     │
│            │                                                  │
│  ┌─────────▼──────────────────────────────────────────┐     │
│  │  ✅ DEPLOYMENT COMPLETE                            │     │
│  │  - Version tagged in production                    │     │
│  │  - Monitoring active                               │     │
│  │  - Ready for next deployment                       │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Data Flow Diagram

```
┌─────────────┐
│   Mobile    │
│   User      │
└──────┬──────┘
       │
       │ Open App
       │ View Dashboard
       │
       ▼
   ┌─────────────────────────────────┐
   │  Frontend (Flutter Mobile)      │
   │  - Display home dashboard       │
   │  - Show readiness score         │
   │  - Show today's workout         │
   └──────────┬──────────────────────┘
              │
              │ API Call
              │ GET /readiness
              │
              ▼
        ┌────────────────────────────┐
        │   Backend API (FastAPI)    │
        │   - Auth check (JWT)       │
        │   - Query recent metrics   │
        │   - Calculate readiness    │
        └────────┬──────────────────┘
                 │
                 │ Query
                 │
                 ▼
        ┌────────────────────────────┐
        │  PostgreSQL Database       │
        │  - health_metrics table    │
        │  - users table             │
        └────────┬──────────────────┘
                 │
                 │ Return Data
                 │
                 ▼
        ┌────────────────────────────┐
        │   Backend Processing       │
        │  - Calculate readiness     │
        │  - Format response JSON    │
        │  - Cache result (Redis)    │
        └────────┬──────────────────┘
                 │
                 │ JSON Response
                 │
                 ▼
        ┌────────────────────────────┐
        │   Frontend (Display)       │
        │  - Parse JSON              │
        │  - Update UI               │
        │  - Store in local cache    │
        └────────┬──────────────────┘
                 │
                 │
                 ▼
        ┌────────────────────────────┐
        │   User See Dashboard       │
        │  - Readiness: 7.2/10       │
        │  - HR: 65 bpm              │
        │  - Sleep: 7.5 hours        │
        └────────────────────────────┘

BACKGROUND PROCESS (Every 2 hours):

        ┌────────────────────────────┐
        │   iOS HealthKit            │
        │   - Collects metrics       │
        │   - HR, HRV, Sleep data    │
        └────────┬──────────────────┘
                 │
                 │ Sync Event
                 │
                 ▼
        ┌────────────────────────────┐
        │  Backend Sync Service      │
        │  - Poll HealthKit          │
        │  - Transform data          │
        └────────┬──────────────────┘
                 │
                 │ Insert/Update
                 │
                 ▼
        ┌────────────────────────────┐
        │  PostgreSQL Database       │
        │  - Update health_metrics   │
        │  - health_metrics.hr_data[]│
        └────────┬──────────────────┘
                 │
                 │ Trigger Event
                 │
                 ▼
        ┌────────────────────────────┐
        │  Supabase Function         │
        │  - AI Insights Trigger     │
        │  - Generate insights       │
        │  - Store in ai_insights    │
        └────────┬──────────────────┘
                 │
                 │ Insert
                 │
                 ▼
        ┌────────────────────────────┐
        │  PostgreSQL Database       │
        │  - ai_insights table       │
        │  - Ready for app query     │
        └────────────────────────────┘
```

---

## 7. Scaling Architecture

```
DEVELOPMENT STAGE:
┌─────────────────────────────────┐
│  Single Instance Deployment      │
│  ┌───────────────────────────┐  │
│  │ API + Frontend + DB       │  │
│  │ (All on one small VM)     │  │
│  │ ~$50-100/month            │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘

GROWTH STAGE:
┌──────────────────────────────────────────┐
│  Multi-Instance with Load Balancer       │
│  ┌────────────────────────────────────┐  │
│  │  Load Balancer (ALB/NLB)           │  │
│  └────────┬──────────────┬────────────┘  │
│           │              │               │
│  ┌────────▼────┐  ┌──────▼────┐         │
│  │ API Pod #1  │  │ API Pod#2 │         │
│  └──────┬──────┘  └──────┬────┘         │
│         │                │              │
│         └────────┬───────┘              │
│                  │                      │
│         ┌────────▼────────┐            │
│         │ Managed DB      │            │
│         │ (RDS/Supabase)  │            │
│         └─────────────────┘            │
│  ~$200-400/month                       │
└──────────────────────────────────────────┘

ENTERPRISE STAGE:
┌────────────────────────────────────────────────────┐
│  Fully Distributed Multi-Region Architecture      │
│  ┌──────────────────────────────────────────────┐ │
│  │         AWS CloudFront (Global CDN)          │ │
│  └──┬───────────────────────────────────┬───────┘ │
│     │ US REGION                         │ EU REGION
│  ┌──▼─────────────────────────┐    ┌───▼──────────────────┐
│  │ ALB                        │    │ ALB                  │
│  ├──────────┬──────────┐      │    ├────────┬────────┐    │
│  │API #1 #2 │#3 #4 #5 │      │    │API #1#2│#3 #4 #5│    │
│  ├──────────┴──────────┤      │    ├────────┴────────┤    │
│  │ Auto-Scaling Group  │      │    │Auto-Scaling Grp │    │
│  └──────────┬──────────┘      │    └────────┬────────┘    │
│             │                 │             │              │
│  ┌──────────▼──────────────┐  │  ┌─────────▼──────────┐   │
│  │ RDS Primary (MySQL)     │  │  │ RDS Read Replica   │   │
│  │ Multi-AZ               │  │  │ Replication Lag<1s │   │
│  │ Automated Backup       │  │  │                    │   │
│  └────────────────────────┘  │  └────────────────────┘   │
│                              │                            │
│  ElastiCache (Redis) ────────┼──► ElastiCache (Redis)    │
│  for Session & Cache         │    for Read Cache         │
│                              │                            │
│  ~$1500-3000/month          │                            │
└────────────────────────────────────────────────────────┘
```

---

## 8. Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   SECURITY LAYERS                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  LAYER 1: NETWORK SECURITY                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • WAF (Web Application Firewall)                   │  │
│  │  • DDoS Protection                                  │  │
│  │  • VPC with Private Subnets                         │  │
│  │  • Security Groups (Whitelist Rules)                │  │
│  │  • NACLs (Network Access Control Lists)             │  │
│  │  • Bastion Host for Admin Access                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 2: DATA IN TRANSIT                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • TLS 1.2+ (HTTPS/SSL)                             │  │
│  │  • Certificate Management (ACM)                     │  │
│  │  • VPN for Admin Connections                        │  │
│  │  • Encrypted Database Connections                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 3: AUTHENTICATION & AUTHORIZATION                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • JWT Token-based Auth (1-hour expiration)         │  │
│  │  • Refresh Token Rotation                           │  │
│  │  • OAuth 2.0 Support (Google, Apple)                │  │
│  │  • Multi-Factor Authentication (MFA)                │  │
│  │  • Role-Based Access Control (RBAC)                 │  │
│  │  • Service Account Keys (for API-to-API)            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 4: DATA AT REST                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • AES-256 Encryption (Database)                    │  │
│  │  • Field-level Encryption (PII)                     │  │
│  │  • Encrypted EBS Volumes                            │  │
│  │  • Encrypted S3 Buckets (if used)                   │  │
│  │  • Key Management Service (KMS)                     │  │
│  │  • Secrets Manager (for API keys)                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 5: APPLICATION SECURITY                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • Input Validation (Pydantic Schemas)              │  │
│  │  • SQL Injection Prevention (Parameterized Queries) │  │
│  │  • CSRF Protection                                  │  │
│  │  • XSS Protection                                   │  │
│  │  • Rate Limiting (1000 req/min per user)            │  │
│  │  • Request Signing                                  │  │
│  │  • Session Management                               │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 6: AUDIT & COMPLIANCE                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • Comprehensive Audit Logs                         │  │
│  │  • CloudTrail for API Logging                       │  │
│  │  • Database Activity Monitoring                     │  │
│  │  • User Activity Tracking                           │  │
│  │  • GDPR Compliance (Data Retention Policies)        │  │
│  │  • HIPAA Compliance (if handling health data)       │  │
│  │  • Regular Security Audits                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

**Diagram Version:** 1.0  
**Last Updated:** November 2025
