# Workout Planner — Deployment

## Deployment Targets

| Target | Method | Notes |
|--------|--------|-------|
| Web (GitHub Pages) | GitHub Actions | `rummel-tech/workout-planner` |
| iOS | GitHub Actions + Xcode | TestFlight / App Store |
| Android | GitHub Actions | Play Store |
| Backend (ECS) | `infrastructure/.github/workflows/deploy-workout-planner-backend.yml` | Port 8000 |

## Backend Deployment

Backend runs on AWS ECS Fargate via the shared deploy pipeline.

**ECS task definition**: `infrastructure/aws/ecs-task-definitions/workout-planner.json`
- CPU: 512, Memory: 1024 MB
- Port: 8000
- Secrets: `DATABASE_URL`, `JWT_SECRET` from AWS Secrets Manager

**Deploy manually:**
```bash
gh workflow run deploy-workout-planner-backend.yml \
  --repo rummel-tech/infrastructure \
  -f environment=production
```

**Run database migrations:**
```bash
TASK=$(aws ecs list-tasks --cluster app-cluster \
  --service-name workout-planner-service \
  --region us-east-1 --query 'taskArns[0]' --output text)

aws ecs execute-command --cluster app-cluster --task $TASK \
  --container workout-planner \
  --command "python -m alembic upgrade head" --interactive
```

## Frontend Deployment

### Web (GitHub Pages)

```bash
flutter build web --release \
  --dart-define=PRODUCTION_API_URL=https://your-backend.com

# Or trigger CI:
gh workflow run deploy-workout-planner-frontend.yml \
  --repo rummel-tech/infrastructure
```

### iOS

```bash
flutter build ios --release
# Open Xcode → Archive → Distribute to TestFlight
```

See [IOS_BUILD_GUIDE.md](IOS_BUILD_GUIDE.md) for full iOS build instructions.

### Android

```bash
flutter build appbundle --release
# Upload to Play Console
```

## Environment Configuration

### Backend `.env` (development)

```bash
DATABASE_URL=sqlite:///workout_dev.db
JWT_SECRET=dev-secret-key
ENVIRONMENT=development
PORT=8000
CORS_ORIGINS=["http://localhost:8080","http://localhost:3000"]
```

### Backend production secrets (AWS Secrets Manager)

| Secret | Path |
|--------|------|
| Database URL | `workout-planner/database-url` |
| JWT secret | `workout-planner/jwt-secret` |

### Frontend `--dart-define` values

| Key | Default | Production |
|-----|---------|-----------|
| `PRODUCTION_API_URL` | `http://localhost:8000` | `http://<ECS_IP>:8000` |

## GitHub Secrets (for CI/CD)

Set in `rummel-tech/workout-planner` repo:

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | OIDC role ARN for ECS deploy |
| `ECR_REGISTRY` | ECR registry URL |
| `API_BASE_URL` | Backend public URL |

## Health Check

```bash
curl http://localhost:8000/health
# {"status":"healthy","service":"workout-planner"}
```

## Smoke Test Checklist

After deployment:
- [ ] `GET /health` returns `{"status":"healthy"}`
- [ ] Register a user and log in
- [ ] Create a workout
- [ ] AI coach responds to a prompt
- [ ] HealthKit data syncs (iOS only)
- [ ] Cross-module: meal-planner can read `calories_burned`
