# Fitness Agent - High-Level Design & Deployment Architecture

**Document Version:** 1.0  
**Last Updated:** November 2025  
**Status:** Active Development

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Deployable Components](#deployable-components)
4. [Deployment Plan](#deployment-plan)
5. [Environment Configuration](#environment-configuration)
6. [Monitoring & Health Checks](#monitoring--health-checks)

---

## Executive Summary

The Fitness Agent is a modular, cloud-native application consisting of independent deployable components. The system is designed to scale horizontally with clear separation of concerns:

- **Frontend**: Flutter web & mobile apps with modular UI packages
- **Backend**: Python FastAPI microservice with AI/ML capabilities
- **Database**: PostgreSQL with Supabase serverless functions
- **Integrations**: Native iOS HealthKit, background sync pipeline, authentication

Each component can be deployed independently using Docker containers or platform-specific tools. The system supports both local development (Docker Compose) and cloud deployments (AWS, GCP, Azure, Supabase).

---

## System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENTS / END USERS                         │
├──────────────────────┬──────────────────────┬──────────────────┤
│   Flutter Mobile     │   Flutter Web        │  Health Platforms │
│  (Android/iOS)       │  (Browser)           │  (Apple Health)   │
└──────────────────────┴──────────────────────┴──────────────────┘
         │                      │                        │
         └──────────────────────┼────────────────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │   API Gateway / CDN     │
                    │  (Optional - Nginx)     │
                    └───────────┬─────────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
    ┌─────▼─────┐         ┌─────▼──────┐      ┌──────▼──────┐
    │  Frontend  │         │   Backend  │      │  Integrations
    │  Service   │         │   API      │      │  Services
    │  (Nginx)   │         │  (FastAPI) │      │
    │  Port: 80  │         │  Port:8000 │      │
    └────────────┘         └─────┬──────┘      └──────┬───────┘
                                 │                    │
                                 │    ┌───────────────┘
                                 │    │
                    ┌────────────▼────▼─────────────────┐
                    │   Supabase / PostgreSQL           │
                    │  • Schema & Tables                │
                    │  • Serverless Functions (Triggers)│
                    │  • Real-time Subscriptions        │
                    └──────────────────────────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │  Background Services     │
                    │  • Auth Sync             │
                    │  • Health Data Sync      │
                    │  • AI Insights Engine    │
                    │  • Notification Service  │
                    └──────────────────────────┘
```

### Layered Architecture

```
APPLICATION LAYER (User Facing)
├── Flutter Mobile App (iOS/Android)
├── Flutter Web App
└── Native iOS HealthKit Module

API LAYER (Business Logic)
├── FastAPI Backend Server
│   ├── Auth Service
│   ├── Workout Service
│   ├── AI Insights Service
│   ├── Readiness Service
│   └── User Profile Service
└── Supabase Edge Functions

DATA LAYER (Persistence)
├── PostgreSQL Database
│   ├── Users Table
│   ├── Workouts Table
│   ├── Health Metrics Table
│   ├── AI Insights Table
│   └── Goals Table
└── Real-time Subscriptions

INTEGRATION LAYER
├── Apple HealthKit Bridge
├── Background Sync Pipeline
├── Email/Push Notifications
└── External API Connectors
```

---

## Deployable Components

### 1. **Backend API Service**

**Component ID:** `fitness_api`

**Location:** `applications/backend/fastapi_server/`

**Technology Stack:**
- Language: Python 3.11+
- Framework: FastAPI
- Server: Uvicorn
- Dependencies: See `requirements.txt`

**Responsibilities:**
- REST API endpoints for workouts, readiness, goals, etc.
- AI/ML model inference for workout recommendations
- User authentication and profile management
- Data aggregation from multiple sources

**Deployment Methods:**
- Docker container (recommended for cloud)
- Standalone Python service (local development)
- Serverless function (AWS Lambda, Google Cloud Run)

**Health Check Endpoint:**
- `GET /health` - Returns `{"status": "ok"}`

**Ports:** 8000 (internal), 8000 (external in Docker)

---

### 2. **Frontend Web Application**

**Component ID:** `fitness_frontend`

**Location:** `applications/frontend/apps/mobile_app/`

**Technology Stack:**
- Language: Dart
- Framework: Flutter
- Build Target: Web (Chrome/Safari/Firefox)
- UI Packages: Modular packages in `applications/frontend/packages/`

**Responsibilities:**
- Web-based user interface
- Real-time dashboard with workout data
- User settings and profile management
- Goal tracking and progress visualization

**Deployment Methods:**
- Docker container with Nginx (recommended)
- Static hosting (AWS S3 + CloudFront, Netlify, Vercel)
- CDN distribution

**Environment Variables:**
- `API_URL`: Backend API endpoint (e.g., `http://localhost:8000`)
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_ANON_KEY`: Public Supabase key

**Ports:** 80 (HTTP), 443 (HTTPS with reverse proxy)

---

### 3. **Flutter Mobile Apps (iOS/Android)**

**Component ID:** `fitness_mobile_app`

**Location:** `applications/frontend/apps/mobile_app/`

**Technology Stack:**
- Language: Dart
- Framework: Flutter 3.38.1+
- Target Platforms: iOS 12+, Android 5.0+

**Responsibilities:**
- Native mobile user interface
- Offline-first capability with local sync
- HealthKit integration (iOS)
- Push notifications
- Biometric authentication

**Build & Distribution:**
- Android: `flutter build apk` or `flutter build appbundle` → Google Play Store
- iOS: `flutter build ios` → Xcode → App Store
- Signed APK/IPA distribution

**Key Dependencies:**
- `flutter_local_notifications` - Push notifications
- `http` - API communication
- Custom packages in `applications/frontend/packages/`

**Ports:** N/A (native app)

---

### 4. **Database Schema & Migrations**

**Component ID:** `fitness_database`

**Location:** `database/sql/`

**Technology Stack:**
- Database: PostgreSQL 12+
- Version Control: SQL migration scripts
- Hosting: Supabase or self-hosted PostgreSQL

**Responsibilities:**
- Data schema definition (tables, indexes, constraints)
- Database migrations and versioning
- Data relationships and integrity

**Key Tables:**
- `users` - User profiles and authentication
- `workouts` - Workout history and details
- `health_metrics` - Heart rate, sleep, readiness, etc.
- `ai_insights` - AI-generated recommendations
- `goals` - User fitness goals and progress
- `notifications` - User notification preferences

**Deployment Method:**
- Supabase project setup
- Manual SQL execution (development)
- Migration tools (Alembic, Flyway)

**Backup Strategy:** Daily automated backups (if using Supabase)

---

### 5. **Supabase Serverless Functions**

**Component ID:** `fitness_functions`

**Location:** 
- `database/supabase_ai_trigger/`
- `database/supabase_health_upload/`

**Technology Stack:**
- Language: JavaScript/TypeScript
- Runtime: Deno or Node.js
- Hosting: Supabase Functions

**Responsibilities:**

**5a. Health Data Upload Function**
- Syncs health data from mobile devices
- Aggregates metrics (sleep, HR, HRV, etc.)
- Triggers readiness calculations

**5b. AI Trigger Function**
- Evaluates user readiness daily
- Generates personalized workout recommendations
- Creates insights based on performance trends

**Deployment:** 
- Push to Supabase via CLI
- Functions automatically trigger on database events or scheduled cron jobs

---

### 6. **Background Sync Pipeline**

**Component ID:** `sync_service`

**Location:** `integrations/sync_pipeline/`

**Technology Stack:**
- Language: Python or Node.js
- Execution: Docker container or serverless
- Frequency: Scheduled (hourly/daily)

**Responsibilities:**
- Aggregates health data from multiple sources
- Syncs user profiles across services
- Handles failed sync retries
- Logs sync operations for debugging

**Deployment Method:**
- Docker container with cron scheduler
- Kubernetes CronJob
- AWS EventBridge or Lambda scheduled events
- Supabase Cron functions

**Frequency:** Runs every 1-24 hours (configurable)

---

### 7. **Authentication & User Sync Module**

**Component ID:** `auth_service`

**Location:** `integrations/auth_sync_module/`

**Technology Stack:**
- Language: Dart/Flutter + Python
- Auth Provider: Supabase Auth or Firebase Auth
- Session Management: JWT tokens

**Responsibilities:**
- User registration and login
- Multi-factor authentication
- User profile synchronization
- Session token refresh

**Deployment Method:**
- Supabase Auth (managed, zero-config)
- Firebase Auth (managed, zero-config)
- Custom JWT service (self-hosted)

---

### 8. **Native iOS HealthKit Integration**

**Component ID:** `healthkit_bridge`

**Location:** `integrations/swift_healthkit_module/`

**Technology Stack:**
- Language: Swift
- Framework: HealthKit
- Integration: Flutter method channels

**Responsibilities:**
- Read health metrics from iOS HealthKit (steps, HR, sleep, etc.)
- Request user permissions
- Real-time metric updates
- Secure data transmission to backend

**Deployment Method:**
- Compiled into iOS app binary
- Requires App Store privacy policy (HealthKit access)

**Permissions Required:**
- `NSHealthShareUsageDescription` in `Info.plist`
- User consent at runtime

---

## Deployment Plan

### Phase 1: Local Development Environment

**Goal:** Set up complete system on developer machine

**Prerequisites:**
- Docker & Docker Compose (v2+)
- Git
- Flutter SDK (optional, for mobile development)
- PostgreSQL CLI (optional)

**Steps:**

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd "Fitness Agent"
   ```

2. **Create Environment File**
   ```bash
   cp .env.example .env
   # Edit .env with your local database credentials and API keys
   ```

3. **Start Services with Docker Compose**
   ```bash
   docker compose up --build
   ```
   - API will be available at `http://localhost:8000`
   - Frontend will be available at `http://localhost`

4. **Verify Services**
   ```bash
   # Check backend health
   curl http://localhost:8000/health
   
   # Check frontend
   curl http://localhost
   ```

5. **Initialize Database** (if not auto-initialized)
   ```bash
   # Run migrations
   docker exec fitness_api python -m alembic upgrade head
   ```

**Expected Runtime:** 2-3 minutes for all services to be ready

---

### Phase 2: Staging Environment

**Goal:** Test application in cloud-like environment before production

**Target Infrastructure:** AWS EC2, GCP Compute Engine, or Azure VM

**Deployment Steps:**

1. **Provision Cloud Infrastructure**
   ```bash
   # Example: AWS EC2 (Ubuntu 22.04, t3.medium or larger)
   - CPU: 2+ cores
   - RAM: 4GB+ 
   - Storage: 50GB+ SSD
   - Security Group: Allow ports 80, 443, 8000 (internal only)
   ```

2. **Install Prerequisites on Server**
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose git curl
   sudo usermod -aG docker $USER
   ```

3. **Clone Repository & Configure**
   ```bash
   git clone <repository-url>
   cd "Fitness Agent"
   
   # Create .env file with staging values
   cat > .env <<EOF
   DATABASE_URL=postgres://user:pass@staging-db:5432/fitness_staging
   SUPABASE_URL=https://staging-supabase.example.com
   SUPABASE_KEY=staging_service_role_key
   SECRET_KEY=staging_secret_key_12345
   EOF
   ```

4. **Build and Push Images to Registry** (AWS ECR, Docker Hub, etc.)
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com
   
   docker build -f applications/backend/Dockerfile -t 123456789.dkr.ecr.us-east-1.amazonaws.com/fitness_api:v1.0.0 applications/backend
   docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/fitness_api:v1.0.0
   
   docker build -f applications/frontend/Dockerfile -t 123456789.dkr.ecr.us-east-1.amazonaws.com/fitness_frontend:v1.0.0 applications/frontend
   docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/fitness_frontend:v1.0.0
   ```

5. **Deploy using ECS Task Definition**
   - Backend deployed to ECS Fargate using task definitions in infrastructure repo
   - Frontend deployed to GitHub Pages via workflow
   - See [Production Deployment Guide](https://github.com/srummel/documentation/blob/main/deployment/production-deployment.md)

6. **Start Services**
   ```bash
   docker compose -f docker-compose.staging.yml up -d
   ```

7. **Run Smoke Tests**
   ```bash
   # Health checks
   curl https://staging.fitnessagent.example/health
   curl https://staging-api.fitnessagent.example/health
   
   # Functional tests
   curl -X POST https://staging-api.fitnessagent.example/api/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test123"}'
   ```

**Estimated Time:** 15-20 minutes

---

### Phase 3: Production Deployment

**Goal:** Deploy to production environment with high availability

**Target Infrastructure Options:**

**Option A: AWS ECS (Recommended)**
- Application Load Balancer
- ECS Fargate for containers
- RDS PostgreSQL database
- CloudFront CDN for frontend
- CloudWatch for monitoring

**Option B: Kubernetes (Scalable)**
- AWS EKS, GCP GKE, or Azure AKS
- Helm charts for package management
- Ingress controller for routing
- StatefulSet for databases

**Option C: Supabase Hosting**
- Fully managed PostgreSQL
- Supabase Auth
- Supabase Functions for serverless
- Supabase Storage for media

**Deployment Steps (AWS Example):**

1. **Setup AWS Infrastructure**
   ```bash
   # Create RDS PostgreSQL database
   aws rds create-db-instance \
     --db-instance-identifier fitness-db-prod \
     --db-instance-class db.t3.medium \
     --engine postgres \
     --master-username admin \
     --master-user-password <strong-password>
   
   # Create ECR repositories
   aws ecr create-repository --repository-name fitness_api
   aws ecr create-repository --repository-name fitness_frontend
   ```

2. **Build and Push Production Images**
   ```bash
   docker build -f applications/backend/Dockerfile \
     -t fitness_api:prod applications/backend
   docker tag fitness_api:prod \
     123456789.dkr.ecr.us-east-1.amazonaws.com/fitness_api:prod
   docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/fitness_api:prod
   
   # Repeat for frontend
   ```

3. **Setup Application Load Balancer**
   ```bash
   # Create ALB with target groups for API and Frontend
   # Configure health check endpoints
   # Attach SSL certificate (AWS Certificate Manager)
   ```

4. **Deploy to ECS**
   ```bash
   # Create ECS task definitions for API and Frontend
   # Configure environment variables and secrets
   # Create ECS services with desired task count (min 2 for HA)
   ```

5. **Configure CloudFront CDN**
   ```bash
   # Create distribution for frontend (S3 origin or ALB)
   # Set cache policies and invalidation rules
   # Attach SSL certificate
   ```

6. **Run Production Health Checks**
   ```bash
   curl https://fitnessagent.example/health
   curl https://api.fitnessagent.example/health
   ```

7. **Monitor & Alert Setup**
   ```bash
   # CloudWatch dashboards
   # SNS notifications for failures
   # Error logging with structured JSON
   ```

**Estimated Time:** 1-2 hours (first deployment), 15-30 minutes (subsequent)

---

### Phase 4: Continuous Deployment Pipeline

**Goal:** Automate deployment process

**Technology:** GitHub Actions, GitLab CI/CD, or Jenkins

**Pipeline Stages:**

```
1. Code Push to Main Branch
        ↓
2. Run Tests (Unit, Integration)
        ↓
3. Build Docker Images
        ↓
4. Push to Registry
        ↓
5. Deploy to Staging
        ↓
6. Run Smoke Tests
        ↓
7. Manual Approval (if needed)
        ↓
8. Deploy to Production
        ↓
9. Verify Production Health
```

**Example GitHub Actions Workflow:**

```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build API Image
        run: |
          docker build -f applications/backend/Dockerfile \
            -t fitness_api:${{ github.sha }} applications/backend
      
      - name: Build Frontend Image
        run: |
          docker build -f applications/frontend/Dockerfile \
            -t fitness_frontend:${{ github.sha }} applications/frontend
      
      - name: Push to ECR
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REGISTRY
          docker tag fitness_api:${{ github.sha }} $ECR_REGISTRY/fitness_api:${{ github.sha }}
          docker push $ECR_REGISTRY/fitness_api:${{ github.sha }}
          # Repeat for frontend
      
      - name: Deploy to ECS
        run: |
          aws ecs update-service --cluster fitness-prod --service fitness-api \
            --force-new-deployment
```

---

## Environment Configuration

### Local Development Environment

**File:** `.env.local` or `.env`

```bash
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_LOG_LEVEL=DEBUG

# Database
DATABASE_URL=postgres://postgres:postgres@localhost:5432/fitness_dev
DATABASE_POOL_SIZE=5

# Supabase (Local or Remote)
SUPABASE_URL=http://localhost:54321
SUPABASE_KEY=eyJhbGc...
SUPABASE_JWT_SECRET=your-jwt-secret

# Authentication
SECRET_KEY=dev-secret-key-do-not-use-in-production
JWT_EXPIRATION=3600

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...

# AI/ML Models
AI_MODEL_PATH=./models/workout_recommender.pkl
```

### Staging Environment

**File:** `.env.staging`

```bash
API_HOST=0.0.0.0
API_PORT=8000
API_LOG_LEVEL=INFO

DATABASE_URL=postgres://admin:${STAGING_DB_PASSWORD}@staging-db.rds.amazonaws.com:5432/fitness_staging
DATABASE_POOL_SIZE=10

SUPABASE_URL=https://staging-supabase.example.com
SUPABASE_KEY=${STAGING_SUPABASE_KEY}
SUPABASE_JWT_SECRET=${STAGING_JWT_SECRET}

SECRET_KEY=${STAGING_SECRET_KEY}
JWT_EXPIRATION=7200

NEXT_PUBLIC_API_URL=https://staging-api.fitnessagent.example
NEXT_PUBLIC_SUPABASE_URL=https://staging-supabase.example.com
NEXT_PUBLIC_SUPABASE_ANON_KEY=${STAGING_SUPABASE_ANON_KEY}

# Sentry for error tracking
SENTRY_DSN=${STAGING_SENTRY_DSN}
```

### Production Environment

**File:** `.env.production` (managed by secrets management system)

```bash
API_HOST=0.0.0.0
API_PORT=8000
API_LOG_LEVEL=WARNING

DATABASE_URL=postgres://admin:${PROD_DB_PASSWORD}@prod-db.rds.amazonaws.com:5432/fitness
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=40

SUPABASE_URL=https://prod-supabase.example.com
SUPABASE_KEY=${PROD_SUPABASE_KEY}
SUPABASE_JWT_SECRET=${PROD_JWT_SECRET}

SECRET_KEY=${PROD_SECRET_KEY}
JWT_EXPIRATION=3600

NEXT_PUBLIC_API_URL=https://api.fitnessagent.example
NEXT_PUBLIC_SUPABASE_URL=https://prod-supabase.example.com
NEXT_PUBLIC_SUPABASE_ANON_KEY=${PROD_SUPABASE_ANON_KEY}

# Error Tracking
SENTRY_DSN=${PROD_SENTRY_DSN}

# Email Service
SMTP_HOST=${PROD_SMTP_HOST}
SMTP_PORT=587
SMTP_USER=${PROD_SMTP_USER}
SMTP_PASSWORD=${PROD_SMTP_PASSWORD}

# API Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_PERIOD=60
```

**Secrets Management Best Practices:**
- Use AWS Secrets Manager / Parameter Store
- Use HashiCorp Vault
- Use GitHub Secrets for CI/CD
- Never commit secrets to version control
- Rotate secrets every 90 days
- Enable audit logging for secret access

---

## Monitoring & Health Checks

### Health Check Endpoints

**Backend API**
```
GET /health
Response: 200 OK
{
  "status": "ok",
  "database": "connected",
  "version": "1.0.0"
}
```

**Frontend**
```
GET /health
Response: 200 OK
(or simply returns the HTML page)
```

### Metrics to Monitor

| Metric | Alert Threshold | Frequency |
|--------|-----------------|-----------|
| CPU Usage | > 80% | Every 5 min |
| Memory Usage | > 85% | Every 5 min |
| Database Connection Pool | > 18/20 | Every 5 min |
| API Response Time | > 2000ms (p95) | Every 1 min |
| Error Rate | > 1% | Every 5 min |
| Disk Space | < 20% available | Every 1 hour |
| Database Replication Lag | > 10 seconds | Every 1 min |
| Failed Sync Operations | Any failures | Immediate |

### Logging Strategy

**Log Levels:**
- `DEBUG` - Development only
- `INFO` - Key events, application state changes
- `WARNING` - Recoverable issues
- `ERROR` - Unrecoverable issues
- `CRITICAL` - System-level failures

**Log Aggregation:**
- AWS CloudWatch / GCP Cloud Logging / Azure Monitor
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Datadog or New Relic

**Example Log Format:**
```json
{
  "timestamp": "2025-11-15T10:30:45Z",
  "level": "INFO",
  "service": "fitness_api",
  "trace_id": "abc123def456",
  "message": "User workout created",
  "user_id": "user_12345",
  "duration_ms": 245
}
```

### Alerting Strategy

**Critical Alerts (Immediate):**
- API service down
- Database connection failure
- High error rate (> 5%)
- Disk space < 10%

**Warning Alerts (Within 1 hour):**
- High response time (p95 > 3000ms)
- Memory usage > 85%
- Failed sync operations (> 10)
- SSL certificate expiring soon (< 7 days)

**Notification Channels:**
- PagerDuty for on-call rotation
- Slack for team notifications
- Email for escalation

---

## Rollback Procedures

### Rollback Strategy

**For Docker Deployments:**
```bash
# Check current version
docker ps

# Rollback to previous image
docker pull <registry>/fitness_api:v1.0.0
docker-compose down
docker-compose up -d

# Verify services
curl http://localhost:8000/health
```

**For ECS Deployments:**
```bash
# View task definition history
aws ecs list-task-definitions --family-prefix fitness-api

# Rollback to previous task definition
aws ecs update-service \
  --cluster fitness-prod \
  --service fitness-api \
  --task-definition fitness-api:2  # Previous version

# Monitor rollback
aws ecs describe-services --cluster fitness-prod --services fitness-api
```

**For Database Rollback:**
- Restore from automated daily backup
- Point-in-time recovery (AWS RDS, last 35 days)
- Transaction logs for custom recovery points

---

## Security Considerations

### Network Security
- Use VPC with private subnets for databases
- Security groups restrict traffic to needed ports only
- Use VPN or bastion host for admin access
- Enable VPC Flow Logs for audit

### Data Security
- Encrypt data at rest (AES-256)
- Encrypt data in transit (TLS 1.2+)
- Hash passwords with bcrypt (cost factor 12)
- Implement data retention policies

### Authentication & Authorization
- JWT tokens with 1-hour expiration
- Refresh token rotation
- Multi-factor authentication for admin accounts
- Role-based access control (RBAC)

### API Security
- Rate limiting (1000 requests per minute per user)
- CORS policy enforcement
- Input validation and sanitization
- SQL injection prevention (parameterized queries)
- CSRF protection

---

## Disaster Recovery

### Backup Strategy

**Database Backups:**
- Automated daily full backups
- Retention: 30 days
- Geographic replication to secondary region
- Test restore procedures monthly

**Application Code:**
- Git repository with protected main branch
- All deployments tagged with versions
- Release notes documented

**Configuration Backups:**
- Secrets in AWS Secrets Manager
- Infrastructure as Code in version control
- Regular configuration audits

### RTO & RPO Targets

| Component | RTO | RPO |
|-----------|-----|-----|
| Frontend | 1 hour | 1 hour |
| Backend API | 30 minutes | 15 minutes |
| Database | 4 hours | 1 hour |
| User Data | 24 hours | 1 hour |

---

## Cost Optimization

### Estimated Monthly Costs (AWS)

| Component | Size | Cost |
|-----------|------|------|
| ECS Fargate (2 t3.medium tasks) | 2 CPU, 4GB RAM | $100-150 |
| RDS PostgreSQL | db.t3.medium | $50-75 |
| CloudFront CDN | ~10GB transfer | $0.87/GB |
| CloudWatch | Logs & Monitoring | $20-40 |
| Route53 DNS | 1 hosted zone | $0.50 |
| **Total** | | **$200-300** |

### Cost Reduction Strategies
- Use Reserved Instances (RI) for 1-3 year commitment
- Auto-scaling to match demand
- Cache frequently accessed data
- Compress API responses
- Use CDN for static content
- Monitor and clean up unused resources

---

## Appendix

### A. Quick Reference Commands

**Local Development:**
```bash
# Start all services
docker compose up --build

# View logs
docker compose logs -f api
docker compose logs -f frontend

# Stop services
docker compose down

# Reset database
docker compose down -v
docker compose up --build
```

**Production Deployment (AWS):**
```bash
# Build and push
aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY
docker build -t $REGISTRY/fitness_api:$VERSION applications/backend
docker push $REGISTRY/fitness_api:$VERSION

# Deploy
aws ecs update-service --cluster fitness-prod --service fitness-api --force-new-deployment
```

### B. Troubleshooting Guide

| Issue | Solution |
|-------|----------|
| API service won't start | Check DB connection, verify secrets, check logs: `docker logs fitness_api` |
| Frontend blank page | Clear browser cache, check API connectivity, verify `API_URL` env var |
| High memory usage | Check for memory leaks, scale horizontally, increase task memory |
| Database locked | Kill long-running queries, restart database, check backup jobs |
| Slow queries | Add database indexes, enable query profiling, optimize N+1 queries |

### C. Additional Resources

- [Flutter Documentation](https://flutter.dev)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Supabase Documentation](https://supabase.com/docs)
- [Docker Deployment Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)

---

**Document Control:**
- Author: Fitness Agent Dev Team
- Last Reviewed: November 2025
- Next Review: Q1 2026
