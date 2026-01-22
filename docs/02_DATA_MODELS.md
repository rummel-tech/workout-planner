# Workout Planner - Data Models

**Version:** 1.0
**Last Updated:** 2024-12-24

---

## Overview

This document defines all data models used in the Workout Planner system. Models are shown in JSON Schema format with SQL table definitions where applicable.

## Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    users     │───────│  user_goals  │───────│  goal_plans  │
└──────┬───────┘       └──────────────┘       └──────────────┘
       │
       ├───────────────┬───────────────┬───────────────┐
       │               │               │               │
       ▼               ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│health_samples│ │health_metrics│ │ daily_plans  │ │ weekly_plans │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
       │
       ├───────────────┬───────────────┐
       │               │               │
       ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   strength   │ │     swim     │ │    murph     │
└──────────────┘ └──────────────┘ └──────────────┘

┌──────────────┐       ┌──────────────┐
│chat_sessions │───────│chat_messages │
└──────────────┘       └──────────────┘

┌──────────────┐       ┌──────────────┐
│registration_ │       │   waitlist   │
│    codes     │       │              │
└──────────────┘       └──────────────┘
```

---

## Core Models

### User

Represents an authenticated user account.

**JSON Schema:**
```json
{
  "id": "string (UUID)",
  "email": "string (unique)",
  "hashed_password": "string",
  "full_name": "string | null",
  "is_active": "boolean (default: true)",
  "is_admin": "boolean (default: false)",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    hashed_password TEXT NOT NULL,
    full_name TEXT,
    is_active INTEGER DEFAULT 1,
    is_admin INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Example:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Doe",
  "is_active": true,
  "is_admin": false,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

---

### User Goal

Represents a fitness goal set by the user.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "goal_type": "string",
  "target_value": "float",
  "target_unit": "string",
  "target_date": "date (ISO format)",
  "notes": "string | null",
  "is_active": "boolean (default: true)",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE user_goals (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    goal_type TEXT NOT NULL,
    target_value REAL,
    target_unit TEXT,
    target_date TEXT,
    notes TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Goal Types:**
| Type | Description | Example Target |
|------|-------------|----------------|
| Running | Distance or time goals | 5 km, 30 minutes |
| Strength | Lift weight goals | 300 lbs (deadlift) |
| Swimming | Distance or pace | 1000 m, 2:00/100m |
| Weight Loss | Body weight target | 180 lbs |
| Endurance | Duration goals | 60 min run |
| Murph | Murph completion time | < 45 minutes |

**Example:**
```json
{
  "id": 1,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "goal_type": "Strength",
  "target_value": 315.0,
  "target_unit": "lbs",
  "target_date": "2024-06-01",
  "notes": "Deadlift 3 plates",
  "is_active": true,
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

### Goal Plan

A plan associated with a specific goal.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "goal_id": "integer (FK → user_goals)",
  "user_id": "string",
  "name": "string",
  "description": "string | null",
  "status": "string (default: 'active')",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE goal_plans (
    id SERIAL PRIMARY KEY,
    goal_id INTEGER NOT NULL,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Health Models

### Health Sample

Raw health data samples from HealthKit or manual entry.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "sample_type": "string",
  "value": "float",
  "unit": "string",
  "start_time": "timestamp (ISO8601)",
  "end_time": "timestamp (ISO8601)",
  "source_app": "string | null",
  "source_uuid": "string | null",
  "created_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE health_samples (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    sample_type TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT,
    start_time TEXT NOT NULL,
    end_time TEXT,
    source_app TEXT,
    source_uuid TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, sample_type, start_time, source_uuid)
);
```

**Sample Types:**
| Type | Unit | Description |
|------|------|-------------|
| `hrv` | ms | Heart Rate Variability (SDNN) |
| `resting_hr` | bpm | Resting Heart Rate |
| `heart_rate` | bpm | Heart Rate sample |
| `sleep_stage` | hours | Sleep duration |
| `workout_distance` | meters | Workout distance |
| `workout_calories` | kcal | Calories burned |
| `vo2max` | mL/kg/min | VO2 Max estimate |
| `weight` | kg | Body weight |

**Example:**
```json
{
  "id": 12345,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "sample_type": "hrv",
  "value": 45.5,
  "unit": "ms",
  "start_time": "2024-01-15T06:30:00Z",
  "end_time": "2024-01-15T06:30:00Z",
  "source_app": "com.apple.health",
  "source_uuid": "abc123-def456"
}
```

---

### Health Metrics

Aggregated daily health metrics (manual entry or derived).

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "date": "date (ISO format)",
  "hrv_ms": "float | null",
  "resting_hr": "integer | null",
  "vo2max": "float | null",
  "sleep_hours": "float | null",
  "weight_kg": "float | null",
  "rpe": "integer (1-10) | null",
  "soreness": "integer (1-10) | null",
  "mood": "integer (1-10) | null",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE health_metrics (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    hrv_ms REAL,
    resting_hr INTEGER,
    vo2max REAL,
    sleep_hours REAL,
    weight_kg REAL,
    rpe INTEGER,
    soreness INTEGER,
    mood INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);
```

**Example:**
```json
{
  "id": 100,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2024-01-15",
  "hrv_ms": 48.2,
  "resting_hr": 58,
  "vo2max": 42.5,
  "sleep_hours": 7.5,
  "weight_kg": 82.1,
  "rpe": 6,
  "soreness": 4,
  "mood": 7
}
```

---

## Planning Models

### Daily Plan

Workout plan for a specific day.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "date": "date (ISO format)",
  "workouts": [
    {
      "name": "string",
      "type": "workout_type",
      "focus": "string | null",
      "time_goal": "string | null",
      "warmup": ["exercise"],
      "main": ["exercise"],
      "cooldown": ["exercise"],
      "notes": "string | null",
      "status": "pending | complete | skipped"
    }
  ],
  "ai_notes": "string | null",
  "status": "string (default: 'pending')",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**Workout Types:**
```
strength | run | swim | murph | mobility | bike | yoga | cardio | rest
```

**Exercise Object:**
```json
{
  "name": "string",
  "sets": "integer | null",
  "reps": "integer | null",
  "weight": "float | null",
  "weightUnit": "lbs | kg",
  "duration": "integer | null (seconds)",
  "rest": "integer | null (seconds between sets)",
  "distance": "float | null",
  "distanceUnit": "miles | km | meters | yards | laps",
  "notes": "string | null"
}
```

**Unit Normalization:**

Weight and distance units are automatically normalized when parsing from JSON to ensure consistent values:

**Weight Unit Normalization:**
| Input Values | Normalized To |
|--------------|---------------|
| `kg`, `kgs`, `kilogram`, `kilograms` | `kg` |
| `lbs`, `lb`, `pound`, `pounds` | `lbs` |
| Empty or null | `lbs` (default) |
| Invalid values | `lbs` (default) |

**Distance Unit Normalization:**
| Input Values | Normalized To |
|--------------|---------------|
| `mi`, `mile`, `miles` | `miles` |
| `km`, `kilometer`, `kilometers` | `km` |
| `m`, `meter`, `meters`, `metre`, `metres` | `meters` |
| `yd`, `yard`, `yards` | `yards` |
| `lap`, `laps` | `laps` |
| Empty or null | `miles` (default) |
| Invalid values | `miles` (default) |

**Note:** All unit matching is case-insensitive and trimmed. The normalization ensures dropdown validation works correctly in the UI by converting various user-friendly input formats to standard values.

**SQL Definition:**
```sql
CREATE TABLE daily_plans (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    plan_json TEXT NOT NULL,  -- JSON with workouts array
    status TEXT DEFAULT 'pending',
    ai_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);
```

**Example:**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2024-01-15",
  "workouts": [
    {
      "name": "Upper Body Strength",
      "type": "strength",
      "focus": "Push",
      "time_goal": "60 min",
      "warmup": [
        {"exercise": "Arm circles", "reps": 20},
        {"exercise": "Band pull-aparts", "sets": 2, "reps": 15}
      ],
      "main": [
        {"exercise": "Bench Press", "sets": 4, "reps": 6, "weight": 185},
        {"exercise": "Overhead Press", "sets": 3, "reps": 8, "weight": 95},
        {"exercise": "Dips", "sets": 3, "reps": 12}
      ],
      "cooldown": [
        {"exercise": "Chest stretch", "duration": "30s"},
        {"exercise": "Shoulder stretch", "duration": "30s"}
      ],
      "notes": "Focus on controlled eccentric",
      "status": "pending"
    }
  ],
  "ai_notes": "Readiness at 75% - good day for intensity"
}
```

---

### Weekly Plan

High-level weekly workout schedule.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "week_start": "date (Monday, ISO format)",
  "focus": "hybrid | strength | cardio | swimming",
  "days": [
    {
      "day": "Monday | Tuesday | ... | Sunday",
      "type": "workout_type",
      "focus": "string | null",
      "time_goal": "string | null"
    }
  ],
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE weekly_plans (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    week_start TEXT NOT NULL,
    focus TEXT,
    plan_json TEXT NOT NULL,  -- JSON with days array
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, week_start)
);
```

**Example:**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "week_start": "2024-01-15",
  "focus": "hybrid",
  "days": [
    {"day": "Monday", "type": "strength", "focus": "Upper Push"},
    {"day": "Tuesday", "type": "swim", "focus": "Endurance"},
    {"day": "Wednesday", "type": "mobility", "focus": "Recovery"},
    {"day": "Thursday", "type": "run", "focus": "Zone 2"},
    {"day": "Friday", "type": "strength", "focus": "Lower"},
    {"day": "Saturday", "type": "murph", "focus": "Murph Prep"},
    {"day": "Sunday", "type": "rest"}
  ]
}
```

---

## Workout Logging Models

### Strength Metrics

Individual strength training sets.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "date": "date (ISO format)",
  "lift": "string",
  "weight": "float",
  "reps": "integer",
  "set_number": "integer",
  "estimated_1rm": "float | null",
  "velocity_m_per_s": "float | null",
  "created_at": "timestamp"
}
```

**Lift Types:**
```
Bench Press | Squat | Deadlift | Overhead Press | Barbell Row |
Pull-ups | Dips | Lunges | Romanian Deadlift | Front Squat
```

**1RM Calculation (Epley Formula):**
```
estimated_1rm = weight × (1 + reps / 30)
```

**Example:**
```json
{
  "id": 500,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2024-01-15",
  "lift": "Deadlift",
  "weight": 275.0,
  "reps": 5,
  "set_number": 3,
  "estimated_1rm": 320.8,
  "velocity_m_per_s": 0.45
}
```

---

### Swim Metrics

Swimming workout data.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "workout_id": "integer | null",
  "date": "date (ISO format)",
  "distance_meters": "float",
  "duration_seconds": "integer",
  "avg_pace_seconds": "float",
  "stroke_rate": "float | null",
  "stroke_type": "string | null",
  "water_type": "pool | ocean | river",
  "created_at": "timestamp"
}
```

**Stroke Types:**
```
freestyle | backstroke | breaststroke | butterfly | mixed
```

**Example:**
```json
{
  "id": 200,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2024-01-15",
  "distance_meters": 1500.0,
  "duration_seconds": 1800,
  "avg_pace_seconds": 120.0,
  "stroke_rate": 28.5,
  "stroke_type": "freestyle",
  "water_type": "pool"
}
```

---

### Murph Metrics

Murph workout performance data.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "workout_id": "integer | null",
  "date": "date (ISO format)",
  "run_1_time_seconds": "integer",
  "run_2_time_seconds": "integer",
  "partition": "20-10-5 | singles | unpartitioned",
  "total_time_seconds": "integer",
  "vest_weight": "float | null",
  "notes": "string | null",
  "created_at": "timestamp"
}
```

**Murph Structure:**
```
1 mile run
100 pull-ups
200 push-ups
300 squats
1 mile run
(Optional: 20 lb vest)
```

**Partition Schemes:**
| Scheme | Description |
|--------|-------------|
| `20-10-5` | 20 rounds of 5 pull-ups, 10 push-ups, 15 squats |
| `singles` | All pull-ups, then all push-ups, then all squats |
| `unpartitioned` | Mix as needed |

**Example:**
```json
{
  "id": 50,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2024-01-15",
  "run_1_time_seconds": 480,
  "run_2_time_seconds": 540,
  "partition": "20-10-5",
  "total_time_seconds": 2700,
  "vest_weight": 20.0,
  "notes": "PR attempt, good pacing"
}
```

---

## Chat Models

### Chat Session

A conversation session with the AI coach.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "user_id": "string",
  "title": "string | null",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE chat_sessions (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### Chat Message

Individual messages in a chat session.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "session_id": "integer (FK → chat_sessions)",
  "user_id": "string",
  "role": "user | assistant",
  "content": "string",
  "metadata": {
    "model": "string | null",
    "tokens": "integer | null",
    "context_summary": "string | null"
  },
  "created_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE chat_messages (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata TEXT,  -- JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Example:**
```json
{
  "id": 1000,
  "session_id": 42,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "user",
  "content": "Should I do a hard workout today?",
  "metadata": null,
  "created_at": "2024-01-15T10:30:00Z"
}
```

```json
{
  "id": 1001,
  "session_id": 42,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "assistant",
  "content": "Based on your readiness score of 72% and good HRV, today would be a good day for moderate intensity...",
  "metadata": {
    "model": "gpt-4o-mini",
    "tokens": 245,
    "context_summary": "User has 2 active goals. Readiness: 72%"
  },
  "created_at": "2024-01-15T10:30:05Z"
}
```

---

## Access Control Models

### Registration Code

Codes for controlled user registration.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "code": "string (unique)",
  "is_used": "boolean (default: false)",
  "used_by_user_id": "string | null",
  "expires_at": "timestamp | null",
  "distributed_to": "string (email) | null",
  "distributed_at": "timestamp | null",
  "distributed_by_user_id": "string | null",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE registration_codes (
    id SERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    is_used INTEGER DEFAULT 0,
    used_by_user_id TEXT,
    expires_at TIMESTAMP,
    distributed_to TEXT,
    distributed_at TIMESTAMP,
    distributed_by_user_id TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### Waitlist

Users waiting for registration access.

**JSON Schema:**
```json
{
  "id": "integer (auto)",
  "email": "string (unique)",
  "created_at": "timestamp"
}
```

**SQL Definition:**
```sql
CREATE TABLE waitlist (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Derived/Computed Models

### Readiness Score

Computed from health data, not stored directly.

**JSON Schema:**
```json
{
  "user_id": "string",
  "score": "float (0.0 - 1.0)",
  "hrv_score": "float",
  "rhr_score": "float",
  "sleep_score": "float",
  "limiting_factor": "string | null",
  "computed_at": "timestamp"
}
```

**Calculation:**
```
score = (hrv_score × 0.4) + (rhr_score × 0.3) + (sleep_score × 0.3)

hrv_score = current_hrv / baseline_hrv (14-day average)
rhr_score = baseline_rhr / current_rhr (inverted)
sleep_score = sleep_hours / 8.0
```

---

### User Context (AI Chat)

Context object built for AI responses.

**JSON Schema:**
```json
{
  "user_id": "string",
  "goals": ["goal objects"],
  "recent_health": {
    "hrv": {"avg": "float", "count": "int", "unit": "string"},
    "resting_hr": {"avg": "float", "count": "int", "unit": "string"},
    "sleep": {"avg": "float", "count": "int", "unit": "string"}
  },
  "readiness": "float (0.0 - 1.0)",
  "summary": "string"
}
```
