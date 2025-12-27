# Workout Planner - Integrations

**Version:** 1.0
**Last Updated:** 2024-12-24

---

## Overview

This document describes all external service integrations used by the Workout Planner platform.

## Apple HealthKit

### Purpose

Automatically sync health data from Apple devices to provide personalized readiness scores and AI coaching context.

### Data Types

| HealthKit Type | Internal Type | Unit | Description |
|----------------|---------------|------|-------------|
| HKQuantityTypeIdentifierHeartRateVariabilitySDNN | `hrv` | ms | Heart Rate Variability |
| HKQuantityTypeIdentifierRestingHeartRate | `resting_hr` | bpm | Resting Heart Rate |
| HKQuantityTypeIdentifierHeartRate | `heart_rate` | bpm | Heart Rate samples |
| HKCategoryTypeIdentifierSleepAnalysis | `sleep_stage` | hours | Sleep duration |
| HKWorkoutType | `workout_*` | various | Workout data |
| HKQuantityTypeIdentifierVO2Max | `vo2max` | mL/kg/min | VO2 Max estimate |

### Permissions

```dart
// Requested HealthKit permissions (read-only)
final types = {
  HealthDataType.HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_SDNN,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_IN_BED,
  HealthDataType.WORKOUT,
  HealthDataType.VO2MAX,
};
```

### Sync Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │     │  HealthKit  │     │   Backend   │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │  Request access   │                   │
       │──────────────────>│                   │
       │                   │                   │
       │  Permission grant │                   │
       │<──────────────────│                   │
       │                   │                   │
       │  Fetch samples    │                   │
       │  (last 7 days)    │                   │
       │──────────────────>│                   │
       │                   │                   │
       │  Raw samples      │                   │
       │<──────────────────│                   │
       │                   │                   │
       │  Transform & batch│                   │
       │  (100 per request)│                   │
       │                   │                   │
       │  POST /health/samples                 │
       │──────────────────────────────────────>│
       │                   │                   │
       │  {inserted: 95, duplicates: 5}        │
       │<──────────────────────────────────────│
```

### Configuration

**Setup Wizard Page 3:**
```
Enable HealthKit: [Toggle]

When enabled:
- Auto-sync every 15 minutes (when app active)
- Manual sync available in Profile
- Last sync timestamp displayed
```

### Deduplication

Samples are deduplicated on the backend using:
```sql
UNIQUE(user_id, sample_type, start_time, source_uuid)
```

### Platform Support

| Platform | Support |
|----------|---------|
| iOS | Full support |
| macOS | Full support |
| Android | Not supported (use Google Fit - future) |
| Web | Not applicable |

---

## AI Providers

### OpenAI

**Purpose:** Provide AI coaching responses in chat interface.

**Model:** `gpt-4o-mini` (configurable)

**Configuration:**
```yaml
Provider: OpenAI
API Key: sk-...
Model: gpt-4o-mini
Max Tokens: 1000
Temperature: 0.7
```

**Context Provided:**
```json
{
  "goals": ["Active fitness goals"],
  "health_summary": {
    "hrv_avg": 48.2,
    "resting_hr_avg": 58,
    "sleep_avg": 7.2
  },
  "readiness": 0.72,
  "recent_messages": ["Last 10 chat messages"]
}
```

**System Prompt Template:**
```
You are an AI fitness coach for the Workout Planner app. You have access to the user's:
- Fitness goals: {goals}
- Recent health metrics: {health_summary}
- Current readiness score: {readiness}%

Provide helpful, personalized fitness advice based on this context.
Be encouraging but realistic. Recommend rest when readiness is low.
```

### Anthropic Claude

**Purpose:** Alternative AI provider for chat interface.

**Model:** `claude-3-5-sonnet-20241022` (configurable)

**Configuration:**
```yaml
Provider: Anthropic
API Key: sk-ant-...
Model: claude-3-5-sonnet-20241022
Max Tokens: 1000
```

**Same context and system prompt as OpenAI.**

### Mock Mode

For development/testing without API keys:

```python
AI_PROVIDER = "mock"
```

Mock responses are contextual:
- Questions about goals → Discuss goal progress
- Questions about workouts → Consider readiness
- Questions about recovery → Provide recovery tips

---

## Google Sign-In

### Purpose

Provide OAuth 2.0 authentication as alternative to email/password.

### Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │     │   Google    │     │   Backend   │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │  Initiate OAuth   │                   │
       │──────────────────>│                   │
       │                   │                   │
       │  Consent screen   │                   │
       │<──────────────────│                   │
       │                   │                   │
       │  User approves    │                   │
       │──────────────────>│                   │
       │                   │                   │
       │  ID Token         │                   │
       │<──────────────────│                   │
       │                   │                   │
       │  POST /auth/google│                   │
       │  {id_token}       │                   │
       │──────────────────────────────────────>│
       │                   │                   │
       │  Verify token, create/login user      │
       │                   │                   │
       │  {access_token, refresh_token}        │
       │<──────────────────────────────────────│
```

### Configuration

**iOS (Info.plist):**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

**Android (build.gradle):**
```groovy
// Google Services plugin
apply plugin: 'com.google.gms.google-services'
```

**Web:**
```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
```

### Scopes Requested

```dart
final scopes = [
  'email',
  'profile',
];
```

---

## Redis

### Purpose

- Response caching for expensive queries
- Token blacklisting for logout
- Rate limiting (if implemented)

### Configuration

```yaml
REDIS_URL: redis://:password@localhost:6379/0
REDIS_ENABLED: true
```

### Caching

```python
@cache(prefix="readiness", ttl=300)  # 5 minutes
async def get_readiness(user_id: str):
    # Expensive calculation
    ...
```

**Cache Keys:**
| Pattern | TTL | Purpose |
|---------|-----|---------|
| `readiness:{user_id}` | 5 min | Readiness scores |
| `health_summary:{user_id}` | 5 min | Health summaries |
| `health_trends:{user_id}:{metric}` | 10 min | Health trends |

### Token Blacklist

```python
# On logout
redis.setex(f"blacklist:{jti}", ttl, "1")

# On every request
if redis.exists(f"blacklist:{jti}"):
    raise Unauthorized("Token revoked")
```

### Graceful Degradation

If Redis is unavailable:
- Caching is bypassed (queries hit database)
- Token blacklisting falls back to database (if implemented)
- Error is logged, service continues

---

## PostgreSQL

### Purpose

Primary database for all application data.

### Configuration

**Development (SQLite):**
```yaml
DATABASE_URL: sqlite:///fitness_dev.db
```

**Production (PostgreSQL):**
```yaml
DATABASE_URL: postgresql://user:pass@host:5432/workout_planner
```

### Connection Pooling

```python
# Production settings
pool_size = 10
max_overflow = 20
pool_timeout = 30
pool_recycle = 1800
```

### Schema Management

- Tables auto-created on startup (IF NOT EXISTS)
- Schema changes require manual migration
- Future: Alembic migrations

---

## Prometheus Metrics

### Purpose

Export application metrics for monitoring.

### Endpoint

```
GET /metrics
```

### Metrics Exported

```prometheus
# Request metrics
request_count_total{method="GET", endpoint="/readiness", status="200"} 1234
request_latency_seconds{method="GET", endpoint="/readiness"} 0.045

# Cache metrics
cache_hits_total{endpoint="/readiness"} 890
cache_misses_total{endpoint="/readiness"} 344

# Domain events
domain_events_total{event="user_registered"} 50
domain_events_total{event="workout_completed"} 234
```

### Integration

**Prometheus scrape config:**
```yaml
scrape_configs:
  - job_name: 'workout-planner-api'
    static_configs:
      - targets: ['api:8000']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

---

## Future Integrations

### Google Fit (Planned)

Android equivalent of HealthKit for health data sync.

**Data Types:**
- Heart rate
- Sleep
- Workouts
- Steps

### Garmin Connect (Planned)

Direct integration with Garmin devices.

**Data Types:**
- HRV (via Garmin HRV Status)
- Training readiness
- Sleep
- Workouts

### Fitbit (Planned)

Fitbit device integration.

**Data Types:**
- Heart rate
- HRV (Premium)
- Sleep stages
- Activity

### Strava (Planned)

Workout import from Strava.

**Data Types:**
- Run activities
- Cycle activities
- Swim activities

---

## Integration Testing

### HealthKit

```dart
// Mock HealthKit for testing
class MockHealthService implements HealthService {
  @override
  Future<List<HealthSample>> fetchSamples() async {
    return [
      HealthSample(type: 'hrv', value: 45.0, ...),
      HealthSample(type: 'resting_hr', value: 58, ...),
    ];
  }
}
```

### AI Providers

```python
# Use mock mode for testing
AI_PROVIDER=mock pytest tests/test_chat.py
```

### Redis

```python
# Use fakeredis for testing
import fakeredis
redis_client = fakeredis.FakeRedis()
```

---

## Integration Status

| Integration | Status | Platform |
|-------------|--------|----------|
| HealthKit | ✅ Implemented | iOS, macOS |
| OpenAI | ✅ Implemented | All |
| Anthropic | ✅ Implemented | All |
| Google Sign-In | ✅ Implemented | All |
| Redis | ✅ Implemented | Backend |
| PostgreSQL | ✅ Implemented | Backend |
| Prometheus | ✅ Implemented | Backend |
| Google Fit | 🔜 Planned | Android |
| Garmin | 🔜 Planned | All |
| Fitbit | 🔜 Planned | All |
| Strava | 🔜 Planned | All |
