# Workout Planner - API Specification

**Version:** 1.0
**Last Updated:** 2024-12-24
**Base URL:** `http://localhost:8000` (development)

---

## Overview

The Workout Planner API is a RESTful service built with FastAPI. All endpoints return JSON responses and use standard HTTP status codes.

### Authentication

Most endpoints require Bearer token authentication:
```
Authorization: Bearer <access_token>
```

### Common Response Formats

**Success Response:**
```json
{
  "data": { ... },
  "message": "Success"
}
```

**Error Response:**
```json
{
  "detail": "Error message",
  "error_code": "ERROR_CODE",
  "request_id": "uuid"
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Rate Limited |
| 500 | Server Error |

---

## Health & Status

### GET /health
Basic liveness probe.

**Auth Required:** No

**Response:**
```json
{"status": "ok"}
```

---

### GET /ready
Readiness probe with dependency checks.

**Auth Required:** No

**Response:**
```json
{
  "status": "ok",
  "db": "ok",
  "redis": "ok"
}
```

---

### GET /metrics
Prometheus metrics endpoint.

**Auth Required:** No

**Response:** Prometheus text format

---

## Authentication

### POST /auth/register
Create a new user account.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "full_name": "John Doe",
  "registration_code": "ABC123"
}
```

**Response (201):**
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

**Response (201 - Waitlisted):**
```json
{
  "status": "waitlisted",
  "email": "user@example.com",
  "message": "Added to waitlist"
}
```

---

### POST /auth/login
Authenticate and receive tokens.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

---

### POST /auth/refresh
Get new access token using refresh token.

**Auth Required:** Bearer (refresh token)

**Response:**
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer"
}
```

---

### POST /auth/logout
Invalidate current token.

**Auth Required:** Bearer

**Response:**
```json
{"message": "Logged out successfully"}
```

---

### GET /auth/me
Get current user info.

**Auth Required:** Bearer

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "is_active": true,
  "is_admin": false
}
```

---

### POST /auth/validate-code
Validate registration code without using it.

**Auth Required:** No

**Request Body:**
```json
{
  "code": "ABC123"
}
```

**Response:**
```json
{
  "valid": true,
  "expires_at": "2024-12-31T23:59:59Z"
}
```

---

## Goals

### GET /goals
List user's fitness goals.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required if not in token |
| active_only | boolean | Filter to active goals (default: true) |

**Response:**
```json
[
  {
    "id": 1,
    "user_id": "uuid",
    "goal_type": "Strength",
    "target_value": 315.0,
    "target_unit": "lbs",
    "target_date": "2024-06-01",
    "notes": "Deadlift goal",
    "is_active": true,
    "plan_count": 2
  }
]
```

---

### POST /goals
Create a new goal.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "user_id": "uuid",
  "goal_type": "Running",
  "target_value": 5.0,
  "target_unit": "km",
  "target_date": "2024-03-01",
  "notes": "5K race prep"
}
```

**Response (201):**
```json
{
  "id": 5,
  "user_id": "uuid",
  "goal_type": "Running",
  "target_value": 5.0,
  "target_unit": "km",
  "target_date": "2024-03-01",
  "notes": "5K race prep",
  "is_active": true
}
```

---

### GET /goals/{goal_id}
Get specific goal.

**Auth Required:** Bearer

**Response:**
```json
{
  "id": 1,
  "user_id": "uuid",
  "goal_type": "Strength",
  "target_value": 315.0,
  "target_unit": "lbs",
  "target_date": "2024-06-01",
  "notes": "Deadlift goal",
  "is_active": true
}
```

---

### PUT /goals/{goal_id}
Update a goal.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "target_value": 335.0,
  "notes": "Updated target"
}
```

**Response:**
```json
{
  "id": 1,
  "target_value": 335.0,
  "notes": "Updated target",
  ...
}
```

---

### DELETE /goals/{goal_id}
Deactivate a goal (soft delete).

**Auth Required:** Bearer

**Response:**
```json
{"message": "Goal deactivated"}
```

---

### GET /goals/{goal_id}/plans
Get plans for a goal.

**Auth Required:** Bearer

**Response:**
```json
[
  {
    "id": 1,
    "goal_id": 1,
    "name": "12-Week Program",
    "description": "Progressive overload plan",
    "status": "active"
  }
]
```

---

## Health Data

### POST /health/samples
Bulk ingest health samples.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "user_id": "uuid",
  "samples": [
    {
      "sample_type": "hrv",
      "value": 45.5,
      "unit": "ms",
      "start_time": "2024-01-15T06:30:00Z",
      "end_time": "2024-01-15T06:30:00Z",
      "source_app": "com.apple.health",
      "source_uuid": "abc123"
    }
  ]
}
```

**Response:**
```json
{
  "inserted": 50,
  "duplicates": 5,
  "errors": 0
}
```

---

### GET /health/samples
List health samples.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |
| sample_type | string | Filter by type |
| start_time | string | ISO timestamp |
| end_time | string | ISO timestamp |
| limit | int | Max results (default: 100) |

**Response:**
```json
[
  {
    "id": 1,
    "sample_type": "hrv",
    "value": 45.5,
    "unit": "ms",
    "start_time": "2024-01-15T06:30:00Z"
  }
]
```

---

### GET /health/summary
Get aggregated health summary.

**Auth Required:** Bearer
**Cached:** 5 minutes

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |
| days | int | Lookback days (default: 7) |

**Response:**
```json
{
  "user_id": "uuid",
  "period_days": 7,
  "metrics": {
    "hrv": {"avg": 48.2, "min": 35.0, "max": 62.0, "count": 7},
    "resting_hr": {"avg": 58.5, "min": 55, "max": 62, "count": 7},
    "sleep_hours": {"avg": 7.2, "min": 5.5, "max": 8.5, "count": 7}
  }
}
```

---

### GET /health/trends
Get health metric trends.

**Auth Required:** Bearer
**Cached:** 10 minutes

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |
| metric | string | hrv, resting_hr, sleep |
| days | int | Lookback days (default: 30) |

**Response:**
```json
{
  "metric": "hrv",
  "period_days": 30,
  "data": [
    {"date": "2024-01-01", "value": 45.2},
    {"date": "2024-01-02", "value": 48.1}
  ],
  "trend": "improving"
}
```

---

## Readiness

### GET /readiness
Get readiness score.

**Auth Required:** Bearer
**Cached:** 5 minutes

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |

**Response:**
```json
{
  "user_id": "uuid",
  "score": 0.72,
  "components": {
    "hrv_score": 0.85,
    "rhr_score": 0.65,
    "sleep_score": 0.68
  },
  "limiting_factor": "resting_hr",
  "recommendation": "Moderate intensity recommended"
}
```

---

## Daily Plans

### GET /daily-plans/{user_id}/{date}
Get daily plan for specific date.

**Auth Required:** Bearer

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | User ID |
| date | string | ISO date (YYYY-MM-DD) |

**Response:**
```json
{
  "user_id": "uuid",
  "date": "2024-01-15",
  "workouts": [
    {
      "name": "Upper Body",
      "type": "strength",
      "focus": "Push",
      "warmup": [...],
      "main": [...],
      "cooldown": [...],
      "status": "pending"
    }
  ],
  "ai_notes": "Good readiness for intensity"
}
```

---

### PUT /daily-plans/{user_id}/{date}
Create or update daily plan.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "workouts": [
    {
      "name": "Upper Body",
      "type": "strength",
      "focus": "Push",
      "warmup": [
        {"exercise": "Arm circles", "reps": 20}
      ],
      "main": [
        {"exercise": "Bench Press", "sets": 4, "reps": 6, "weight": 185}
      ],
      "cooldown": [
        {"exercise": "Stretch", "duration": "5 min"}
      ]
    }
  ],
  "ai_notes": "Focus on form"
}
```

**Response:**
```json
{
  "message": "Daily plan saved",
  "date": "2024-01-15"
}
```

---

### PATCH /daily-plans/{user_id}/{date}/workouts/{index}
Update workout status.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "status": "complete"
}
```

**Response:**
```json
{"message": "Workout status updated"}
```

---

## Weekly Plans

### GET /weekly-plans/{user_id}
Get weekly plan.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| week_start | string | Monday date (default: current week) |

**Response:**
```json
{
  "user_id": "uuid",
  "week_start": "2024-01-15",
  "focus": "hybrid",
  "days": [
    {"day": "Monday", "type": "strength", "focus": "Upper"},
    {"day": "Tuesday", "type": "swim"},
    {"day": "Wednesday", "type": "mobility"},
    {"day": "Thursday", "type": "run"},
    {"day": "Friday", "type": "strength", "focus": "Lower"},
    {"day": "Saturday", "type": "murph"},
    {"day": "Sunday", "type": "rest"}
  ]
}
```

---

### PUT /weekly-plans/{user_id}
Create or update weekly plan.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "week_start": "2024-01-15",
  "focus": "strength",
  "days": [
    {"day": "Monday", "type": "strength", "focus": "Push"},
    {"day": "Tuesday", "type": "strength", "focus": "Pull"},
    {"day": "Wednesday", "type": "rest"},
    {"day": "Thursday", "type": "strength", "focus": "Legs"},
    {"day": "Friday", "type": "strength", "focus": "Upper"},
    {"day": "Saturday", "type": "cardio"},
    {"day": "Sunday", "type": "rest"}
  ]
}
```

---

## Chat

### POST /chat/sessions
Create a new chat session.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "user_id": "uuid",
  "title": "Training Questions"
}
```

**Response (201):**
```json
{
  "id": 42,
  "user_id": "uuid",
  "title": "Training Questions",
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

### GET /chat/sessions
List user's chat sessions.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |
| limit | int | Max results (default: 20) |

**Response:**
```json
[
  {
    "id": 42,
    "title": "Training Questions",
    "created_at": "2024-01-15T10:30:00Z",
    "message_count": 12
  }
]
```

---

### POST /chat/messages
Send message and get AI response.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "user_id": "uuid",
  "session_id": 42,
  "content": "Should I do a hard workout today?"
}
```

**Response:**
```json
{
  "user_message": {
    "id": 100,
    "role": "user",
    "content": "Should I do a hard workout today?",
    "created_at": "2024-01-15T10:30:00Z"
  },
  "assistant_message": {
    "id": 101,
    "role": "assistant",
    "content": "Based on your readiness score of 72%...",
    "metadata": {
      "model": "gpt-4o-mini",
      "tokens": 245
    },
    "created_at": "2024-01-15T10:30:05Z"
  },
  "context": {
    "readiness": 0.72,
    "goals_count": 2
  }
}
```

---

### GET /chat/messages/{session_id}
Get messages in a session.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |
| limit | int | Max results (default: 50) |

**Response:**
```json
[
  {
    "id": 100,
    "role": "user",
    "content": "Should I do a hard workout today?",
    "created_at": "2024-01-15T10:30:00Z"
  },
  {
    "id": 101,
    "role": "assistant",
    "content": "Based on your readiness...",
    "created_at": "2024-01-15T10:30:05Z"
  }
]
```

---

## Strength Logging

### POST /strength
Log a strength training set.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "user_id": "uuid",
  "date": "2024-01-15",
  "lift": "Deadlift",
  "weight": 275.0,
  "reps": 5,
  "set_number": 3,
  "velocity_m_per_s": 0.45
}
```

**Response (201):**
```json
{
  "id": 500,
  "lift": "Deadlift",
  "weight": 275.0,
  "reps": 5,
  "estimated_1rm": 320.8
}
```

---

### GET /strength
Get strength metrics.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |
| lift | string | Filter by lift type |
| start_date | string | ISO date |
| end_date | string | ISO date |

**Response:**
```json
[
  {
    "id": 500,
    "date": "2024-01-15",
    "lift": "Deadlift",
    "weight": 275.0,
    "reps": 5,
    "estimated_1rm": 320.8
  }
]
```

---

### GET /strength/progress/{lift}
Get lift progress over time.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| days | int | Lookback days (default: 90) |

**Response:**
```json
{
  "lift": "Deadlift",
  "period_days": 90,
  "data": [
    {"date": "2024-01-01", "max_weight": 255.0, "estimated_1rm": 295.0},
    {"date": "2024-01-08", "max_weight": 265.0, "estimated_1rm": 308.0}
  ],
  "progress_pct": 8.5
}
```

---

## Swim Logging

### POST /swim
Log a swim workout.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "user_id": "uuid",
  "date": "2024-01-15",
  "distance_meters": 1500.0,
  "duration_seconds": 1800,
  "stroke_type": "freestyle",
  "water_type": "pool"
}
```

**Response (201):**
```json
{
  "id": 200,
  "distance_meters": 1500.0,
  "avg_pace_seconds": 120.0
}
```

---

### GET /swim/trends
Get swim performance trends.

**Auth Required:** Bearer

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| user_id | string | Required |
| days | int | Lookback days (default: 90) |

**Response:**
```json
{
  "period_days": 90,
  "total_distance_m": 45000,
  "avg_pace_trend": [
    {"week": "2024-W01", "avg_pace": 125.0},
    {"week": "2024-W02", "avg_pace": 122.0}
  ]
}
```

---

## Murph Logging

### POST /murph
Log a Murph workout.

**Auth Required:** Bearer

**Request Body:**
```json
{
  "user_id": "uuid",
  "date": "2024-01-15",
  "run_1_time_seconds": 480,
  "run_2_time_seconds": 540,
  "partition": "20-10-5",
  "total_time_seconds": 2700,
  "vest_weight": 20.0,
  "notes": "PR attempt"
}
```

**Response (201):**
```json
{
  "id": 50,
  "total_time_seconds": 2700,
  "is_pr": true
}
```

---

### GET /murph/progress
Get Murph performance stats.

**Auth Required:** Bearer

**Response:**
```json
{
  "total_attempts": 12,
  "best_time_seconds": 2580,
  "average_time_seconds": 2850,
  "with_vest_count": 8,
  "improvement_pct": 15.2,
  "recent": [
    {"date": "2024-01-15", "total_time_seconds": 2700, "vest_weight": 20.0}
  ]
}
```

---

## Waitlist

### POST /waitlist
Join the waitlist.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "Added to waitlist",
  "email": "user@example.com"
}
```

---

## Rate Limits

| Endpoint | Development | Production |
|----------|-------------|------------|
| POST /auth/register | 10000/min | 5/min |
| POST /auth/login | 10000/min | 10/min |
| POST /auth/refresh | 10000/min | 10/min |
| GET /readiness | 10000/min | 60/min |
| All others | 10000/min | 100/min |

---

## OpenAPI Documentation

Interactive API documentation is available at:
- **Swagger UI:** `http://localhost:8000/docs`
- **ReDoc:** `http://localhost:8000/redoc`
- **OpenAPI JSON:** `http://localhost:8000/openapi.json`
