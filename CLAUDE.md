# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project Overview

**Workout Planner** — AI-powered fitness coaching Flutter application.

| Path | Contents |
|------|----------|
| `~/_Projects/modules/planners/workout-planner` | This repo — Flutter frontend |
| `~/_Projects/services/workout-planner` | FastAPI backend |
| `~/_Projects/services/workout-planner-ai-engine` | AI engine (goals, readiness, plans) |
| `~/_Projects/services/workout-planner-integration-layer` | Integration layer |
| `~/_Projects/services/common` | Shared Python infrastructure |
| `rummel-tech/resources` | Platform contract + design system |

## ⚠️ Documentation Rules

**Do NOT create session/fix files in the repo root.**
Put context in commit messages and update `CHANGELOG.md` instead.

Never create: `SESSION_SUMMARY.md`, `*_FIX.md`, `*_FIX_SUMMARY.md`, `*_UPDATE.md`

Do instead:
- Describe the fix in the git commit message
- Add a line to `CHANGELOG.md` under `[Unreleased]`
- Add permanent guidance to `docs/DEVELOPMENT.md`

## Quick Start

```bash
./dev.sh status      # check services
./dev.sh hot-reload  # apply changes (~2s)
./dev.sh logs        # view output
```

Backend: `http://localhost:8000` | Frontend: `http://localhost:8080`

## Code Structure

```
lib/main.dart                      # App entry, routing
lib/config/env_config.dart         # API URL config
packages/home_dashboard_ui/        # Auth lives here
packages/goals_ui/
packages/todays_workout_ui/
packages/weekly_plan_ui/
packages/ai_coach_chat/
packages/health_integration/
docs/DEVELOPMENT.md                # Full dev guide
```

## Backend

```bash
cd ~/_Projects/services/workout-planner
source .venv/bin/activate
uvicorn main:app --reload --port 8000
```

Key endpoints: `/auth/login`, `/auth/register`, `/goals`, `/daily-plans`,
`/weekly-plans`, `/chat/messages`, `/health/summary`, `/readiness`, `/health`, `/ready`

## Deployment

```bash
gh workflow run deploy-workout-planner-frontend.yml --repo rummel-tech/infrastructure
gh workflow run deploy-workout-planner-backend.yml  --repo rummel-tech/infrastructure
```
