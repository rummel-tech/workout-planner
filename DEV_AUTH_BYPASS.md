# Development Authentication Bypass

## Quick Start

To run the workout-planner backend without authentication requirements:

```bash
cd /home/shawn/APP_DEV/workout-planner/applications/backend/python_fastapi_server
source .venv/bin/activate
DISABLE_AUTH=true uvicorn main:app --reload --port 8000
```

Or run in background:
```bash
DISABLE_AUTH=true nohup python -m uvicorn main:app --port 8000 > /tmp/workout-backend.log 2>&1 &
```

## What This Does

- **Bypasses JWT authentication** for all protected endpoints
- **Returns a stub user** with:
  - User ID: `user-123`
  - Email: `dev@example.com`
  - Token ID: `dev-stub-token`
- **Only works in development mode** (`ENVIRONMENT=development`)
- **Logs all bypassed requests** with `auth_bypassed_dev_mode` message

## Testing Endpoints Without Auth

All protected endpoints now work without Authorization headers:

```bash
# Get goals
curl http://localhost:8000/goals?user_id=user-123

# Get weekly plan
curl http://localhost:8000/weekly-plans/user-123

# Get daily plan
curl http://localhost:8000/daily-plans/user-123/2025-11-23

# Get health samples
curl http://localhost:8000/health/samples?user_id=user-123&sample_type=workout_distance
```

## Disabling the Bypass

To require authentication again, simply restart without the `DISABLE_AUTH` flag:

```bash
uvicorn main:app --reload --port 8000
```

## Security Note

⚠️ **This bypass is ONLY enabled when both conditions are met:**
1. `DISABLE_AUTH=true` environment variable is set
2. `ENVIRONMENT=development` (default)

It will NOT work in production or staging environments for safety.

## Current Status

✅ **Auth bypass is currently ACTIVE** on port 8000
- Check logs: `tail -f /tmp/workout-backend.log`
- Look for: `"message": "auth_bypassed_dev_mode"`
