# Workout Planner — Primary Workflows

Documents the main user-facing journeys through the Workout Planner app.

---

## 1. Authentication

### New User Registration
1. Open app → **Welcome screen**
2. Tap **Register** → enter email, password
3. Account created; JWT stored; lands on **Home Dashboard**

### Returning User Login (Email)
1. Open app → **Welcome screen**
2. Tap **Log In** → enter email + password
3. JWT issued and stored; lands on **Home Dashboard**

### Google OAuth Sign-In
1. Open app → **Welcome screen**
2. Tap **Continue with Google** → complete OAuth flow
3. JWT issued and stored; lands on **Home Dashboard**

### Forgot Password
1. On Login screen → tap **Forgot password?**
2. Enter email → receive reset link
3. Follow link → set new password → log in

### Token Lifecycle
- Auth service auto-refreshes expired tokens in the background
- On unrecoverable auth failure, user is redirected to **Welcome screen**

---

## 2. Core Workout Loop (Plan → Execute → Log)

### Step 1: Open Weekly Plan
**Entry:** Home Dashboard → **Weekly Plan** or tap a day card

- 7-day calendar view (Mon–Sun)
- Each day shows scheduled workouts or "Rest"
- Up to 3 workouts per day

### Step 2: Add a Workout to a Day
**Entry:** Weekly Plan → "+" on any day

- Select workout type: Strength, Run, Swim, Murph, Bike, Yoga, Cardio, Mobility, Rest
- Name the workout
- Add warmup, main set, cooldown sections
- For each section add exercises: sets, reps, weight, duration, distance, rest period
- Save → workout appears on the day card

### Step 3: Execute Today's Workout
**Entry:** Home Dashboard → **Today's Workout** card

- View full workout detail (warmup / main / cooldown)
- Work through exercises in sequence
- Mark workout complete when done
- Workout logged; HealthKit write triggered (calories, activity)

### Step 4: View History
**Entry:** Dashboard or profile

- Past workouts listed with date, type, duration
- Tap a workout to see full detail

---

## 3. Readiness & Health Integration

### HealthKit Sync (iOS)
1. On first launch (iOS) → app requests HealthKit permissions
2. App reads: sleep duration, HRV, resting heart rate, activity
3. **Readiness Score** (0–100) calculated from health metrics
4. Score displayed on **Home Dashboard** with contributing factors

### Interpreting Readiness
| Score | Recommendation |
|-------|---------------|
| 80–100 | High-intensity training — go for it |
| 60–79 | Moderate effort — avoid max effort |
| 40–59 | Light activity — consider active recovery |
| 0–39 | Rest — prioritise sleep and recovery |

---

## 4. Goal Management

### Create a Goal
**Entry:** Goals screen → "+"

1. Enter title and description
2. Set target date
3. (Optional) link a workout type or plan
4. Save — goal appears in list with 0% progress

### Track Progress
- Progress bar updates as linked workouts are completed
- Tap a goal to view linked workouts and completion history

### Complete a Goal
- Mark goal complete from Goal Detail screen
- Completion notification triggered

---

## 5. AI Coach

### Start a Conversation
**Entry:** Home Dashboard → **AI Coach** tab

1. Type question or request (e.g. "What should I do on rest days?")
2. Coach responds with context-aware advice based on user history, readiness, and goals
3. Conversation history persisted across sessions

### Typical Use Cases
- "Suggest a workout for today given my readiness score"
- "What are good exercises for my shoulders?"
- "How can I improve my sleep quality?"

---

## 6. Screen / Route Map

| Screen | Purpose |
|--------|---------|
| WelcomeScreen | Landing / onboarding |
| LoginScreen | Email + password login |
| RegisterScreen | Account creation |
| ForgotPasswordScreen | Password reset |
| HomeScreen (Dashboard) | Daily overview — readiness, today's workout, goals |
| WeeklyPlanScreen | 7-day workout calendar |
| WorkoutDetailScreen | View/edit a single workout |
| ExerciseBuilderScreen | Add exercises to warmup/main/cooldown |
| GoalsScreen | List and manage fitness goals |
| GoalDetailScreen | Goal progress and linked workouts |
| AICoachScreen | Chat interface with AI coach |
| SettingsScreen | Profile, notifications, HealthKit permissions |

---

## 7. HealthKit Data Flow

```
Apple Health → HealthKit API
    → FocusTrainingService (sleep, HRV, RHR, activity)
        → ReadinessScoreCalculator
            → HomeScreen readiness card
```

Write path:
```
Workout completed → HealthKit write (workout session, calories)
```
