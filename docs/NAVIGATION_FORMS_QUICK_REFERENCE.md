# Navigation & Forms Quick Reference

## 🔗 Navigation Routes

| Route | Screen | Access |
|-------|--------|--------|
| `/login` | Login | Default if not authenticated |
| `/register` | Register | From login screen |
| `/home` | Dashboard | Default if authenticated |
| `/config` | App Config | From profile screen |

## 📝 Forms At A Glance

### Authentication

**Login** (`/login`)
- Email + Password
- API: `POST /auth/login`
- Validation: email format, password ≥6 chars

**Register** (`/register`)
- Email + Password + Confirm + Name (optional)
- API: `POST /auth/register`
- Validation: email format, password ≥8 chars, passwords match

### Goals

**Create/Edit Goal** (Dialog in GoalsScreen)
- Goal Type (required) + Target Value + Unit + Date + Notes
- API: `POST /goals`, `PUT /goals/{id}`
- Smart parsing: "5km" → value:5, unit:"km"

### Health Tracking

**Daily Metrics** (HealthMetricsScreen)
- Physical: HRV, Resting HR, VO2max, Sleep, Weight
- Subjective: RPE, Soreness, Mood (sliders 1-10)
- API: `POST /health/metrics`

**Strength Workout** (StrengthMetricsScreen)
- Lift Type + Weight + Reps + Set Number + Velocity (optional)
- Auto-calculates 1RM (Epley formula)
- API: `POST /process/strength`

**Swim Workout** (SwimMetricsScreen)
- Distance + Pace + Stroke Rate + Water Type
- Auto-calculates total time and formats pace
- API: `POST /process/swim`

## 🔌 API Endpoints Summary

### Auth
```
POST   /auth/register   → {access_token, refresh_token}
POST   /auth/login      → {access_token, refresh_token}
GET    /auth/me         → {user_info}
POST   /auth/refresh    → {new_tokens}
POST   /auth/logout     → void
```

### Goals
```
GET    /goals                    → [goals]
POST   /goals                    → {goal}
PUT    /goals/{id}               → {goal}
DELETE /goals/{id}               → void
GET    /goals/{id}/plans         → [plans]
POST   /goals/plans              → {plan}
```

### Health
```
POST   /health/samples           → {created, duplicates}
GET    /health/samples           → [samples]
GET    /health/summary           → {aggregated_stats}
POST   /health/metrics           → {metric}
GET    /health/metrics           → [metrics]
```

### Workouts
```
POST   /process/strength         → {analysis}
POST   /process/swim             → {analysis}
POST   /process/murph            → {analysis}
```

### Readiness & Plans
```
GET    /readiness/score          → {score, factors}
GET    /weekly-plans             → {plan}
POST   /weekly-plans             → {plan}
GET    /daily-plans              → {plan}
POST   /daily-plans              → {plan}
```

## ✅ Validation Rules Cheat Sheet

```dart
// Email
if (!value.contains('@')) return 'Please enter a valid email';

// Password (Login)
if (value.length < 6) return 'Password must be at least 6 characters';

// Password (Register)
if (value.length < 8) return 'Password must be at least 8 characters';

// Confirm Password
if (value != _passwordController.text) return 'Passwords do not match';

// Required
(v) => v == null || v.isEmpty ? 'Required' : null

// Optional Number
(v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Invalid number' : null
```

## 🧪 Run Tests

```bash
# Backend tests
cd applications/backend/python_fastapi_server
pytest tests/test_auth.py -v                  # Auth endpoints
pytest tests/test_daily_plans.py -v           # Daily plans
pytest tests/test_weekly_plans.py -v          # Weekly plans

# Frontend tests
cd applications/frontend/apps/mobile_app
flutter test test/forms_validation_test.dart  # Form validation
flutter test test/widget_test.dart            # Widget tests
```

## 🛠️ Common Tasks

**Add new form field:**
1. Add controller: `final _controller = TextEditingController();`
2. Add dispose: `_controller.dispose();`
3. Add TextFormField with validator
4. Include in submit payload

**Add new route:**
1. Add route to `main.dart` routes map
2. Or use Navigator.push with MaterialPageRoute
3. Update this documentation

**Add new API endpoint:**
1. Create/update router in `routers/`
2. Register in `main.py` if new router
3. Add to NAVIGATION_AND_FORMS.md
4. Create frontend service method
5. Write tests

**Debug form submission:**
1. Check network logs (backend logs)
2. Verify token in AuthService
3. Check endpoint in OpenAPI docs at `/docs`
4. Test with curl or pytest

## 📍 Key Files

```
Frontend Navigation:
- apps/mobile_app/lib/main.dart (routes)
- packages/home_dashboard_ui/lib/screens/home_screen.dart (hub)

Frontend Forms:
- packages/home_dashboard_ui/lib/screens/login_screen.dart
- packages/home_dashboard_ui/lib/screens/register_screen.dart
- packages/goals_ui/lib/screens/goals_screen.dart
- packages/readiness_ui/lib/screens/health_metrics_screen.dart
- packages/todays_workout_ui/lib/screens/strength_metrics_screen.dart
- packages/todays_workout_ui/lib/screens/swim_metrics_screen.dart

Backend Routers:
- routers/auth.py (authentication)
- routers/goals.py (goals CRUD)
- routers/health.py (health data)
- routers/daily_plans.py (daily planning)
- routers/weekly_plans.py (weekly planning)
- routers/chat.py (AI coach)

Tests:
- tests/test_auth.py (backend auth)
- tests/test_integration.py (backend integration)
- test/forms_validation_test.dart (frontend forms)
```

## 🚨 Common Issues

**"Backend unreachable"**
- Check `baseUrl` in AuthService
- Web: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://localhost:8000`

**"Token has been revoked"**
- User logged out or token blacklisted
- Clear app storage and re-login

**"Rate limit exceeded"**
- Too many requests in test environment
- Wait or disable rate limiting for tests

**Form validation not working**
- Check `_formKey.currentState!.validate()`
- Ensure validators return String? (null = valid)
- Verify validator is attached to TextFormField

## 🎯 Testing Checklist

Before pushing changes:

```bash
# Backend
cd applications/backend/python_fastapi_server
pytest tests/test_auth.py -v
pytest tests/test_integration.py -v

# Frontend
cd applications/frontend/apps/mobile_app
flutter test

# Manual smoke test
# 1. Login/Register
# 2. Create a goal
# 3. Log health metrics
# 4. Log a workout
# 5. Verify data persists
```

---

**For detailed documentation, see:**
- [NAVIGATION_AND_FORMS.md](./NAVIGATION_AND_FORMS.md) - Complete reference
- [CLAUDE.md](./CLAUDE.md) - Development guide
- [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) - System architecture
