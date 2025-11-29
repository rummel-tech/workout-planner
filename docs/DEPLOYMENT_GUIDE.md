# Deployment Guide - Workout Planner

This guide covers deployment of both the Workout Planner applications.

## Architecture Overview

```
Workout Planner/
├── Backend: Python FastAPI (AWS ECS)
├── Frontend: Flutter Web (GitHub Pages)
│
MealsPlanner/
├── Backend: Python FastAPI (in Workout Planner/applications/backend/meals_fastapi_server)
├── Frontend: Flutter Web (GitHub Pages)
```

## Backend Deployment

### Workout Planner Backend

The Workout Planner backend is deployed to AWS ECS using GitHub Actions.

**Workflow:** `.github/workflows/deploy-backend.yml`

**Prerequisites:**
- AWS OIDC Role configured
- ECR repository created
- ECS cluster and service configured
- Secrets configured in GitHub:
  - `AWS_ROLE_TO_ASSUME`
  - `DB_SECRET_ARN`
  - `JWT_SECRET_ARN`

**Deployment Steps:**
1. Push changes to `main` branch in `applications/backend/python_fastapi_server/`
2. GitHub Actions automatically:
   - Builds Docker image
   - Pushes to ECR
   - Updates ECS task definition
   - Deploys new service version

**Manual Trigger:**
```bash
# Via GitHub UI: Actions > Deploy Backend to AWS ECS > Run workflow
```

**Endpoints:**
- Health: `http://<ECS_IP>:8000/health`
- API Docs: `http://<ECS_IP>:8000/docs`
- Readiness: `http://<ECS_IP>:8000/ready`

### Meal Planner Backend

The Meal Planner backend is deployed to AWS ECS using GitHub Actions.

**Workflow:** `.github/workflows/deploy-meals-backend.yml`

**Location:** `applications/backend/meals_fastapi_server/`

**Deployment Steps:**
1. Push changes to `main` branch in `applications/backend/meals_fastapi_server/`
2. GitHub Actions automatically:
   - Builds Docker image
   - Pushes to ECR as `meals-agent`
   - Image is ready for ECS deployment

**Note:** The workflow only builds and pushes the Docker image. ECS task definition and service need to be provisioned separately.

**Manual ECS Setup:**
1. Create ECS task definition using the `meals-agent` ECR image
2. Create ECS service with the task definition
3. Configure load balancer if needed

**Endpoints:**
- Health: `http://<ECS_IP>:8000/health`
- API Docs: `http://<ECS_IP>:8000/docs`
- Weekly Plan: `http://<ECS_IP>:8000/meals/weekly-plan/{user_id}`
- Today's Meals: `http://<ECS_IP>:8000/meals/today/{user_id}`

**Local Testing:**
```bash
cd applications/backend/meals_fastapi_server
docker build -t meals-planner:local .
docker run -p 8010:8000 meals-planner:local
# Test at http://localhost:8010/docs
```

## Frontend Deployment

### Both Frontends (Combined Deployment)

Both the Workout Planner frontends are deployed together to GitHub Pages.

**Workflow:** `.github/workflows/deploy-both-frontends.yml`

**Deployment Steps:**
1. Push changes to `main` branch in `applications/frontend/`
2. GitHub Actions automatically:
   - Builds Workout Planner web app with base-href `/workout-planner/`
   - Builds Meal Planner web app with base-href `/meal-planner/`
   - Combines both builds into single deployment
   - Deploys to GitHub Pages

**Access URLs:**
- Root: `https://<username>.github.io/<repo-name>/`
- Workout Planner: `https://<username>.github.io/<repo-name>/workout-planner/`
- Meal Planner: `https://<username>.github.io/<repo-name>/meal-planner/`

**Manual Trigger:**
```bash
# Via GitHub UI: Actions > Deploy Both Frontends to GitHub Pages > Run workflow
```

**GitHub Pages Setup:**
1. Go to repository Settings > Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages` (auto-created by workflow)
4. Enable GitHub Pages if not already enabled

### Local Development

**Workout Planner:**
```bash
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run -d chrome
# Or for web build:
flutter build web --release
```

**Meal Planner:**
```bash
cd applications/frontend/apps/meals_app
flutter pub get
flutter run -d chrome
# Or for web build:
flutter build web --release
```

## Configuration

### Backend API URLs

Update the API base URLs in the frontend code:

**Workout Planner:**
- File: `applications/frontend/packages/home_dashboard_ui/lib/services/*_service.dart`
- Default: `http://localhost:8000`
- Production: Update to your ECS/EC2 public IP or domain

**Meal Planner:**
- File: `applications/frontend/packages/meals_ui/lib/services/meals_api_service.dart`
- Default: `http://localhost:8010`
- Production: Update to your ECS/EC2 public IP or domain

### Environment Variables

For production deployment, update the base URLs:

```dart
// meals_api_service.dart
MealsApiService({this.baseUrl = 'https://api.yourdomain.com'});

// Other services similarly
HealthService({this.baseUrl = 'https://api.yourdomain.com'});
```

## Monitoring & Troubleshooting

### Backend Logs

**AWS CloudWatch:**
- Log Group: `/ecs/workout-planner-dev` (Workout Planner)
- Log Group: `/ecs/meals-agent-dev` (Meal Planner - if configured)

### Frontend Issues

**Common Issues:**
1. **404 on refresh:** Single-page apps need proper routing. Check `404.html` is set up correctly.
2. **Base href issues:** Ensure base-href in workflow matches GitHub Pages path.
3. **CORS errors:** Backend must allow the GitHub Pages origin.

**Debug Steps:**
1. Check browser console for errors
2. Verify API endpoints are accessible
3. Check CORS headers in network tab
4. Verify base-href matches deployment path

### Workflow Failures

**Backend Deployment:**
- Check AWS credentials and permissions
- Verify ECR repository exists
- Check ECS task definition is valid
- Review CloudWatch logs for container errors

**Frontend Deployment:**
- Verify Flutter version matches workflow
- Check for build errors in Actions logs
- Ensure Pages is enabled in repo settings
- Verify branch permissions

## Production Checklist

- [ ] Update all API base URLs to production endpoints
- [ ] Configure CORS to allow GitHub Pages origin
- [ ] Set up proper authentication/authorization
- [ ] Enable HTTPS for backend (ALB or API Gateway)
- [ ] Configure custom domain for GitHub Pages (optional)
- [ ] Set up monitoring and alerting
- [ ] Configure database backups (if applicable)
- [ ] Review and update security groups
- [ ] Enable CloudWatch alarms for ECS services
- [ ] Document API keys and secrets management

## Quick Start Commands

```bash
# Deploy Fitness Backend
git add applications/backend/python_fastapi_server/
git commit -m "Update fitness backend"
git push origin main

# Deploy Meals Backend
git add applications/backend/meals_fastapi_server/
git commit -m "Update meals backend"
git push origin main

# Deploy Both Frontends
git add applications/frontend/
git commit -m "Update frontends"
git push origin main

# Manual trigger any workflow
# Go to Actions tab > Select workflow > Run workflow
```

## Next Steps

1. **Set up custom domain:**
   - Configure DNS CNAME record
   - Update GitHub Pages custom domain setting
   - Update CORS settings in backend

2. **Enable authentication:**
   - Implement JWT authentication in both backends
   - Add login/logout flows in frontends
   - Secure API endpoints

3. **Database setup:**
   - Provision RDS/PostgreSQL for persistent storage
   - Update connection strings in backends
   - Run database migrations

4. **Monitoring:**
   - Set up CloudWatch dashboards
   - Configure alerting rules
   - Enable application performance monitoring

## Support

For issues or questions:
1. Check GitHub Actions logs
2. Review CloudWatch logs
3. Check this deployment guide
4. Refer to `.github/DEPLOYMENT.md` for backend-specific details
