---
module: workout-planner
version: 2.0.0
status: active
last_updated: 2026-01-20
---

# Workout Planner Specification

> **Source of Truth** - This document is the authoritative specification for all aspects of the Workout Planner application including data models, API endpoints, UI screens, and design system.

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Design System](#design-system)
4. [Data Models](#data-models)
5. [API Specification](#api-specification)
6. [UI Screen Specifications](#ui-screen-specifications)
7. [Use Cases](#use-cases)
8. [Implementation Status](#implementation-status)
9. [Technical Notes](#technical-notes)

---

## Overview

The Workout Planner is an AI-powered fitness coaching platform that provides personalized workout planning, health data integration, and intelligent recommendations. It features a multi-package Flutter application with an external FastAPI backend.

### Key Capabilities

- **Readiness-based training** - Adjust workouts based on HRV, sleep, and recovery
- **AI Coach chat** - Conversational fitness coaching with context awareness
- **Goal tracking** - Set and monitor fitness goals with sub-plans
- **Health metrics integration** - HealthKit/Google Fit data sync
- **Detailed workout logging** - Strength, swimming, and Murph workouts

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ main.dart   │  │  packages/  │  │  services/          │  │
│  │ (nav/theme) │  │  (features) │  │  (API clients)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTP/REST (JWT)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    FASTAPI BACKEND                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ PostgreSQL  │  │ OpenAI/     │  │ Registration        │  │
│  │ (Database)  │  │ Claude (AI) │  │ Code System         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Related Documentation

- `02_DATA_MODELS.md` - Extended data model definitions
- `03_API_SPECIFICATION.md` - Full API endpoint documentation
- `04_UI_SPECIFICATION.md` - Extended UI specifications

---

## Authentication

This module uses the shared AWS Amplify authentication system. See [Authentication Architecture](../../../../docs/architecture/AUTHENTICATION.md) for complete details.

### Authentication Modes

| Mode | Description |
|------|-------------|
| Artemis-Integrated | User authenticates via Artemis, gains access to all permitted modules |
| Standalone | User authenticates directly in Workout Planner app |

### Module Access

- **Module ID**: `workout-planner`
- **Artemis Users**: Full access when `artemis_access: true`
- **Standalone Users**: Access when `workout-planner` in `module_access` list

### Login Screen

Uses shared `auth_ui` package with identical UI to all other modules:
- Email/password authentication
- Google Sign-In
- Apple Sign-In
- Email verification flow
- Password reset flow

### API Authentication

All API endpoints require JWT Bearer token from AWS Cognito:
```http
Authorization: Bearer <access_token>
```

Backend validates tokens using AWS Cognito SDK and checks module access permissions. Registration codes (existing feature) are being migrated to Amplify-based access control.

---

## Design System

### Color Palette

#### Primary Colors (Rummel Blue)

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `primary500` | `#1E88E5` | rgb(30, 136, 229) | Primary actions, app bar, FAB |
| `primary400` | `#42A5F5` | rgb(66, 165, 245) | Hover states, secondary emphasis |
| `primary600` | `#1565C0` | rgb(21, 101, 192) | Pressed states |
| `primary700` | `#0D47A1` | rgb(13, 71, 161) | Dark mode primary |

#### Secondary Colors (Teal)

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `secondary500` | `#26A69A` | rgb(38, 166, 154) | Secondary actions, accents |
| `secondary400` | `#4DB6AC` | rgb(77, 182, 172) | Hover states |

#### Semantic Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `error` | `#D32F2F` | Error states, destructive actions, low readiness |
| `success` | `#388E3C` | Success states, positive feedback, high readiness |
| `warning` | `#F57C00` | Warning states, caution, moderate readiness |

#### Surface Colors

| Token | Light Mode | Dark Mode |
|-------|------------|-----------|
| `surface` | `#FAFAFA` | `#121212` |
| `background` | `#FFFFFF` | `#1E1E1E` |
| `card` | `#FFFFFF` | `#2C2C2C` |

#### Readiness Score Colors

| Score Range | Color | Token | Meaning |
|-------------|-------|-------|---------|
| 70-100% | Green | `success` | Good to train hard |
| 40-69% | Orange | `warning` | Moderate intensity recommended |
| 0-39% | Red | `error` | Recovery recommended |

### Typography

Uses Material 3 type scale with system fonts.

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `displayLarge` | 57sp | 400 | 64sp | Hero numbers (readiness score) |
| `displayMedium` | 45sp | 400 | 52sp | Large titles |
| `headlineLarge` | 32sp | 400 | 40sp | Screen titles |
| `headlineMedium` | 28sp | 400 | 36sp | Section headers |
| `titleLarge` | 22sp | 500 | 28sp | Card titles |
| `titleMedium` | 16sp | 500 | 24sp | List item titles |
| `titleSmall` | 14sp | 500 | 20sp | Subtitles |
| `bodyLarge` | 16sp | 400 | 24sp | Primary body text |
| `bodyMedium` | 14sp | 400 | 20sp | Secondary body text |
| `bodySmall` | 12sp | 400 | 16sp | Captions |
| `labelLarge` | 14sp | 500 | 20sp | Button labels |
| `labelMedium` | 12sp | 500 | 16sp | Form labels |
| `labelSmall` | 11sp | 500 | 16sp | Badges, chips |

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4dp | Tight spacing, icon gaps |
| `sm` | 8dp | Default element spacing |
| `md` | 16dp | Card padding, section gaps |
| `lg` | 24dp | Screen padding |
| `xl` | 32dp | Large section separation |
| `xxl` | 48dp | Hero spacing |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 4dp | Small elements |
| `md` | 8dp | Buttons, inputs |
| `lg` | 12dp | Cards |
| `xl` | 16dp | Bottom sheets |
| `full` | 24dp | Chips, avatars |

### Component Specifications

#### Buttons

**ElevatedButton (Primary)**
```
Background: colorScheme.primary
Foreground: colorScheme.onPrimary
Padding: horizontal 24dp, vertical 12dp
BorderRadius: 8dp
MinHeight: 48dp
Elevation: 2dp
```

**OutlinedButton (Secondary)**
```
Background: transparent
Foreground: colorScheme.primary
Border: 1dp solid colorScheme.primary
Padding: horizontal 24dp, vertical 12dp
BorderRadius: 8dp
MinHeight: 48dp
```

**TextButton (Tertiary)**
```
Background: transparent
Foreground: colorScheme.primary
Padding: horizontal 16dp, vertical 8dp
```

**FilledButton (Tonal)**
```
Background: colorScheme.primaryContainer
Foreground: colorScheme.onPrimaryContainer
Padding: horizontal 24dp, vertical 12dp
BorderRadius: 8dp
```

#### Cards

```
Elevation: 2dp (light), 4dp (dark)
BorderRadius: 12dp
Padding: 16dp (content)
Margin: 8dp (between cards)
Background: colorScheme.surface
```

#### Input Fields

```
Type: OutlineInputBorder
BorderRadius: 8dp
BorderColor: colorScheme.outline
FocusedBorderColor: colorScheme.primary
FocusedBorderWidth: 2dp
Padding: horizontal 16dp, vertical 12dp
LabelStyle: labelMedium
HelperTextStyle: bodySmall
ErrorTextStyle: bodySmall, color: error
```

#### App Bar

**Light Mode**
```
Background: colorScheme.primary
Foreground: colorScheme.onPrimary
Elevation: 2dp
TitleStyle: titleLarge
```

**Dark Mode**
```
Background: colorScheme.surface
Foreground: colorScheme.onSurface
Elevation: 0dp
TitleStyle: titleLarge
```

#### Bottom Navigation

```
Type: BottomAppBar with notched FAB
Items: 4 (Home, Plan, Goals, Profile)
FAB: Center-docked, circular, notched
SelectedItemColor: colorScheme.primary
UnselectedItemColor: colorScheme.onSurface.withOpacity(0.6)
LabelStyle: labelSmall
```

#### Chips

```
Background: colorScheme.surfaceVariant
SelectedBackground: colorScheme.primaryContainer
LabelStyle: labelSmall
Padding: horizontal 12dp, vertical 8dp
BorderRadius: 8dp
```

### Iconography

Uses Material Icons. Standard size: 24dp.

| Feature | Icon | Code Point |
|---------|------|------------|
| Home | `home` | `Icons.home` |
| Plan | `calendar_today` | `Icons.calendar_today` |
| Goals | `flag` | `Icons.flag` |
| Profile | `person` | `Icons.person` |
| AI Coach | `chat_bubble_outline` | `Icons.chat_bubble_outline` |
| Strength | `fitness_center` | `Icons.fitness_center` |
| Run | `directions_run` | `Icons.directions_run` |
| Swim | `pool` | `Icons.pool` |
| Bike | `directions_bike` | `Icons.directions_bike` |
| Yoga | `self_improvement` | `Icons.self_improvement` |
| Rest | `hotel` | `Icons.hotel` |
| Mobility | `accessibility` | `Icons.accessibility` |
| Cardio | `favorite` | `Icons.favorite` |
| Health | `favorite` | `Icons.favorite` |
| Settings | `settings` | `Icons.settings` |
| Add | `add` | `Icons.add` |
| Edit | `edit` | `Icons.edit` |
| Delete | `delete` | `Icons.delete` |
| Save | `check` | `Icons.check` |
| Back | `arrow_back` | `Icons.arrow_back` |
| Email | `email_outlined` | `Icons.email_outlined` |
| Password | `lock_outline` | `Icons.lock_outline` |
| Visibility | `visibility` | `Icons.visibility` |
| Visibility Off | `visibility_off` | `Icons.visibility_off` |

---

## Data Models

### User

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | String | PK, UUID | Unique identifier |
| email | String | Required, unique | User email address |
| hashed_password | String | Required | Bcrypt hashed password |
| full_name | String? | Optional | Display name |
| is_active | bool | Default: true | Account active status |
| is_admin | bool | Default: false | Admin privileges |
| created_at | DateTime | Auto | Creation timestamp |
| updated_at | DateTime | Auto | Last update timestamp |

### UserGoal

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Unique identifier |
| user_id | String | FK to User | Owner user |
| goal_type | String | Required | Goal category |
| target_value | float | Optional | Target metric value |
| target_unit | String | Optional | Unit of measurement |
| target_date | String | ISO date | Target completion date |
| notes | String? | Optional | Additional notes |
| is_active | bool | Default: true | Active status |
| created_at | DateTime | Auto | Creation timestamp |
| updated_at | DateTime | Auto | Last update timestamp |

**Goal Types:**

| Type | Description | Example Target |
|------|-------------|----------------|
| Running | Distance or time | 5 km, 30 minutes |
| Strength | Lift weight | 315 lbs deadlift |
| Swimming | Distance or pace | 1000 m, 2:00/100m |
| Weight Loss | Body weight | 180 lbs |
| Endurance | Duration | 60 min run |
| Murph | Completion time | < 45 minutes |

### HealthSample

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Unique identifier |
| user_id | String | Required | Owner user |
| sample_type | String | Required | Type of health data |
| value | float | Required | Measured value |
| unit | String | Optional | Unit of measurement |
| start_time | DateTime | Required | Sample start time |
| end_time | DateTime? | Optional | Sample end time |
| source_app | String? | Optional | Source application |
| source_uuid | String? | Optional | Source unique ID |
| created_at | DateTime | Auto | Creation timestamp |

**Sample Types:**

| Type | Unit | Description |
|------|------|-------------|
| hrv | ms | Heart Rate Variability |
| resting_hr | bpm | Resting Heart Rate |
| sleep_stage | hours | Sleep duration |
| workout_distance | meters | Workout distance |
| workout_calories | kcal | Calories burned |
| vo2max | mL/kg/min | VO2 Max estimate |
| weight | kg | Body weight |

### DailyPlan

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Unique identifier |
| user_id | String | Required | Owner user |
| date | String | Required, ISO date | Plan date |
| workouts | List\<Workout\> | JSON | Workout array (max 3) |
| ai_notes | String? | Optional | AI-generated notes |
| status | String | Default: pending | Plan status |
| created_at | DateTime | Auto | Creation timestamp |
| updated_at | DateTime | Auto | Last update timestamp |

**Workout Object:**

```json
{
  "name": "Upper Body Strength",
  "type": "strength",
  "focus": "Push",
  "time_goal": "60 min",
  "warmup": [{"name": "Arm circles", "reps": 20}],
  "main": [{"name": "Bench Press", "sets": 4, "reps": 6, "weight": 185, "weightUnit": "lbs"}],
  "cooldown": [{"name": "Stretch", "duration": 300}],
  "notes": "Focus on form",
  "status": "pending"
}
```

**Workout Types:**

| Type | Icon | Description |
|------|------|-------------|
| strength | `fitness_center` | Weight training |
| run | `directions_run` | Running/jogging |
| swim | `pool` | Swimming |
| murph | `military_tech` | Murph workout |
| bike | `directions_bike` | Cycling |
| yoga | `self_improvement` | Yoga/flexibility |
| cardio | `favorite` | General cardio |
| mobility | `accessibility` | Mobility work |
| rest | `hotel` | Rest/recovery day |

### Exercise

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| name | String | Required | Exercise name |
| sets | int? | Optional | Number of sets |
| reps | int? | Optional | Repetitions per set |
| weight | double? | Optional | Weight amount |
| weightUnit | String | Default: "lbs" | Weight unit (lbs/kg) |
| duration | int? | Optional | Duration in seconds |
| distance | double? | Optional | Distance amount |
| distanceUnit | String | Default: "miles" | Distance unit (miles/km/meters/yards/laps) |
| rest | int? | Optional | Rest period in seconds |
| notes | String? | Optional | Exercise notes |

**Computed Property - Summary:**
```
"{sets}x{reps} @ {weight}{weightUnit}" (strength)
"{distance}{distanceUnit}" (cardio)
"{duration}sec" (timed)
```

### WeeklyPlan

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Unique identifier |
| user_id | String | Required | Owner user |
| week_start | String | Required, Monday | Week start date (ISO) |
| focus | String | Optional | Weekly focus theme |
| days | List\<DayPlan\> | JSON | 7 day summaries |
| created_at | DateTime | Auto | Creation timestamp |
| updated_at | DateTime | Auto | Last update timestamp |

### StrengthMetrics

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Unique identifier |
| user_id | String | Required | Owner user |
| date | String | Required, ISO date | Workout date |
| lift | String | Required | Exercise name |
| weight | float | Required | Weight lifted |
| reps | int | Required | Repetitions |
| set_number | int | Required | Set number |
| estimated_1rm | float? | Calculated | Estimated 1-rep max |
| velocity_m_per_s | float? | Optional | Bar velocity |
| created_at | DateTime | Auto | Creation timestamp |

**Lift Types:**
- squat
- bench_press
- deadlift
- overhead_press
- front_squat
- power_clean
- snatch
- row
- pull_up

**1RM Calculation (Epley Formula):**
```
estimated_1rm = weight * (1 + reps / 30)
```

### SwimMetrics

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Unique identifier |
| user_id | String | Required | Owner user |
| date | String | Required, ISO date | Workout date |
| distance_meters | float | Required | Distance swum |
| duration_seconds | int | Required | Total time |
| avg_pace_seconds | float | Calculated | Pace per 100m |
| stroke_type | String? | Optional | Stroke used |
| water_type | String | Required | pool/open_water |
| created_at | DateTime | Auto | Creation timestamp |

**Pace Calculation:**
```
avg_pace_seconds = duration_seconds / (distance_meters / 100)
```

**Pace Display Format:** `M:SS / 100m`

### MurphMetrics

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Unique identifier |
| user_id | String | Required | Owner user |
| date | String | Required, ISO date | Workout date |
| run_1_time_seconds | int | Required | First mile time |
| run_2_time_seconds | int | Required | Second mile time |
| partition | String | Required | Workout partition |
| total_time_seconds | int | Required | Total workout time |
| vest_weight | float? | Optional | Weight vest used (lbs) |
| notes | String? | Optional | Workout notes |
| created_at | DateTime | Auto | Creation timestamp |

**Partition Types:**
- `20-10-5`: 20 rounds of 5 pull-ups, 10 push-ups, 15 squats
- `singles`: All pull-ups, then push-ups, then squats
- `unpartitioned`: Mix as needed

### ChatSession / ChatMessage

**ChatSession:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Session ID |
| user_id | String | Required | Owner user |
| title | String? | Optional | Session title |
| created_at | DateTime | Auto | Creation timestamp |
| updated_at | DateTime | Auto | Last update timestamp |
| message_count | int | Computed | Number of messages |

**ChatMessage:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | int | PK, auto | Message ID |
| session_id | int | FK to ChatSession | Parent session |
| role | String | Required | "user" or "assistant" |
| content | String | Required | Message text |
| metadata | JSON? | Optional | AI response metadata |
| created_at | DateTime | Auto | Timestamp |

### ReadinessScore (Computed)

| Field | Type | Description |
|-------|------|-------------|
| user_id | String | User identifier |
| score | float | 0.0 - 1.0 score |
| hrv_score | float | HRV component (0-1) |
| rhr_score | float | Resting HR component (0-1) |
| sleep_score | float | Sleep component (0-1) |
| limiting_factor | String? | Lowest scoring factor |
| computed_at | DateTime | Calculation time |

**Calculation:**
```
score = (hrv_score * 0.4) + (rhr_score * 0.3) + (sleep_score * 0.3)
hrv_score = min(1.0, current_hrv / baseline_hrv)  // 14-day rolling avg
rhr_score = min(1.0, baseline_rhr / current_rhr)  // inverted, lower is better
sleep_score = min(1.0, sleep_hours / 8.0)
```

**Display:** `score * 100` as percentage

---

## API Specification

### Authentication Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/register` | POST | Create account with registration code |
| `/auth/login` | POST | Authenticate and get tokens |
| `/auth/refresh` | POST | Refresh access token |
| `/auth/logout` | POST | Invalidate token |
| `/auth/me` | GET | Get current user info |
| `/auth/validate-code` | POST | Validate registration code |

### Goal Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/goals` | GET | List user goals |
| `/goals` | POST | Create new goal |
| `/goals/{id}` | GET | Get specific goal |
| `/goals/{id}` | PUT | Update goal |
| `/goals/{id}` | DELETE | Deactivate goal |
| `/goals/{id}/plans` | GET | Get goal's plans |
| `/goals/{id}/plans` | POST | Create plan for goal |
| `/goals/{id}/plans/{plan_id}` | PUT | Update plan |
| `/goals/{id}/plans/{plan_id}` | DELETE | Delete plan |

### Health Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health/samples` | POST | Bulk ingest samples |
| `/health/samples` | GET | List health samples |
| `/health/summary` | GET | Aggregated summary |
| `/health/trends` | GET | Metric trends |
| `/readiness` | GET | Get readiness score |

### Planning Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/daily-plans/{user_id}/{date}` | GET | Get daily plan |
| `/daily-plans/{user_id}/{date}` | PUT | Update daily plan |
| `/weekly-plans/{user_id}` | GET | Get weekly plan |
| `/weekly-plans/{user_id}` | PUT | Update weekly plan |

### Logging Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/strength` | POST | Log strength set |
| `/strength` | GET | Get strength metrics |
| `/strength/progress/{lift}` | GET | Lift progress |
| `/swim` | POST | Log swim workout |
| `/swim/trends` | GET | Swim trends |
| `/murph` | POST | Log Murph workout |
| `/murph/progress` | GET | Murph stats |

### Chat Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/chat/sessions` | POST | Create chat session |
| `/chat/sessions` | GET | List sessions |
| `/chat/messages` | POST | Send message, get AI response |
| `/chat/messages/{session_id}` | GET | Get session messages |

---

## UI Screen Specifications

### Navigation Structure

```
App Entry (main.dart)
├── /welcome ────────► WelcomeScreen
├── /login ──────────► LoginScreen
├── /register ───────► RegisterScreen
├── /forgot ─────────► ForgotPasswordScreen
├── /setup ──────────► SetupWizardScreen
└── /home ───────────► HomeScreen (IndexedStack with 4 tabs)
    ├── Tab 0: Home Dashboard
    │   └── → ChatScreen (AI Coach icon)
    │   └── → DayEditScreen (Today's workout tap)
    ├── Tab 1: Weekly Plan
    │   └── → WeeklyPlanEditScreen
    │       └── → DayEditScreen
    │           └── → WorkoutDetailScreen
    ├── Tab 2: Goals
    │   └── → GoalsScreen
    │       └── → GoalPlansScreen
    └── Tab 3: Profile
        └── → ProfileScreen

Quick Log FAB (from any tab)
├── → HealthMetricsScreen
├── → StrengthMetricsScreen
└── → SwimMetricsScreen
```

---

### Screen: WelcomeScreen

**Package:** `home_dashboard_ui`
**Route:** `/welcome`
**Purpose:** App entry point for unauthenticated users

#### Layout

```
┌─────────────────────────────────┐
│         SafeArea                │
│  ┌───────────────────────────┐  │
│  │    [fitness_center icon]  │  │
│  │         100x100           │  │
│  │     color: primary500     │  │
│  ├───────────────────────────┤  │
│  │    "Workout-Planner"      │  │
│  │   headlineLarge, bold     │  │
│  ├───────────────────────────┤  │
│  │  "AI-Powered Training     │  │
│  │       Platform"           │  │
│  │  bodyLarge, onSurface.60  │  │
│  ├───────────────────────────┤  │
│  │     [Feature Card 1]      │  │
│  │     [Feature Card 2]      │  │
│  │     [Feature Card 3]      │  │
│  ├───────────────────────────┤  │
│  │    [ Login Button ]       │  │
│  │      ElevatedButton       │  │
│  │                           │  │
│  │  [ Sign Up with Code ]    │  │
│  │      OutlinedButton       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Feature Cards

| # | Icon | Title | Description |
|---|------|-------|-------------|
| 1 | `auto_awesome` | AI Coach | Personalized training advice powered by AI |
| 2 | `calendar_today` | Smart Planning | Weekly plans that adapt to your recovery |
| 3 | `trending_up` | Performance Insights | Track progress and hit your goals |

#### Actions

| Element | Type | Label | Navigation |
|---------|------|-------|------------|
| Login Button | ElevatedButton | "Login" | `/login` |
| Sign Up Button | OutlinedButton | "Sign Up with Code" | `/register` |

#### State

- Stateless widget

---

### Screen: LoginScreen

**Package:** `home_dashboard_ui`
**Route:** `/login`
**Purpose:** User authentication

#### Layout

```
┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │    [fitness_center icon]  │  │
│  │          64x64            │  │
│  ├───────────────────────────┤  │
│  │      "Welcome Back"       │  │
│  │      headlineMedium       │  │
│  ├───────────────────────────┤  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Error Banner (red)  │ │  │
│  │   │ if _errorMessage    │ │  │
│  │   └─────────────────────┘ │  │
│  ├───────────────────────────┤  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Email TextField     │ │  │
│  │   │ icon: email_outlined│ │  │
│  │   └─────────────────────┘ │  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Password TextField  │ │  │
│  │   │ icon: lock_outline  │ │  │
│  │   │ suffix: visibility  │ │  │
│  │   └─────────────────────┘ │  │
│  ├───────────────────────────┤  │
│  │   [Forgot password?]      │  │
│  │      TextButton, right    │  │
│  ├───────────────────────────┤  │
│  │      [ Login ]            │  │
│  │    ElevatedButton, full   │  │
│  ├───────────────────────────┤  │
│  │   ─────── OR ───────      │  │
│  ├───────────────────────────┤  │
│  │  [Sign in with Google]    │  │
│  │    OutlinedButton, full   │  │
│  ├───────────────────────────┤  │
│  │  "Don't have an account?" │  │
│  │       [Sign up]           │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Input Fields

| Field | Label | Icon | Keyboard | Validation |
|-------|-------|------|----------|------------|
| Email | "Email" | `email_outlined` | emailAddress | Required, contains '@' |
| Password | "Password" | `lock_outline` | text | Required, min 6 chars |

#### Actions

| Element | Type | Label | Action |
|---------|------|-------|--------|
| Forgot Password | TextButton | "Forgot password?" | Navigate `/forgot` |
| Login | ElevatedButton | "Login" / CircularProgressIndicator | `authService.login()` → `/home` or `/setup` |
| Google Sign In | OutlinedButton | "Sign in with Google" | `authService.signInWithGoogle()` |
| Sign Up | TextButton | "Sign up" | Navigate `/register` |

#### State

| Variable | Type | Initial | Description |
|----------|------|---------|-------------|
| `_emailController` | TextEditingController | empty | Email input |
| `_passwordController` | TextEditingController | empty | Password input |
| `_isLoading` | bool | false | Shows spinner on login button |
| `_errorMessage` | String? | null | Error banner text |
| `_obscurePassword` | bool | true | Password visibility toggle |

---

### Screen: RegisterScreen

**Package:** `home_dashboard_ui`
**Route:** `/register`
**Purpose:** New user registration (2-step flow)

#### Step 1: Code Validation

```
┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │    [vpn_key_outlined]     │  │
│  │          64x64            │  │
│  ├───────────────────────────┤  │
│  │ "Enter Registration Code" │  │
│  │      headlineMedium       │  │
│  ├───────────────────────────┤  │
│  │   [Error Banner if any]   │  │
│  ├───────────────────────────┤  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Registration Code   │ │  │
│  │   │ hint: "ABC12345"    │ │  │
│  │   │ caps: CHARACTERS    │ │  │
│  │   └─────────────────────┘ │  │
│  ├───────────────────────────┤  │
│  │    [ Validate Code ]      │  │
│  ├───────────────────────────┤  │
│  │ [Already have account?]   │  │
│  │ [Don't have a code?]      │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Step 2: User Details

```
┌─────────────────────────────────┐
│  ← Back      Step 2 of 2        │
│  ┌───────────────────────────┐  │
│  │  ✓ Code: ABC12345         │  │
│  │  Container: success bg    │  │
│  ├───────────────────────────┤  │
│  │  "Create Your Account"    │  │
│  │     headlineMedium        │  │
│  ├───────────────────────────┤  │
│  │   [Error Banner if any]   │  │
│  ├───────────────────────────┤  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Full Name (Optional)│ │  │
│  │   └─────────────────────┘ │  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Email              │ │  │
│  │   └─────────────────────┘ │  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Password           │ │  │
│  │   └─────────────────────┘ │  │
│  │   ┌─────────────────────┐ │  │
│  │   │ Confirm Password   │ │  │
│  │   └─────────────────────┘ │  │
│  ├───────────────────────────┤  │
│  │    [ Create Account ]     │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Input Fields

**Step 1:**

| Field | Label | Hint | Validation |
|-------|-------|------|------------|
| Registration Code | "Registration Code" | "e.g., ABC12345" | Required, min 4 chars |

**Step 2:**

| Field | Label | Icon | Validation |
|-------|-------|------|------------|
| Full Name | "Full Name (Optional)" | `person_outline` | None |
| Email | "Email" | `email_outlined` | Required, contains '@' |
| Password | "Password" | `lock_outline` | Required, min 8 chars |
| Confirm Password | "Confirm Password" | `lock_outline` | Must match password |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_currentStep` | int | 1 or 2 |
| `_validatedCode` | String? | Validated code (shown in step 2) |
| `_isLoading` | bool | Loading state |
| `_errorMessage` | String? | Error display |
| `_showWaitlistForm` | bool | Toggle waitlist form |
| `_obscurePassword` | bool | Password visibility |
| `_obscureConfirm` | bool | Confirm visibility |

---

### Screen: SetupWizardScreen

**Package:** `home_dashboard_ui`
**Route:** `/setup`
**Purpose:** Initial configuration (4-page wizard)

#### Layout

```
┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │  Progress: ████░░░░ 1/4   │  │
│  │  LinearProgressIndicator  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │       PageView            │  │
│  │    (swipeable pages)      │  │
│  │                           │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  [Back]      [Continue]   │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Page 1: Welcome

| Element | Content |
|---------|---------|
| Icon | `fitness_center`, 80x80 |
| Title | "Welcome to Workout-Planner" |
| Subtitle | "Let's get you set up" |
| Features | 3 bullet points |
| Button | "Get Started" (FilledButton) |

#### Page 2: Server Configuration

| Field | Type | Properties |
|-------|------|------------|
| API Server URL | TextField | label: "API Server URL", icon: `cloud`, hint: "https://api.example.com", keyboardType: url |

| Button | Label | Action |
|--------|-------|--------|
| Test Connection | OutlinedButton | `configService.testApiConnection()` |
| Continue | FilledButton | Disabled if URL empty |

#### Page 3: AI Configuration

| Option | Radio Value | Additional Fields |
|--------|-------------|-------------------|
| Skip for now | 'none' | None |
| OpenAI (GPT) | 'openai' | API Key (obscured, hint: "sk-...") |
| Anthropic (Claude) | 'anthropic' | API Key (obscured, hint: "sk-ant-...") |

#### Page 4: Health Data

| Field | Type | Properties |
|-------|------|------------|
| Enable Health Sync | SwitchListTile | icon: `favorite`, title: "Enable Health Data Sync", subtitle: "Connect to Apple Health or Google Fit" |

**Data Access List (when enabled):**
- Workouts
- Heart Rate
- HRV (Heart Rate Variability)
- Sleep Analysis
- Steps
- Active Energy

| Button | Label | Action |
|--------|-------|--------|
| Finish Setup | FilledButton | Save all config, navigate `/home` |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_currentPage` | int | 0-3 |
| `_apiUrlController` | TextEditingController | Server URL |
| `_isTestingConnection` | bool | Connection test loading |
| `_connectionSuccess` | bool | Test result |
| `_connectionError` | String? | Test error |
| `_selectedAiProvider` | String | 'none', 'openai', 'anthropic' |
| `_openAiKeyController` | TextEditingController | OpenAI key |
| `_anthropicKeyController` | TextEditingController | Anthropic key |
| `_enableHealthKit` | bool | Health sync toggle |

---

### Screen: HomeScreen

**Package:** `home_dashboard_ui`
**Route:** `/home`
**Purpose:** Main dashboard with 4-tab navigation

#### Layout

```
┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │     SliverAppBar          │  │
│  │  Title: varies by tab     │  │
│  │  Actions: varies          │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │      IndexedStack         │  │
│  │    (4 tab contents)       │  │
│  │                           │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ [🏠] [📅]  [+]  [🚩] [👤] │  │
│  │      BottomAppBar         │  │
│  │   (notched for FAB)       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Bottom Navigation

| Index | Icon | Label |
|-------|------|-------|
| 0 | `home` | Home |
| 1 | `calendar_today` | Plan |
| FAB | `add` | Quick Log |
| 2 | `flag` | Goals |
| 3 | `person` | Profile |

#### Tab 0: Home Dashboard

**AppBar:** Title: "Workout-Planner", Action: `chat_bubble_outline` → ChatScreen

**Content:**

```
┌───────────────────────────────┐
│  Today's Card                 │
│  ┌─────────┬───────────────┐  │
│  │ Monday  │   Readiness   │  │
│  │ Jan 20  │     85%       │  │
│  │         │  [battery]    │  │
│  ├─────────┴───────────────┤  │
│  │ [Strength] [Run] chips  │  │
│  └─────────────────────────┘  │
├───────────────────────────────┤
│  Quick Stats Row              │
│  ┌────────┬────────┬───────┐  │
│  │ Sleep  │  HRV   │  RHR  │  │
│  │  7.5h  │   45   │   58  │  │
│  └────────┴────────┴───────┘  │
├───────────────────────────────┤
│  Today's Workout Card         │
│  ┌─────────────────────────┐  │
│  │ [💪]  Upper Body        │  │
│  │       Strength          │  │
│  │ Focus: Push             │  │
│  │ 60 min • Strength Goal  │  │
│  │ [Strength] [Push] chips │  │
│  │ "Focus on compound..."  │  │
│  └─────────────────────────┘  │
├───────────────────────────────┤
│  Tomorrow Preview             │
│  ┌─────────────────────────┐  │
│  │ [🛏️] Tomorrow          │  │
│  │      Rest • Recovery    │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
```

**Readiness Color Logic:**
- score >= 0.70: `success` (green)
- score >= 0.40: `warning` (orange)
- score < 0.40: `error` (red)

#### Tab 1: Weekly Plan

**AppBar:** Title: "Weekly Plan"

**Content:** WeeklyPlanPreview component

#### Tab 2: Goals

**AppBar:** Title: "Goals", Action: `add` → GoalsScreen

**Content:**
- Loading: `CircularProgressIndicator`
- Empty: "No goals yet" + "Create Goal" button
- Goals: `ListView` of goal cards

#### Tab 3: Profile

**AppBar:** Title: "Profile", Action: `logout`

**Content:**
- Profile header card (avatar, name, email, edit button)
- Settings list (Appearance, Sync Health Data, AI Coach)

#### Quick Log FAB

Opens `ModalBottomSheet`:

| Option | Icon | Navigation |
|--------|------|------------|
| Health Metrics | `favorite` | HealthMetricsScreen |
| Strength Workout | `fitness_center` | StrengthMetricsScreen |
| Swim Workout | `pool` | SwimMetricsScreen |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_currentIndex` | int | Selected tab (0-3) |
| `_goals` | List\<UserGoal\> | User's goals |
| `_readinessScore` | double | 0.0-1.0 |
| `_hrv` | double | Heart rate variability |
| `_sleepHours` | double | Sleep duration |
| `_restingHr` | int | Resting heart rate |
| `_weeklyPlan` | Map | Weekly plan data |
| `_dailyPlan` | Map | Today's plan |
| `_syncing` | bool | Health sync in progress |
| `_userId` | String | Current user ID |

---

### Screen: DayEditScreen

**Package:** `home_dashboard_ui`
**Purpose:** Edit a single day's workouts

#### Layout

```
┌─────────────────────────────────┐
│  ← Back              [Save ✓]   │
│  ┌───────────────────────────┐  │
│  │  Day Header               │  │
│  │  "Monday, January 20"     │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Title                    │  │
│  │  [Upper Body Day      ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Description              │  │
│  │  [Focus on pushing... ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Time Goal                │  │
│  │  [60 min              ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Goal (dropdown)          │  │
│  │  [Strength Goal ▼     ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  WORKOUTS (max 3)         │  │
│  │  ┌─────────────────────┐  │  │
│  │  │[≡] Strength  [✏][🗑]│  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │[≡] Cardio    [✏][🗑]│  │  │
│  │  └─────────────────────┘  │  │
│  │                           │  │
│  │  [ + Add Workout ]        │  │
│  │  (disabled if 3 workouts) │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Input Fields

| Field | Type | Properties |
|-------|------|------------|
| Title | TextField | Initial: day + date |
| Description | TextField | Multiline, optional |
| Time Goal | TextField | e.g., "60 min" |
| Goal | DropdownButtonFormField | User's active goals |

#### Workout List

- **Max:** 3 workouts per day
- **Reorderable:** Drag handle (≡)
- **Actions:** Edit (→ WorkoutDetailScreen), Delete

#### Actions

| Element | Action |
|---------|--------|
| Save (AppBar) | Save and return updated data |
| Add Workout | Open WorkoutSelectionDialog (disabled if 3) |
| Edit Workout | Navigate to WorkoutDetailScreen |
| Delete Workout | Remove from list |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_workouts` | List\<Map\> | Day's workouts |
| `_titleController` | TextEditingController | Day title |
| `_descriptionController` | TextEditingController | Description |
| `_timeGoalController` | TextEditingController | Time goal |
| `_selectedGoalId` | int? | Selected goal |
| `_goals` | List\<UserGoal\> | Available goals |
| `_hasChanges` | bool | Unsaved changes flag |

---

### Screen: WorkoutDetailScreen

**Package:** `todays_workout_ui`
**Purpose:** Create/edit workout with exercises

#### Layout

```
┌─────────────────────────────────┐
│  ← Back              [Save ✓]   │
│  ┌───────────────────────────┐  │
│  │  Workout Type             │  │
│  │  [💪 Strength ▼       ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Workout Name             │  │
│  │  [Upper Body Power    ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  WARMUP              [+]  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │[≡] Arm circles     │  │  │
│  │  │    20 reps    [✏🗑]│  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  MAIN SET            [+]  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │[≡] Bench Press     │  │  │
│  │  │    4x6 @ 185 lbs   │  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │[≡] Incline DB Press│  │  │
│  │  │    3x10 @ 50 lbs   │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  COOLDOWN            [+]  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │[≡] Stretch         │  │  │
│  │  │    300 sec         │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Notes                    │  │
│  │  [Focus on form...    ]   │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Workout Type Dropdown

| Type | Icon | Value |
|------|------|-------|
| Strength | `fitness_center` | 'strength' |
| Run | `directions_run` | 'run' |
| Swim | `pool` | 'swim' |
| Murph | `military_tech` | 'murph' |
| Bike | `directions_bike` | 'bike' |
| Yoga | `self_improvement` | 'yoga' |
| Cardio | `favorite` | 'cardio' |
| Mobility | `accessibility` | 'mobility' |
| Rest | `hotel` | 'rest' |

#### Exercise Dialog

| Field | Type | Shown For | Properties |
|-------|------|-----------|------------|
| Exercise Name | TextField | All | Required |
| Sets | TextField | Strength | Number keyboard |
| Reps | TextField | Strength | Number keyboard |
| Weight | TextField | Strength | Number keyboard |
| Weight Unit | Dropdown | Strength | lbs, kg |
| Distance | TextField | Cardio | Number keyboard |
| Distance Unit | Dropdown | Cardio | miles, km, meters, yards, laps |
| Duration | TextField | All | Seconds, number keyboard |
| Rest | TextField | All | Seconds, number keyboard |
| Notes | TextField | All | Max 2 lines |

#### Exercise Sections

| Section | Purpose | Add Button | Reorderable |
|---------|---------|------------|-------------|
| Warmup | Pre-workout | Yes | Yes |
| Main Set | Primary exercises | Yes | Yes |
| Cooldown | Post-workout | Yes | Yes |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_selectedType` | String | Workout type |
| `_nameController` | TextEditingController | Workout name |
| `_notesController` | TextEditingController | Notes |
| `_warmup` | List\<Exercise\> | Warmup exercises |
| `_main` | List\<Exercise\> | Main exercises |
| `_cooldown` | List\<Exercise\> | Cooldown exercises |
| `_hasChanges` | bool | Unsaved changes |

---

### Screen: GoalsScreen

**Package:** `goals_ui`
**Purpose:** View and manage fitness goals

#### Layout

```
┌─────────────────────────────────┐
│  ← Back        Your Goals       │
│  ┌───────────────────────────┐  │
│  │  Goal Card                │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ [🚩]  Running       │  │  │
│  │  │       Target: 5 km  │  │  │
│  │  │       By: 2026-06-01│  │  │
│  │  │  [2 plans]    [...] │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Goal Card                │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ [🚩]  Strength      │  │  │
│  │  │       Target: 315lbs│  │  │
│  │  │       By: 2026-12-31│  │  │
│  │  │  [1 plan]     [...] │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│                          [+]    │
│                          FAB    │
└─────────────────────────────────┘
```

#### Empty State

```
┌───────────────────────────────┐
│         [🚩] 64x64            │
│      "No goals yet"           │
│   bodyLarge, onSurface.60     │
│                               │
│   [ Create First Goal ]       │
│      ElevatedButton           │
└───────────────────────────────┘
```

#### Goal Card Structure

| Element | Content |
|---------|---------|
| Leading | Flag icon in primaryContainer circle |
| Title | goal.goalType (titleMedium) |
| Subtitle Line 1 | "Target: {targetValue} {targetUnit}" |
| Subtitle Line 2 | "By: {targetDate}" |
| Badge | "{count} plan(s)" in primary color |
| Trailing | PopupMenuButton |

#### Create/Edit Goal Dialog

| Field | Label | Type | Validation |
|-------|-------|------|------------|
| Goal Type | "Goal Type" | TextField | Required |
| Target Value | "Target Value (optional)" | TextField | None |
| Target Unit | "Target Unit (optional)" | TextField | None |
| Target Date | "Target Date (optional)" | TextField + DatePicker | Future date |
| Notes | "Notes (optional)" | TextField (3 lines) | None |

#### Actions

| Element | Type | Action |
|---------|------|--------|
| FAB | FloatingActionButton | Open create dialog |
| Goal Card | onTap | Navigate GoalPlansScreen |
| Edit Menu | PopupMenuItem | Open edit dialog |
| Delete Menu | PopupMenuItem | Confirm and delete |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_goals` | List\<UserGoal\> | User's goals |
| `_planCounts` | Map\<int, int\> | Goal ID → plan count |
| `_isLoading` | bool | Loading state |
| `_errorMessage` | String? | Error message |
| `_userId` | String? | Current user |

---

### Screen: GoalPlansScreen

**Package:** `goals_ui`
**Purpose:** View and manage sub-plans for a goal

#### Layout

```
┌─────────────────────────────────┐
│  ← Back   Plans for Running     │
│  ┌───────────────────────────┐  │
│  │  Plan Card                │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Week 1-4 Base       │  │  │
│  │  │ Build aerobic base  │  │  │
│  │  │ with easy runs... ▼ │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Plan Card                │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Week 5-8 Speed      │  │  │
│  │  │ Introduce interval  │  │  │
│  │  │ training...       ▼ │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│                          [+]    │
└─────────────────────────────────┘
```

#### Create/Edit Plan Dialog

| Field | Label | Type | Validation |
|-------|-------|------|------------|
| Plan Name | "Plan Name" | TextField | Required |
| Description | "Description" | TextField (3 lines) | None |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_plans` | List\<Map\> | Goal's plans |
| `_isLoading` | bool | Loading state |
| `_errorMessage` | String? | Error message |

---

### Screen: ChatScreen

**Package:** `ai_coach_chat`
**Purpose:** AI fitness coach conversation

#### Layout

```
┌─────────────────────────────────┐
│  ← Back    AI Fitness Coach [i] │
│  ┌───────────────────────────┐  │
│  │  [Error Banner if any]    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │     Message List          │  │
│  │                           │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ User message      ──┤  │  │
│  │  │ (right, primary)    │  │  │
│  │  │          Just now   │  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  ├── Assistant message │  │  │
│  │  │   (left, grey)      │  │  │
│  │  │   5m ago            │  │  │
│  │  └─────────────────────┘  │  │
│  │                           │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  [Ask your coach...] [➤] │  │
│  │  TextField + IconButton   │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Empty State

```
┌───────────────────────────────┐
│       [💬] 80x80              │
│  "Start a conversation!"      │
│   headlineMedium              │
│  "Ask me about training,      │
│   recovery, goals, or         │
│   anything fitness related."  │
│   bodyMedium                  │
│                               │
│  Suggestion Chips:            │
│  [What should I train today?] │
│  [How is my recovery?]        │
│  [Help me set a goal]         │
│  [Analyze my sleep]           │
└───────────────────────────────┘
```

#### Message Bubble Styles

| Type | Alignment | Background | Text | Border Radius |
|------|-----------|------------|------|---------------|
| User | Right | primary | onPrimary | 16, 16, 4, 16 |
| Assistant | Left | surfaceVariant | onSurface | 16, 16, 16, 4 |

**Timestamp:** Below message, bodySmall, relative format ("Just now", "5m ago", "2h ago")

#### Input Area

| Element | Type | Properties |
|---------|------|------------|
| TextField | TextField | hint: "Ask your coach...", borderRadius: 24, maxLines: null |
| Send Button | IconButton | icon: `send` (or CircularProgressIndicator when sending) |

#### Info Dialog (i button)

**Title:** "AI Fitness Coach"

**Content:** The AI coach has access to:
- Health metrics (HRV, heart rate, sleep)
- Training goals and progress
- Readiness scores
- Recent workout data

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_messages` | List\<ChatMessage\> | Chat messages |
| `_currentSessionId` | int? | Current session |
| `_isLoading` | bool | Initial load |
| `_isSending` | bool | Message sending |
| `_error` | String? | Error message |
| `_messageController` | TextEditingController | Input field |
| `_scrollController` | ScrollController | Auto-scroll |

---

### Screen: StrengthMetricsScreen

**Package:** `todays_workout_ui`
**Purpose:** Log strength training sets

#### Layout

```
┌─────────────────────────────────┐
│  ← Back   Log Strength    [📋] │
│  ┌───────────────────────────┐  │
│  │  Date                     │  │
│  │  [📅] January 20, 2026    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Lift Type                │  │
│  │  [Squat ▼             ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Weight (kg)              │  │
│  │  [185                 ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Reps                     │  │
│  │  [5                   ]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Set Number               │  │
│  │  [3                   ]   │  │
│  │  helper: "Which set..."   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Bar Velocity (m/s)       │  │
│  │  [0.8                 ]   │  │
│  │  helper: "Optional..."    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Estimated 1RM: 213 kg    │  │
│  │  Card, primary container  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │       [ Log Set ]         │  │
│  │      ElevatedButton       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Input Fields

| Field | Label | Type | Validation |
|-------|-------|------|------------|
| Date | Card with DatePicker | DatePicker | 365 days ago to today |
| Lift Type | "Lift Type" | Dropdown | Required |
| Weight | "Weight (kg)" | TextField (number) | Required |
| Reps | "Reps" | TextField (number) | Required |
| Set Number | "Set Number" | TextField (number) | Required |
| Bar Velocity | "Bar Velocity (m/s)" | TextField (decimal) | Optional |

#### Lift Type Options

- squat
- bench_press
- deadlift
- overhead_press
- front_squat
- power_clean
- snatch
- row
- pull_up

#### Calculated Display

**Estimated 1RM** (shown when weight and reps filled):
- Formula: `weight * (1 + reps / 30)`
- Display: primaryContainer card

#### History Modal (📋 button)

**Title:** "Recent Lifts"

| Format | Example |
|--------|---------|
| "{lift} • {weight}kg × {reps} • Set {set}" | "Squat • 185kg × 5 • Set 3" |
| "{date}" | "January 19, 2026" |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_selectedDate` | DateTime | Selected date |
| `_liftType` | String | Selected lift |
| `_weightController` | TextEditingController | Weight input |
| `_repsController` | TextEditingController | Reps input |
| `_setNumberController` | TextEditingController | Set number |
| `_velocityController` | TextEditingController | Bar velocity |
| `_formKey` | GlobalKey\<FormState\> | Form validation |

---

### Screen: SwimMetricsScreen

**Package:** `todays_workout_ui`
**Purpose:** Log swimming workouts

#### Layout

```
┌─────────────────────────────────┐
│  ← Back    Log Swim       [📋] │
│  ┌───────────────────────────┐  │
│  │  Date                     │  │
│  │  [📅] January 20, 2026    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Water Type               │  │
│  │  ○ Pool  ● Open Water     │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Distance (meters)        │  │
│  │  [1000               ]    │  │
│  │  helper: "e.g., 1000..."  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Avg Pace (sec/100m)      │  │
│  │  [95                 ]    │  │
│  │  helper: "(1:35 / 100m)"  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Stroke Rate (optional)   │  │
│  │  [                   ]    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Summary Card             │  │
│  │  Distance: 1000m          │  │
│  │  Pace: 1:35 / 100m        │  │
│  │  Total: 15:50             │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │       [ Log Swim ]        │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Input Fields

| Field | Label | Type | Validation |
|-------|-------|------|------------|
| Date | Card with DatePicker | DatePicker | 365 days ago to today |
| Water Type | Radio buttons | RadioListTile | 'pool' or 'open_water' |
| Distance | "Distance (meters)" | TextField (number) | Required |
| Average Pace | "Average Pace (seconds per 100m)" | TextField (number) | Required |
| Stroke Rate | "Stroke Rate (strokes per minute)" | TextField (number) | Optional |

#### Calculated Display

**Summary Card** (shown when distance and pace filled):

| Field | Calculation | Format |
|-------|-------------|--------|
| Distance | distance | "{distance}m" |
| Pace | pace | "M:SS / 100m" |
| Total Time | (distance/100) * pace | "M:SS" |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_selectedDate` | DateTime | Selected date |
| `_distanceController` | TextEditingController | Distance |
| `_avgPaceController` | TextEditingController | Pace |
| `_strokeRateController` | TextEditingController | Stroke rate |
| `_waterType` | String | 'pool' or 'open_water' |
| `_formKey` | GlobalKey\<FormState\> | Form validation |

---

### Screen: HealthMetricsScreen

**Package:** `readiness_ui`
**Purpose:** Log daily health metrics

#### Layout

```
┌─────────────────────────────────┐
│  ← Back   Health Metrics  [📋] │
│  ┌───────────────────────────┐  │
│  │  Date                     │  │
│  │  [📅] January 20, 2026    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  PHYSICAL METRICS         │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ HRV (ms)            │  │  │
│  │  │ [45                ]│  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Resting HR (bpm)    │  │  │
│  │  │ [58                ]│  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ VO2 Max (optional)  │  │  │
│  │  │ [                  ]│  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Sleep Hours         │  │  │
│  │  │ [7.5               ]│  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Weight (optional)   │  │  │
│  │  │ [                  ]│  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  SUBJECTIVE RATINGS       │  │
│  │                           │  │
│  │  RPE (1-10)               │  │
│  │  [1]═══════●═══════[10]   │  │
│  │  helper: "How hard..."    │  │
│  │                           │  │
│  │  Soreness (1-10)          │  │
│  │  [1]═══●═══════════[10]   │  │
│  │  helper: "Overall..."     │  │
│  │                           │  │
│  │  Mood (1-10)              │  │
│  │  [1]═══════════●═══[10]   │  │
│  │  helper: "Overall..."     │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │     [ Save Metrics ]      │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Input Fields - Physical

| Field | Label | Helper | Type | Validation |
|-------|-------|--------|------|------------|
| Date | DatePicker card | - | DatePicker | 365 days ago to today |
| HRV | "HRV (ms)" | "Heart Rate Variability" | TextField (number) | None |
| Resting HR | "Resting Heart Rate (bpm)" | - | TextField (number) | None |
| VO2 Max | "VO2 Max (ml/kg/min)" | "Optional" | TextField (decimal) | None |
| Sleep Hours | "Sleep Hours" | - | TextField (decimal) | None |
| Weight | "Weight (kg)" | "Optional" | TextField (decimal) | None |

#### Input Fields - Subjective

| Field | Label | Helper | Range | Default |
|-------|-------|--------|-------|---------|
| RPE | "RPE" | "How hard did yesterday feel?" | 1-10 | 5 |
| Soreness | "Soreness" | "Overall muscle soreness" | 1-10 | 5 |
| Mood | "Mood" | "Overall mood and energy" | 1-10 | 5 |

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `_selectedDate` | DateTime | Selected date |
| `_hrvController` | TextEditingController | HRV input |
| `_restingHrController` | TextEditingController | RHR input |
| `_vo2maxController` | TextEditingController | VO2 Max |
| `_sleepHoursController` | TextEditingController | Sleep |
| `_weightKgController` | TextEditingController | Weight |
| `_rpe` | int | RPE rating (1-10) |
| `_soreness` | int | Soreness rating |
| `_mood` | int | Mood rating |
| `_formKey` | GlobalKey\<FormState\> | Form validation |

---

### Screen: ProfileScreen

**Package:** `settings_profile_ui`
**Purpose:** User profile and app configuration

#### Layout

```
┌─────────────────────────────────┐
│  ← Back        Profile          │
│  ┌───────────────────────────┐  │
│  │  PERSONAL INFO            │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Name                │  │  │
│  │  │ [Shawn Rummel     ] │  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Age                 │  │  │
│  │  │ [35                ]│  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Weight (lbs)        │  │  │
│  │  │ [185               ]│  │  │
│  │  └─────────────────────┘  │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Height (inches)     │  │  │
│  │  │ [72                ]│  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  APPEARANCE               │  │
│  │  🌙 Dark Mode        [◉]  │  │
│  │  SwitchListTile           │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  CONFIGURATION            │  │
│  │  🖥️ API Server      [✏]  │  │
│  │     https://api.ex...     │  │
│  │  🧠 AI Provider     [▼]   │  │
│  │     OpenAI                │  │
│  │  🔑 OpenAI Key      [✏]  │  │
│  │     sk-...xxxx            │  │
│  │  🔑 Anthropic Key   [✏]  │  │
│  │     Not configured        │  │
│  │  ❤️ HealthKit Sync  [◉]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  DIAGNOSTICS (if errors)  │  │
│  │  Warning card with errors │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │       [ Save ]            │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### Personal Info Fields

| Field | Label | Type | Storage |
|-------|-------|------|---------|
| Name | "Name" | TextField | SharedPreferences |
| Age | "Age" | TextField (number) | SharedPreferences |
| Weight | "Weight (lbs)" | TextField (number) | SharedPreferences |
| Height | "Height (inches)" | TextField (number) | SharedPreferences |

#### Configuration Settings

| Setting | Type | Storage |
|---------|------|---------|
| Dark Mode | SwitchListTile | ThemeController |
| API Server | ListTile + Edit Dialog | SecureStorage |
| AI Provider | ListTile + Dropdown | SecureStorage |
| OpenAI Key | ListTile + Edit Dialog | SecureStorage (masked) |
| Anthropic Key | ListTile + Edit Dialog | SecureStorage (masked) |
| HealthKit Sync | SwitchListTile | SecureStorage |

#### Diagnostics Section

Shown when `healthError` or `syncError` is present:
- Warning card (warning background color)
- Error details
- Common causes and solutions list

#### State

| Variable | Type | Description |
|----------|------|-------------|
| `nameCtrl` | TextEditingController | Name input |
| `ageCtrl` | TextEditingController | Age input |
| `weightCtrl` | TextEditingController | Weight input |
| `heightCtrl` | TextEditingController | Height input |
| `_loading` | bool | Initial load |
| `_saving` | bool | Save in progress |
| `_themeMode` | String | 'light' or 'dark' |
| `_apiBaseUrl` | String? | API server URL |
| `_aiProvider` | String? | 'openai' or 'anthropic' |
| `_maskedOpenAiKey` | String? | Masked API key |
| `_maskedAnthropicKey` | String? | Masked API key |
| `_healthKitEnabled` | bool | HealthKit toggle |
| `_configuredAt` | DateTime? | Config timestamp |

---

## Use Cases

### UC-001: Create Workout Goal

**Actor:** User

**Preconditions:** User is authenticated

**Flow:**
1. User navigates to Goals tab
2. User taps FAB or "Create Goal" button
3. System displays goal creation dialog
4. User enters goal type (required), target value, unit, date, notes
5. User taps "Create"
6. System validates input (goal type required, date in future)
7. System calls `POST /goals` with goal data
8. System displays new goal in list
9. System shows success feedback

**Acceptance Criteria:**
- [x] Goal type field is required
- [x] Target date must be in the future (if provided)
- [x] Goal is associated with authenticated user
- [x] Goal appears in list immediately after creation

### UC-002: Plan Weekly Workouts

**Actor:** User

**Preconditions:** User is authenticated

**Flow:**
1. User navigates to Plan tab
2. System displays current week's plan
3. User taps a day to edit
4. System navigates to DayEditScreen
5. User adds/edits workouts (max 3 per day)
6. User taps Save
7. System validates (max 3 workouts)
8. System calls `PUT /daily-plans/{user_id}/{date}`
9. System returns to weekly view with updated data

**Acceptance Criteria:**
- [x] Plan displays all 7 days of current week
- [x] Maximum 3 workouts per day enforced
- [x] Add Workout button disabled when 3 workouts exist
- [x] Changes persist after save

### UC-003: Log Strength Workout

**Actor:** User

**Preconditions:** User is authenticated

**Flow:**
1. User taps Quick Log FAB → Strength
2. System navigates to StrengthMetricsScreen
3. User selects date (default: today)
4. User selects lift type from dropdown
5. User enters weight, reps, set number
6. System calculates and displays estimated 1RM
7. User optionally enters bar velocity
8. User taps "Log Set"
9. System validates required fields
10. System calls `POST /strength` with metrics
11. System shows success feedback

**Acceptance Criteria:**
- [x] 1RM calculated using Epley formula
- [x] Weight, reps, set number are required
- [x] Date range limited to past 365 days
- [x] Historical lifts viewable via history button

### UC-004: Chat with AI Coach

**Actor:** User

**Preconditions:** User is authenticated, AI provider configured

**Flow:**
1. User taps AI Coach icon from Home tab
2. System navigates to ChatScreen
3. System loads existing session (if any)
4. User types message or taps suggestion chip
5. User taps send button
6. System shows sending indicator
7. System calls `POST /chat/messages` with message
8. Backend retrieves user context (goals, health, readiness)
9. AI generates personalized response
10. System displays response in chat
11. System stores message in session

**Acceptance Criteria:**
- [x] AI has access to user's fitness data
- [x] Responses are contextually relevant
- [x] Conversation history preserved across sessions
- [x] Empty state shows suggestion chips

### UC-005: Sync Health Data

**Actor:** User

**Preconditions:** User is authenticated, HealthKit enabled

**Flow:**
1. User enables HealthKit in setup wizard or profile
2. System requests HealthKit permissions
3. User grants permissions
4. System fetches health samples (HRV, HR, sleep)
5. System transforms data to API format
6. System calls `POST /health/samples` with batch
7. Backend deduplicates by source_uuid
8. Backend stores new samples
9. System recalculates readiness score
10. System updates dashboard display

**Acceptance Criteria:**
- [x] Only requests necessary HealthKit permissions
- [x] Duplicates not stored (deduplication by source_uuid)
- [x] Readiness score updates after sync
- [x] Sync can be triggered manually from profile

### UC-006: View Readiness Score

**Actor:** User

**Preconditions:** User is authenticated, has health data

**Flow:**
1. User opens app to Home tab
2. System fetches latest health samples
3. System calculates readiness score
4. System displays score with color coding
5. System shows quick stats (sleep, HRV, RHR)
6. System identifies limiting factor

**Acceptance Criteria:**
- [x] Score displayed as percentage (0-100%)
- [x] Color coding: green ≥70%, orange 40-69%, red <40%
- [x] Quick stats show actual values
- [x] Limiting factor visible in detailed view

---

## Implementation Status

### Data Models

| Model | Status | Notes |
|-------|--------|-------|
| User | ✅ Implemented | Full auth system |
| UserGoal | ✅ Implemented | CRUD operations |
| GoalPlan | ✅ Implemented | Goal sub-plans |
| HealthSample | ✅ Implemented | Bulk ingest |
| DailyPlan | ✅ Implemented | JSON workout storage |
| WeeklyPlan | ✅ Implemented | 7-day planning |
| Exercise | ✅ Implemented | Full model with units |
| StrengthMetrics | ✅ Implemented | 1RM calculation |
| SwimMetrics | ✅ Implemented | Pace tracking |
| MurphMetrics | ✅ Implemented | Partition support |
| ChatSession | ✅ Implemented | Conversation storage |
| ChatMessage | ✅ Implemented | AI integration |

### UI Screens

| Screen | Status | Package |
|--------|--------|---------|
| WelcomeScreen | ✅ Implemented | home_dashboard_ui |
| LoginScreen | ✅ Implemented | home_dashboard_ui |
| RegisterScreen | ✅ Implemented | home_dashboard_ui |
| SetupWizardScreen | ✅ Implemented | home_dashboard_ui |
| HomeScreen | ✅ Implemented | home_dashboard_ui |
| DayEditScreen | ✅ Implemented | home_dashboard_ui |
| WorkoutDetailScreen | ✅ Implemented | todays_workout_ui |
| GoalsScreen | ✅ Implemented | goals_ui |
| GoalPlansScreen | ✅ Implemented | goals_ui |
| ChatScreen | ✅ Implemented | ai_coach_chat |
| StrengthMetricsScreen | ✅ Implemented | todays_workout_ui |
| SwimMetricsScreen | ✅ Implemented | todays_workout_ui |
| HealthMetricsScreen | ✅ Implemented | readiness_ui |
| ProfileScreen | ✅ Implemented | settings_profile_ui |

### Integrations

| Integration | Status | Notes |
|-------------|--------|-------|
| HealthKit (iOS) | ✅ Implemented | HRV, HR, sleep |
| Google Fit | 🚧 Partial | Basic support |
| OpenAI GPT | ✅ Implemented | AI coach |
| Anthropic Claude | ✅ Implemented | Alt AI provider |

### Authentication

| Component | Status | Notes |
|-----------|--------|-------|
| AWS Amplify Integration | ⬜ Planned | Migrating from custom JWT |
| Shared auth_ui Package | ⬜ Planned | Replacing existing login screens |
| Token Validation | 🚧 Partial | Existing JWT, migrating to Cognito |
| Module Access Control | ⬜ Planned | Replacing registration codes |

**Legend:** ✅ Implemented | 🚧 Partial | ⬜ Planned

---

## Technical Notes

### Backend (External)

- **Framework:** FastAPI
- **Database:** SQLite (dev) / PostgreSQL (prod)
- **Auth:** JWT with refresh tokens (migrating to AWS Cognito)
- **AI:** OpenAI GPT-4o-mini / Anthropic Claude
- **Repository:** Separate services repo

### Frontend

- **Framework:** Flutter 3.x (iOS, Android, Web, macOS, Linux)
- **Architecture:** Multi-package monorepo
- **State:** StatefulWidget + service classes (no external state management)
- **Storage:** FlutterSecureStorage + SharedPreferences
- **Health:** HealthKit bridge via MethodChannel (iOS/macOS)
- **Theme:** Material 3 with custom RummelBlueTheme

### Key Implementation Details

- Registration requires invite codes (migrating to Amplify access control)
- Readiness score cached for 5 minutes
- Health sync deduplicates by source_uuid
- Chat context includes user goals + health summary
- 1RM uses Epley formula: `weight * (1 + reps / 30)`
- Maximum 3 workouts per day
- Offline-first with local storage fallback
- Platform-specific API defaults (localhost for web/iOS, 10.0.2.2 for Android emulator)

---

*Last updated: 2026-01-20*
*Version: 2.0.0*
