# Deployment

This application is deployed via the centralized [infrastructure repository](https://github.com/srummel/infrastructure).

## Deployment Process

All CI/CD pipelines and deployment workflows are maintained in the infrastructure repository for:
- Centralized credential management
- Consistent deployment patterns
- Easier maintenance across multiple applications

## How to Deploy

### Option 1: Automatic (Push to main)

Deployments can be triggered automatically by pushing to the `main` branch:

```bash
git add .
git commit -m "Update application"
git push origin main
```

This requires a trigger workflow in `.github/workflows/deploy.yml` that calls the infrastructure repository.

### Option 2: Manual Deployment

Deploy manually via the infrastructure repository:

#### Deploy Frontend

```bash
gh workflow run deploy-workout-planner-frontend.yml \
  --repo srummel/infrastructure
```

Or via GitHub UI:
1. Go to https://github.com/srummel/infrastructure/actions
2. Select "Deploy Workout Planner Frontend"
3. Click "Run workflow"
4. Click "Run workflow" button

#### Deploy Backend

```bash
gh workflow run deploy-workout-planner-backend.yml \
  --repo srummel/infrastructure
```

Or via GitHub UI:
1. Go to https://github.com/srummel/infrastructure/actions
2. Select "Deploy Workout Planner Backend"
3. Click "Run workflow"
4. Click "Run workflow" button

## Deployment Status

View deployment status and logs:
- https://github.com/srummel/infrastructure/actions

## Application URLs

After successful deployment:
- **Frontend**: https://srummel.github.io/workout-planner/
- **Backend API**: http://<ECS_IP>:8000/docs
  - Health check: http://<ECS_IP>:8000/health
  - API docs: http://<ECS_IP>:8000/docs

## Local Development

Backend:
```bash
cd applications/backend/python_fastapi_server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Frontend:
```bash
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run -d chrome
```

## Infrastructure Configuration

Deployment configuration is stored in the infrastructure repository:
- Workflow: `.github/workflows/deploy-workout-planner-*.yml`
- Config: `config/workout-planner.yml`
- ECS Task Definition: `aws/ecs-task-definitions/workout-planner.json`

## Troubleshooting

If deployment fails:
1. Check workflow logs in infrastructure repository
2. Verify AWS credentials are configured correctly
3. Check CloudWatch logs: `aws logs tail /ecs/workout-planner --follow`
4. Verify ECS task is running: `aws ecs list-tasks --cluster app-cluster --service-name workout-planner-service`

For more information, see the [Infrastructure Repository](https://github.com/srummel/infrastructure).
