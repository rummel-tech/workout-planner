# Goal Plans Persistence - Implementation Summary

## What Was Done

### 1. Created API Service Layer
**File**: `applications/frontend/packages/goals_ui/lib/services/goals_api_service.dart`

Created a service class that handles all API communication:
- `getGoals(userId)` - Fetch all goals for a user
- `getPlans(goalId, userId)` - Fetch plans for a specific goal
- `createPlan(goalId, userId, name, description)` - Create a new plan
- `updatePlan(planId, name, description)` - Update an existing plan
- `deletePlan(planId)` - Delete a plan

The service communicates with the FastAPI backend at `http://localhost:8000`.

### 2. Updated GoalPlansScreen
**File**: `applications/frontend/packages/goals_ui/lib/screens/goal_plans_screen.dart`

Enhanced the screen to persist data:
- Added `_loadPlans()` method that fetches plans from the API on initialization
- Updated `_addPlan()` to call `createPlan()` API and reload data
- Updated `_editPlan()` to call `updatePlan()` API and reload data
- Updated `_deletePlan()` to call `deletePlan()` API and reload data
- Added loading state with `CircularProgressIndicator`
- Added error handling with retry button
- Shows success/error messages via `SnackBar`

### 3. Added HTTP Package Dependency
**File**: `applications/frontend/packages/goals_ui/pubspec.yaml`

Added `http: ^1.1.0` to dependencies and ran `flutter pub get`.

### 4. Backend Already Ready
The backend API was already implemented in previous work:
- **File**: `applications/backend/python_fastapi_server/routers/goals.py`
- Endpoints:
  - `GET /goals/{goalId}/plans?user_id={userId}` - Get plans
  - `POST /goals/{goalId}/plans` - Create plan
  - `PUT /goals/plans/{planId}` - Update plan
  - `DELETE /goals/plans/{planId}` - Delete plan

## How to Test

### 1. Start the Local Environment
```bash
cd "/home/shawn/APP_DEV/Fitness Agent"
./scripts/run_local.sh
```

This will:
- Start PostgreSQL database in Docker/Podman
- Run database migrations (creates `goal_plans` table)
- Start FastAPI backend on port 8000

### 2. Run the Flutter App
```bash
cd "/home/shawn/APP_DEV/Fitness Agent/applications/frontend/mobile_app"
flutter run -d chrome
```

### 3. Test the Flow
1. Navigate to Home Screen
2. Scroll to Goals section
3. Click the menu icon (⋮) on a goal
4. Select "View Plans"
5. Create a new plan with the "Create First Plan" button
6. Navigate away (back button)
7. Return to the same goal's plans
8. **Result**: The plan should still be there (persisted in database)

## What Changed
Before this fix:
- Plans were stored in `_plans` list (in-memory only)
- When navigating away, state was lost
- Plans disappeared on return

After this fix:
- Plans are stored in PostgreSQL database
- API calls persist data
- Plans are reloaded from database when screen opens
- Data survives navigation and app restarts

## Technical Details
- **User ID**: Currently hardcoded as `'user-123'` (auth not yet implemented)
- **Backend URL**: `http://localhost:8000` (configurable in `GoalsApiService`)
- **Database**: PostgreSQL via Docker, schema in `database/sql/goal_plans.sql`
- **Error Handling**: All API calls wrapped in try-catch with user feedback

## Next Steps (Optional)
1. Wire other screens (Health, Strength, Swim) to their APIs
2. Implement authentication to get real user IDs
3. Add offline caching with local database (sqflite)
4. Implement optimistic updates for better UX
