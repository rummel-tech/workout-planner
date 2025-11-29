# Navigation and Forms Documentation

## Navigation Structure

### Named Routes

The application uses named routes defined in `applications/frontend/apps/mobile_app/lib/main.dart`:

| Route | Screen | Purpose |
|-------|--------|---------|
| `/login` | `LoginScreen` | User authentication |
| `/register` | `RegisterScreen` | New user registration |
| `/home` | `HomeScreen` | Main dashboard (default route) |
| `/config` | `AppConfigScreen` | App theme and settings |

### Programmatic Navigation

Additional screens are navigated to using `Navigator.push()` with `MaterialPageRoute`:

| Screen | Accessed From | Purpose |
|--------|---------------|---------|
| `ChatScreen` | HomeScreen (chat icon) | AI coach conversations |
| `ProfileScreen` | HomeScreen (profile tile) | User profile and diagnostics |
| `GoalsScreen` | HomeScreen (goals card) | Create and manage fitness goals |
| `GoalPlansScreen` | GoalsScreen | View/edit plans for specific goal |
| `HealthMetricsScreen` | HomeScreen (Quick Log) | Log daily health metrics |
| `StrengthMetricsScreen` | HomeScreen (Quick Log) | Log strength training sets |
| `SwimMetricsScreen` | HomeScreen (Quick Log) | Log swim workouts |

### Navigation Flow

```
/login ←→ /register
   ↓
/home (Dashboard)
   ├→ ChatScreen
   ├→ ProfileScreen → /config
   ├→ GoalsScreen → GoalPlansScreen
   ├→ HealthMetricsScreen
   ├→ StrengthMetricsScreen
   └→ SwimMetricsScreen
```

## Forms Inventory

### 1. Authentication Forms

#### Login Form (`LoginScreen`)
**Location:** `applications/frontend/packages/home_dashboard_ui/lib/screens/login_screen.dart`

**Fields:**
- Email (TextFormField)
  - Type: email
  - Validation: Required, must contain '@'
  - Controller: `_emailController`

- Password (TextFormField)
  - Type: password (obscured)
  - Validation: Required, minimum 6 characters
  - Controller: `_passwordController`
  - Features: Show/hide toggle

**Submission:**
- Method: `_handleLogin()`
- API: `POST /auth/login`
- Backend: `applications/backend/python_fastapi_server/routers/auth.py:115`
- On Success: Navigate to `/home`
- On Error: Display error message below form

**Navigation:**
- "Sign Up" button → `/register`

---

#### Register Form (`RegisterScreen`)
**Location:** `applications/frontend/packages/home_dashboard_ui/lib/screens/register_screen.dart`

**Fields:**
- Full Name (TextFormField)
  - Type: text
  - Validation: Optional
  - Controller: `_fullNameController`

- Email (TextFormField)
  - Type: email
  - Validation: Required, must contain '@'
  - Controller: `_emailController`

- Password (TextFormField)
  - Type: password (obscured)
  - Validation: Required, minimum 8 characters
  - Controller: `_passwordController`
  - Features: Show/hide toggle

- Confirm Password (TextFormField)
  - Type: password (obscured)
  - Validation: Required, must match password
  - Controller: `_confirmPasswordController`
  - Features: Show/hide toggle

**Submission:**
- Method: `_handleRegister()`
- API: `POST /auth/register`
- Backend: `applications/backend/python_fastapi_server/routers/auth.py:90`
- On Success: Navigate to `/home`
- On Error: Display error message below form

**Navigation:**
- "Login" button → `/login`

---

### 2. Goals Forms

#### Create/Edit Goal Form (`GoalsScreen`)
**Location:** `applications/frontend/packages/goals_ui/lib/screens/goals_screen.dart`

**Fields:**
- Goal Type (TextFormField)
  - Type: text
  - Validation: Required
  - Hint: "e.g., Running, Strength, Swimming"
  - Controller: `_goalTypeController`

- Target Value (TextFormField)
  - Type: text (parsed as number)
  - Validation: Optional
  - Hint: "e.g., 5k, 26.2, 300"
  - Controller: `_targetValueController`
  - Note: Can extract unit suffix (e.g., "5km" → value:5, unit:"km")

- Target Unit (TextFormField)
  - Type: text
  - Validation: Optional
  - Hint: "e.g., km, mi, lbs, reps"
  - Controller: `_targetUnitController`

- Target Date (TextFormField)
  - Type: date (read-only, DatePicker)
  - Validation: Optional
  - Format: YYYY-MM-DD
  - Controller: `_targetDateController`

- Notes (TextFormField)
  - Type: multiline text (3 lines)
  - Validation: Optional
  - Controller: `_notesController`

**Submission:**
- Create Method: `_apiService.createGoal()`
- Update Method: `_apiService.updateGoal()`
- Create API: `POST /goals`
- Update API: `PUT /goals/{goal_id}`
- Backend: `applications/backend/python_fastapi_server/routers/goals.py`
- On Success: Refresh goals list, show SnackBar
- On Error: Show SnackBar with error

**Additional Actions:**
- Delete Goal: `DELETE /goals/{goal_id}`
- View Plans: Navigate to `GoalPlansScreen`

---

### 3. Health Metrics Form

#### Daily Health Metrics (`HealthMetricsScreen`)
**Location:** `applications/frontend/packages/readiness_ui/lib/screens/health_metrics_screen.dart`

**Fields:**
- Date (DatePicker)
  - Type: date
  - Default: Today
  - Range: Last 365 days to today
  - State: `_selectedDate`

**Physical Metrics:**
- HRV (TextFormField)
  - Label: "HRV (ms)"
  - Type: number
  - Validation: Optional
  - Helper: "Heart Rate Variability"
  - Controller: `_hrvController`

- Resting Heart Rate (TextFormField)
  - Label: "Resting Heart Rate (bpm)"
  - Type: number
  - Validation: Optional
  - Controller: `_restingHrController`

- VO2 Max (TextFormField)
  - Label: "VO2 Max (ml/kg/min)"
  - Type: number
  - Validation: Optional
  - Controller: `_vo2maxController`

- Sleep Hours (TextFormField)
  - Label: "Sleep Hours"
  - Type: number
  - Validation: Must be valid number if provided
  - Controller: `_sleepHoursController`

- Weight (TextFormField)
  - Label: "Weight (kg)"
  - Type: number
  - Validation: Optional
  - Controller: `_weightKgController`

**Subjective Ratings (Sliders 1-10):**
- RPE (Rate of Perceived Exertion)
  - Default: 5
  - Helper: "How hard did yesterday feel?"
  - State: `_rpe`

- Soreness
  - Default: 5
  - Helper: "Overall muscle soreness"
  - State: `_soreness`

- Mood
  - Default: 5
  - Helper: "Overall mood and energy"
  - State: `_mood`

**Submission:**
- Method: `_saveMetrics()` (TODO: API integration)
- Expected API: `POST /health/metrics`
- Backend: `applications/backend/python_fastapi_server/routers/health.py:182`
- On Success: Show SnackBar "Health metrics saved!"

**Additional Features:**
- View History: Modal bottom sheet with last 7 days

---

### 4. Workout Forms

#### Strength Training Form (`StrengthMetricsScreen`)
**Location:** `applications/frontend/packages/todays_workout_ui/lib/screens/strength_metrics_screen.dart`

**Fields:**
- Date (DatePicker)
  - Type: date
  - Default: Today
  - Range: Last 365 days to today
  - State: `_selectedDate`

- Lift Type (DropdownButtonFormField)
  - Options: squat, bench_press, deadlift, overhead_press, front_squat, power_clean, snatch, row, pull_up
  - Default: squat
  - State: `_liftType`

- Weight (TextFormField)
  - Label: "Weight (kg)"
  - Type: number
  - Validation: Required
  - Controller: `_weightController`

- Reps (TextFormField)
  - Label: "Reps"
  - Type: number
  - Validation: Required
  - Controller: `_repsController`

- Set Number (TextFormField)
  - Label: "Set Number"
  - Type: number
  - Validation: Required
  - Helper: "Which set in your workout (1, 2, 3...)"
  - Controller: `_setNumberController`

- Bar Velocity (TextFormField)
  - Label: "Bar Velocity (m/s)"
  - Type: number
  - Validation: Optional
  - Helper: "Optional - if using velocity tracker"
  - Controller: `_velocityController`

**Calculated Fields:**
- Estimated 1RM
  - Formula: weight × (1 + reps/30) (Epley formula)
  - Displayed in blue card when weight and reps are provided

**Submission:**
- Method: `_saveMetrics()` (TODO: API integration)
- Expected API: `POST /strength/log` or similar
- On Success: Show SnackBar, auto-increment set number, clear weight/reps/velocity

**Additional Features:**
- View History: Modal bottom sheet with recent lifts

---

#### Swim Workout Form (`SwimMetricsScreen`)
**Location:** `applications/frontend/packages/todays_workout_ui/lib/screens/swim_metrics_screen.dart`

**Fields:**
- Date (DatePicker)
  - Type: date
  - Default: Today
  - Range: Last 365 days to today
  - State: `_selectedDate`

- Water Type (Radio Buttons)
  - Options: Pool, Open Water
  - Default: Pool
  - State: `_waterType` ("pool" | "open_water")

- Distance (TextFormField)
  - Label: "Distance (meters)"
  - Type: number
  - Validation: Required
  - Helper: "e.g., 1000 for 1km"
  - Controller: `_distanceController`

- Average Pace (TextFormField)
  - Label: "Average Pace (seconds per 100m)"
  - Type: number
  - Validation: Required
  - Helper: Formatted as "M:SS / 100m" while typing
  - Controller: `_avgPaceController`

- Stroke Rate (TextFormField)
  - Label: "Stroke Rate (strokes per minute)"
  - Type: number
  - Validation: Optional
  - Controller: `_strokeRateController`

**Calculated Fields:**
- Formatted Pace: MM:SS / 100m
- Total Time: Calculated from distance and pace, displayed as MM:SS
- Workout Summary Card: Shows distance, pace, and total time

**Submission:**
- Method: `_saveMetrics()` (TODO: API integration)
- Expected API: `POST /swim/log` or similar
- On Success: Show SnackBar, clear form fields

**Additional Features:**
- View History: Modal bottom sheet with recent swims

---

## Backend API Endpoints

### Authentication
- `POST /auth/register` - Create new user account
  - Body: `{email, password, full_name?}`
  - Returns: `{access_token, refresh_token, user}`

- `POST /auth/login` - Authenticate user
  - Body: `{email, password}`
  - Returns: `{access_token, refresh_token, user}`

- `GET /auth/me` - Get current user info (requires auth)
  - Returns: `{id, email, full_name, created_at}`

- `POST /auth/refresh` - Refresh access token (requires refresh token)
  - Returns: `{access_token, refresh_token}`

- `POST /auth/logout` - Invalidate tokens (requires auth)

### Goals
- `GET /goals` - List user goals (requires auth, query: user_id)
- `POST /goals` - Create goal (requires auth)
  - Body: `{user_id, goal_type, target_value?, target_unit?, target_date?, notes?}`
- `PUT /goals/{goal_id}` - Update goal (requires auth)
- `DELETE /goals/{goal_id}` - Delete goal (requires auth)
- `GET /goals/{goal_id}/plans` - List plans for goal (requires auth)
- `POST /goals/plans` - Create plan (requires auth)
- `PUT /goals/plans/{plan_id}` - Update plan (requires auth)
- `DELETE /goals/plans/{plan_id}` - Delete plan (requires auth)

### Health
- `POST /health/samples` - Upload health samples (requires auth)
  - Body: `{user_id, samples: [{sample_type, value, unit, start_time, end_time, source_app, source_uuid}]}`
- `GET /health/samples` - List health samples (requires auth, query: user_id, sample_type?, start_date?, end_date?)
- `GET /health/summary` - Get aggregated health summary (requires auth, query: user_id, days?)
- `POST /health/metrics` - Create/update daily health metrics (requires auth)
  - Body: `{user_id, date, hrv_ms?, resting_hr?, vo2max?, sleep_hours?, weight_kg?, rpe?, soreness?, mood?}`
- `GET /health/metrics` - List health metrics (requires auth, query: user_id)
- `GET /health/date/{metric_date}` - Get metrics for specific date (requires auth)
- `PUT /health/{metric_id}` - Update health metric (requires auth)
- `DELETE /health/{metric_id}` - Delete health metric (requires auth)

### Workouts
- `POST /process/strength` - Log strength workout
- `POST /process/swim` - Log swim workout
- `POST /process/murph` - Log Murph workout

### Readiness
- `GET /readiness/score` - Calculate readiness score (requires auth, query: user_id)
- `GET /readiness/history` - Get historical readiness scores (requires auth)

### Plans
- `GET /weekly-plans` - Get weekly plan (requires auth, query: user_id, week_start?)
- `POST /weekly-plans` - Create/update weekly plan (requires auth)
- `GET /daily-plans` - Get daily plan (requires auth, query: user_id, date?)
- `POST /daily-plans` - Create/update daily plan (requires auth)

### Chat
- `GET /chat/sessions` - List chat sessions (requires auth)
- `POST /chat/sessions` - Create chat session (requires auth)
- `GET /chat/sessions/{session_id}/messages` - Get messages for session (requires auth)
- `POST /chat/sessions/{session_id}/messages` - Send message (requires auth)

## Form Validation Rules

### Common Patterns

**Email Validation:**
```dart
if (value == null || value.isEmpty) return 'Please enter your email';
if (!value.contains('@')) return 'Please enter a valid email';
```

**Password Validation:**
```dart
// Login: minimum 6 characters
if (value == null || value.isEmpty) return 'Please enter your password';
if (value.length < 6) return 'Password must be at least 6 characters';

// Registration: minimum 8 characters
if (value == null || value.isEmpty) return 'Please enter a password';
if (value.length < 8) return 'Password must be at least 8 characters';
```

**Confirm Password:**
```dart
if (value == null || value.isEmpty) return 'Please confirm your password';
if (value != _passwordController.text) return 'Passwords do not match';
```

**Required Field:**
```dart
validator: (v) => v == null || v.isEmpty ? 'Required' : null
```

**Optional Number:**
```dart
validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Invalid number' : null
```

## Authentication Flow

```
1. User loads app
   ↓
2. Check AuthService.isAuthenticated()
   ├─ Yes → Navigate to /home
   └─ No → Navigate to /login

3. User enters credentials
   ↓
4. Submit to backend
   ├─ Success → Save tokens to FlutterSecureStorage → Navigate to /home
   └─ Error → Display error message

5. Authenticated requests use Bearer token
   ├─ 401 → Attempt refresh
   │   ├─ Success → Retry request
   │   └─ Fail → Logout → Navigate to /login
   └─ Success → Continue
```

## Testing Checklist

### Navigation Tests
- [ ] Login → Register navigation works
- [ ] Register → Login navigation works
- [ ] Login success navigates to /home
- [ ] Register success navigates to /home
- [ ] Home → Goals → Goal Plans navigation works
- [ ] Home → Profile → Config navigation works
- [ ] Home → Chat opens ChatScreen
- [ ] Home → Quick Log screens open correctly
- [ ] Back button works on all pushed routes

### Form Validation Tests
- [ ] Login form validates email format
- [ ] Login form validates password length
- [ ] Register form validates email format
- [ ] Register form validates password length
- [ ] Register form validates password confirmation
- [ ] Goals form validates required goal_type
- [ ] Health metrics validates number inputs
- [ ] Strength form validates required fields
- [ ] Swim form validates required fields

### Form Submission Tests
- [ ] Login submits correctly and saves tokens
- [ ] Register submits correctly and saves tokens
- [ ] Goals create/update/delete work
- [ ] Health metrics save successfully
- [ ] Strength workout logs successfully
- [ ] Swim workout logs successfully
- [ ] Error messages display on API failures
- [ ] Loading states shown during submission
- [ ] Success messages shown after submission

### API Integration Tests
- [ ] All auth endpoints return correct status codes
- [ ] Token refresh works automatically
- [ ] Logout clears tokens
- [ ] Protected endpoints reject unauthenticated requests
- [ ] Goals CRUD operations work
- [ ] Health sample upload handles duplicates
- [ ] Readiness calculation returns valid scores
