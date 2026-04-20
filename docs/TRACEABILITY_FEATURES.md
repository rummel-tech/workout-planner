# Workout Planner — Feature Traceability Matrix

Maps each user-facing feature from OBJECTIVES.md through specification, tests, implementation, and release verification.

---

## Traceability Chain

```
OBJECTIVES.md (product description)
    → docs/SPECIFICATION.md / docs/ARCHITECTURE.md (specification)
    → docs/WORKFLOWS.md (primary user journeys and screen map)
        → packages/*/test/ — package unit/widget tests
        → test/ — app-level tests
        → integration_test/app_e2e_test.dart — end-to-end workflow tests
            → Source implementation
                → docs/DEPLOYMENT.md smoke test (release gate)
```

---

## FR-1 · Workout Management

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-1.1 | Create weekly workout plans (up to 3/day) | OBJECTIVES.md FR-1.1 | `weekly_plan_7day_view_test` · `day_edit_screen_limit_test` | `packages/home_dashboard_ui/lib/screens/day_edit_screen.dart` · `packages/home_dashboard_ui/lib/screens/weekly_plan_edit_screen.dart` · `packages/home_dashboard_ui/lib/services/weekly_plan_service.dart` | — |
| FR-1.2 | Workout types: Strength, Run, Swim, Murph, Bike, Yoga, Cardio, Mobility, Rest | OBJECTIVES.md FR-1.2 | `forms_validation_test` | `packages/home_dashboard_ui/lib/screens/day_edit_screen.dart` | — |
| FR-1.3 | Structured exercises (sets, reps, weight, duration, distance, rest) | OBJECTIVES.md FR-1.3 | `strength form increments set number after save` · `validates number input for sleep hours` · `calculates 1RM correctly` · `dropdown has all lift types` · `calculates total time correctly` · `formats pace correctly` · `water type selection works` | `packages/home_dashboard_ui/lib/screens/day_edit_screen.dart` | — |
| FR-1.4 | Warmup, main set, cooldown sections per workout | OBJECTIVES.md FR-1.4 | `renders all required fields (strength/cardio)` | `packages/home_dashboard_ui/lib/screens/day_edit_screen.dart` | — |
| FR-1.5 | Edit and reschedule workouts | OBJECTIVES.md FR-1.5 | `weekly_plan_edit_screen_limit_test` · `weekly_plan_preview_limit_test` | `packages/home_dashboard_ui/lib/screens/weekly_plan_edit_screen.dart` · `packages/home_dashboard_ui/lib/services/workout_service.dart` | — |

---

## FR-2 · Health Integration

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-2.1 | Sync with Apple HealthKit (iOS/macOS) | OBJECTIVES.md FR-2.1 | `health_sync_test` — all tests | `lib/services/healthkit_bridge.dart` · `lib/services/health_sync_manager.dart` · `packages/health_integration/lib/services/health_api_service.dart` | HealthKit sync functional on device |
| FR-2.2 | Read health metrics: sleep, HRV, resting heart rate, activity | OBJECTIVES.md FR-2.2 | `health_sync_test` · `health metrics date defaults to today` | `packages/home_dashboard_ui/lib/services/health_service.dart` · `packages/health_integration/lib/models/health_sample.dart` | — |
| FR-2.3 | Write workout sessions and calories burned to HealthKit | OBJECTIVES.md FR-2.3 | `health_sync_test` | `lib/services/health_api_service.dart` · `lib/services/health_sync_manager.dart` | — |
| FR-2.4 | Calculate readiness score from health metrics | OBJECTIVES.md FR-2.4 | `health_sync_test` | `packages/home_dashboard_ui/lib/services/readiness_service.dart` | Readiness score displayed on dashboard |

---

## FR-3 · Goals

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-3.1 | Create fitness goals with target dates | OBJECTIVES.md FR-3.1 | `goals_screen_test` · `shows error when goal type is empty` · `parses target value with unit suffix` | `packages/goals_ui/lib/screens/goal_plans_screen.dart` · `packages/goals_ui/lib/screens/goals_screen.dart` · `packages/goals_ui/lib/services/goals_api_service.dart` · `packages/goals_ui/lib/models/goal_plan.dart` | — |
| FR-3.2 | Link workouts to specific goals | OBJECTIVES.md FR-3.2 | `goals_screen_test` | `packages/goals_ui/lib/screens/goals_screen.dart` · `packages/goals_ui/lib/services/goals_api_service.dart` | — |
| FR-3.3 | Track goal progress over time | OBJECTIVES.md FR-3.3 | `goals_screen_test` | `packages/goals_ui/lib/screens/goal_plans_screen.dart` | — |
| FR-3.4 | Goal completion notifications | OBJECTIVES.md FR-3.4 | None — gap | `lib/src/screens/settings/notification_settings_screen.dart` | — |

---

## FR-4 · Authentication

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-4.1 | Email/password registration and login | OBJECTIVES.md FR-4.1 | `auth_service_test` · `auth_integration_test` · `auth_backend_test` · `login_screen_test` · `register_screen_test` · `login form clears error on re-submit` · `shows error when email is empty / invalid` · `shows error when password is too short` · `shows registration code input field` | `packages/home_dashboard_ui/lib/screens/login_screen.dart` · `packages/home_dashboard_ui/lib/screens/register_screen.dart` · `packages/home_dashboard_ui/lib/services/auth_service.dart` | Register → login succeeds |
| FR-4.2 | Google OAuth sign-in | OBJECTIVES.md FR-4.2 | `auth_backend_test` | `packages/home_dashboard_ui/lib/services/auth_service.dart` | — |
| FR-4.3 | Password reset via email | OBJECTIVES.md FR-4.3 | `forgot_password_widget_test` | `packages/home_dashboard_ui/lib/screens/forgot_password_screen.dart` | — |
| FR-4.4 | Secure token storage with auto-refresh | OBJECTIVES.md FR-4.4 | `auth_service_test` · `handles timeout gracefully` · `handles connection errors gracefully` | `packages/home_dashboard_ui/lib/services/auth_service.dart` · `packages/home_dashboard_ui/lib/services/secure_config_service.dart` | — |
| FR-4.5 | Welcome / onboarding screen | OBJECTIVES.md FR-4.1 | `welcome_screen_test` · `navigates to register screen` · `navigates to login screen` | `packages/home_dashboard_ui/lib/screens/welcome_screen.dart` | — |
| FR-4.6 | Registration code validation | OBJECTIVES.md FR-4.1 | `returns valid true when code exists` · `returns valid false when code does not exist` · `returns valid false when code is already used` · `returns valid false when code format is invalid` · `includes registration_code in request body` · `shows error when code is empty / too short` | `packages/home_dashboard_ui/lib/services/auth_service.dart` | — |
| FR-4.7 | Waitlisted vs registered status handling | OBJECTIVES.md FR-4.1 | `handles registered status with tokens` · `handles waitlisted status without tokens` | `packages/home_dashboard_ui/lib/services/auth_service.dart` | — |

---

## FR-5 · AI Coach

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-5.1 | Chat interface for fitness questions | OBJECTIVES.md FR-5.1 | None — gap | `packages/ai_coach_chat/lib/screens/chat_screen.dart` · `packages/ai_coach_chat/lib/services/chat_api_service.dart` | AI coach chat loads |
| FR-5.2 | Context-aware responses based on user data | OBJECTIVES.md FR-5.2 | None — gap | `packages/ai_coach_chat/lib/services/chat_api_service.dart` · `packages/ai_insights_ui/lib/screens/ai_insights_screen.dart` | — |
| FR-5.3 | Workout recommendations | OBJECTIVES.md FR-5.3 | None — gap | `packages/ai_insights_ui/lib/screens/ai_insights_screen.dart` | — |
| FR-5.4 | Conversation history | OBJECTIVES.md FR-5.4 | None — gap | `packages/ai_coach_chat/lib/models/chat_models.dart` · `packages/ai_coach_chat/lib/screens/chat_screen.dart` | — |

---

## FR-6 · Dashboard

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-6.1 | Daily overview with metrics and scheduled workouts | OBJECTIVES.md FR-6.1 | `home_screen_test` · `HomeScreen has a title and displays data` | `packages/home_dashboard_ui/lib/screens/home_screen.dart` · `packages/home_dashboard_ui/lib/services/daily_plan_service.dart` | Dashboard loads with daily overview |
| FR-6.2 | Readiness score display with contributing factors | OBJECTIVES.md FR-6.2 | `health_sync_test` | `packages/home_dashboard_ui/lib/screens/home_screen.dart` · `packages/home_dashboard_ui/lib/services/readiness_service.dart` | Readiness score displayed |
| FR-6.3 | Quick access to today's workout | OBJECTIVES.md FR-6.3 | `home_screen_test` | `packages/home_dashboard_ui/lib/screens/home_screen.dart` | — |
| FR-6.4 | Weekly calendar view (7-day) | OBJECTIVES.md FR-6.4 | `weekly_plan_7day_view_test` · `weekly_plan_preview_limit_test` | `packages/home_dashboard_ui/lib/screens/home_screen.dart` · `packages/home_dashboard_ui/lib/services/weekly_plan_service.dart` | Week plan view loads |

---

## Coverage Summary

| FR Group | Sub-features | Tests | Gaps |
|----------|-------------|-------|------|
| FR-1 Workout Management | 5 | Good (form tests, limit tests) | No backend API tests |
| FR-2 Health Integration | 4 | health_sync_test covers core | HealthKit write path has no mock |
| FR-3 Goals | 4 | goals_screen_test | Goal completion notifications untested |
| FR-4 Authentication | 7 | Comprehensive (unit + backend + widget) | None |
| FR-5 AI Coach | 4 | None | Entire feature uncovered — add chat_service_test |
| FR-6 Dashboard | 4 | Partial (home_screen_test) | Readiness factors breakdown untested |

## Workflow Documentation

Primary user journeys documented in `docs/WORKFLOWS.md`:
- Workflow 1: Authentication (register, login, Google OAuth, forgot password)
- Workflow 2: Core Workout Loop (plan → execute → log)
- Workflow 3: Readiness & Health Integration
- Workflow 4: Goal Management
- Workflow 5: AI Coach
- Screen / Route Map
