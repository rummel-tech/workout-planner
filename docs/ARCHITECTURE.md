# Workout Planner - High-Level Architecture & Deployment

## Executive Summary

The Workout Planner is a cloud-native AI-powered fitness platform with a microservices architecture designed for independent scaling and deployment. The system integrates mobile clients (iOS/Android), a FastAPI backend, PostgreSQL database, and AI services to deliver personalized training insights.

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT TIER                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐              ┌──────────────────┐            │
│  │   iOS App        │              │   Android App    │            │
│  │  (Flutter)       │              │   (Flutter)      │            │
│  │                  │              │                  │            │
│  │  • Home Dashboard│              │  • Home Dashboard│            │
│  │  • Goals UI      │              │  • Goals UI      │            │
│  │  • Chat Interface│              │  • Chat Interface│            │
│  │  • Health Sync   │              │  • Health Sync   │            │
│  └────────┬─────────┘              └────────┬─────────┘            │
│           │                                 │                       │
│           └─────────────┬───────────────────┘                       │
│                         │ HTTPS/REST                                │
└─────────────────────────┼───────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      API GATEWAY / LOAD BALANCER                     │
│                    (AWS ALB / GCP Load Balancer)                     │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      APPLICATION TIER                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │          FastAPI Backend (Python)                          │    │
│  │          Container: fitness_api:latest                     │    │
│  │                                                             │    │
│  │  Routers:                                                   │    │
│  │  • /goals          - Goal CRUD & plans                     │    │
│  │  • /health/samples - Health data ingestion & dedup         │    │
│  │  • /health/summary - Aggregated metrics                    │    │
│  │  • /readiness      - Dynamic scoring                       │    │
│  │  • /chat           - AI coach sessions/messages            │    │
│  │                                                             │    │
│  │  Services:                                                  │    │
│  │  • AIChatService   - Multi-provider AI (OpenAI/Anthropic)  │    │
│  │  • Database layer  - SQLite (dev) / Postgres (prod)        │    │
│  └────────────┬───────────────────────┬───────────────────────┘    │
│               │                       │                             │
│               │                       │                             │
└───────────────┼───────────────────────┼─────────────────────────────┘
                │                       │
                ▼                       ▼
┌─────────────────────────┐   ┌─────────────────────────────────┐
│    DATABASE TIER        │   │    EXTERNAL SERVICES            │
├─────────────────────────┤   ├─────────────────────────────────┤
│                         │   │                                 │
│  PostgreSQL Database    │   │  ┌────────────────────────┐    │
│  (AWS RDS / GCP SQL)    │   │  │ OpenAI API             │    │
│                         │   │  │ • GPT-4 / GPT-3.5      │    │
│  Tables:                │   │  └────────────────────────┘    │
│  • user_goals           │   │                                 │
│  • goal_plans           │   │  ┌────────────────────────┐    │
│  • health_samples       │   │  │ Anthropic API          │    │
│  • chat_sessions        │   │  │ • Claude models        │    │
│  • chat_messages        │   │  └────────────────────────┘    │
│                         │   │                                 │
│  Features:              │   │  ┌────────────────────────┐    │
│  • Auto-scaling storage │   │  │ Apple HealthKit        │    │
│  • Automated backups    │   │  │ (iOS native)           │    │
│  • Read replicas        │   │  └────────────────────────┘    │
│  • Connection pooling   │   │                                 │
└─────────────────────────┘   └─────────────────────────────────┘
```

---

## Component Inventory & Deployment Targets

### 1. Mobile Applications

#### 1.1 Flutter Mobile App
**Source:** `applications/frontend/apps/mobile_app`

**Deployment Target:** Apple App Store & Google Play Store

**Build Artifacts:**
- iOS: `mobile_app.ipa` (built via Xcode/Flutter)
- Android: `mobile_app.apk` or `mobile_app.aab` (Android App Bundle)

**Production Environment:**
- Distribution: App Store Connect (iOS), Google Play Console (Android)
- Update mechanism: Store-managed updates + CodePush for hot fixes
- Configuration: Environment variables injected at build time (API endpoint URLs)

**Key Dependencies:**
- Flutter SDK 3.22+
- Dart packages: 15+ local path dependencies (theme, goals_ui, chat, etc.)
- Platform channels: HealthKit (iOS), Google Fit (Android planned)

**Scaling:** Client-side; scales with user downloads

---

### 2. Backend API Service

#### 2.1 FastAPI Application
**Source:** `applications/backend/python_fastapi_server`

**Deployment Target:** Container orchestration platform

**Recommended Platforms:**
- **AWS:** ECS (Elastic Container Service) or EKS (Kubernetes)
- **GCP:** Cloud Run or GKE
- **Azure:** Container Instances or AKS
- **Self-hosted:** Docker Swarm or Kubernetes cluster

**Container Specification:**
```dockerfile
Image: fitness_api:latest
Base: python:3.11-slim
Exposed Port: 8000
Health Check: GET /health (to be added)
```

**Production Configuration:**
- **Replicas:** Minimum 2 for high availability
- **Auto-scaling:** CPU > 70% or request rate threshold
- **Resource Limits:**
  - CPU: 0.5-2 cores per container
  - Memory: 512MB-2GB per container
- **Environment Variables:**
  - `DATABASE_URL`: PostgreSQL connection string
  - `OPENAI_API_KEY`: AI service key
  - `ANTHROPIC_API_KEY`: Alternative AI provider
  - `SECRET_KEY`: JWT/session secret
  - `CORS_ORIGINS`: Allowed frontend origins

**Networking:**
- Internal: VPC/private subnet
- External: Load balancer with SSL termination
- Service mesh (optional): Istio/Linkerd for advanced routing

---

### 3. Database Layer

#### 3.1 PostgreSQL Database
**Schema Source:** `database/sql/`, `applications/backend/python_fastapi_server/database.py`

**Deployment Target:** Managed database service

**Recommended Platforms:**
- **AWS:** RDS for PostgreSQL (Multi-AZ)
- **GCP:** Cloud SQL for PostgreSQL
- **Azure:** Azure Database for PostgreSQL
- **Self-hosted:** PostgreSQL 14+ with replication

**Production Configuration:**
- **Instance Class:** db.t3.medium or equivalent (2 vCPU, 4GB RAM minimum)
- **Storage:** 50GB SSD with auto-scaling enabled
- **High Availability:** Multi-AZ deployment with automatic failover
- **Backups:**
  - Automated daily snapshots (30-day retention)
  - Point-in-time recovery enabled
- **Read Replicas:** 1-2 replicas for read-heavy operations
- **Connection Pooling:** PgBouncer or application-level pooling (max 100 connections)

**Schema Management:**
- Migration tool: Alembic (recommended) or custom scripts
- Version control: SQL files in `database/sql/`
- CI/CD: Automated migration on deployment

**Security:**
- Encryption at rest (AES-256)
- Encryption in transit (SSL/TLS required)
- Network isolation: VPC with security groups
- Access: IAM authentication preferred

---

### 4. Integration Services

#### 4.1 Swift HealthKit Module
**Source:** `integrations/swift_healthkit_module/`

**Deployment Target:** Embedded in iOS app binary

**Integration Pattern:**
- Built as Swift framework/module
- Linked during iOS app build process
- Communicates via Flutter MethodChannel
- Native iOS permissions handling

**Data Flow:**
- HealthKit → Swift bridge → Flutter app → Backend API

---

#### 4.2 Background Sync Pipeline
**Source:** `integrations/sync_pipeline/`

**Deployment Target:** Serverless or scheduled job

**Recommended Platforms:**
- **AWS:** Lambda + EventBridge (cron trigger)
- **GCP:** Cloud Functions + Cloud Scheduler
- **Azure:** Functions + Timer trigger
- **Kubernetes:** CronJob

**Execution Pattern:**
- Trigger: Every 15 minutes or user-initiated
- Function: Fetch health data, batch to API
- Timeout: 5 minutes
- Retry: Exponential backoff (3 attempts)

---

#### 4.3 Auth & User Sync Module
**Source:** `auth_sync_module/`

**Deployment Target:** Backend service or serverless

**Recommended Integration:**
- **Supabase Auth:** Managed authentication service
- **Auth0:** Enterprise identity platform
- **AWS Cognito:** AWS-native user pools
- **Custom:** JWT-based with FastAPI dependency injection

**Functionality:**
- User registration/login
- Profile synchronization
- Token refresh
- Session management

---

### 5. Serverless Functions (Optional/Supabase)

#### 5.1 Supabase Health Upload Function
**Source:** `database/supabase_health_upload/`

**Deployment Target:** Supabase Edge Functions

**Trigger:** Database webhook or HTTP endpoint

**Use Case:** Real-time health data processing and validation before persistence

---

#### 5.2 Supabase AI Trigger Function
**Source:** `database/supabase_ai_trigger/`

**Deployment Target:** Supabase Edge Functions

**Trigger:** Database trigger on goal/plan creation

**Use Case:** Automatic AI workout generation on new goals

---

### 6. External Service Dependencies

#### 6.1 OpenAI API
**Integration:** HTTP REST client in `ai_chat_service.py`

**Production Considerations:**
- Rate limits: Tier-based (check quota)
- Fallback: Anthropic or mock responses
- Cost monitoring: Token usage tracking
- Caching: Cache similar prompts (Redis)

---

#### 6.2 Anthropic API
**Integration:** HTTP REST client in `ai_chat_service.py`

**Production Considerations:**
- Alternative to OpenAI for redundancy
- Model selection: Claude 3 family
- Rate limits: Monitor and implement backoff

---

## Deployment Architecture by Environment

### Development Environment
```
Local Machine:
├── Backend: localhost:8000 (Docker or uvicorn)
├── Database: SQLite (local file) or PostgreSQL (Docker)
├── Frontend: flutter run (emulator/device)
└── AI Services: Mock responses (no API keys required)
```

### Staging Environment
```
Cloud Infrastructure:
├── API: 1 container (AWS Fargate / GCP Cloud Run)
├── Database: PostgreSQL (small instance, non-HA)
├── Mobile: TestFlight (iOS) / Internal Testing (Android)
└── AI Services: Real APIs with rate limits
```

### Production Environment
```
Cloud Infrastructure (High Availability):
├── Load Balancer: ALB/Cloud Load Balancing (SSL termination)
├── API Tier:
│   ├── Container Cluster (2-10 replicas, auto-scaling)
│   ├── Health checks: /health endpoint
│   └── Logging: CloudWatch / Stackdriver
├── Database Tier:
│   ├── Primary: PostgreSQL (Multi-AZ, automated backups)
│   ├── Read Replicas: 2 instances
│   └── Connection Pool: PgBouncer
├── Cache Layer (Optional): Redis for sessions/AI responses
├── CDN (Optional): CloudFront for static assets
├── Monitoring:
│   ├── Metrics: Prometheus + Grafana or DataDog
│   ├── Logging: ELK Stack or managed service
│   ├── APM: New Relic / DataDog APM
│   └── Alerting: PagerDuty / OpsGenie
└── CI/CD:
    ├── GitHub Actions (build + test + deploy)
    ├── Container Registry: ECR / GCR / Docker Hub
    └── Deployment: Rolling updates, canary releases
```

---

## Infrastructure as Code (Recommended)

### Terraform Example Structure
```
infrastructure/ (centralized repo: https://github.com/srummel/infrastructure)
├── terraform/
│   ├── modules/
│   │   ├── api/          # ECS/Cloud Run definition
│   │   ├── database/     # RDS/Cloud SQL setup
│   │   ├── network/      # VPC, subnets, security groups
│   │   └── monitoring/   # CloudWatch/Stackdriver
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
│   └── main.tf
└── kubernetes/ (if using K8s)
    ├── deployments/
    │   └── api-deployment.yaml
    ├── services/
    │   └── api-service.yaml
    └── ingress/
        └── ingress.yaml
```

---

## Networking & Security

### Network Architecture
```
Internet
    ↓
┌─────────────────────────────────┐
│   CloudFlare / Route53 (DNS)    │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│   WAF (Web Application Firewall)│
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│   Load Balancer (Public Subnet) │
│   • SSL/TLS Termination         │
│   • DDoS Protection             │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│   API Containers (Private)      │
│   • No direct internet access   │
│   • Outbound via NAT Gateway    │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│   Database (Private Subnet)     │
│   • No internet access          │
│   • VPC peering only            │
└─────────────────────────────────┘
```

### Security Measures
1. **API Security:**
   - HTTPS only (TLS 1.2+)
   - JWT authentication
   - Rate limiting per user/IP
   - Input validation (Pydantic)
   - SQL injection prevention (parameterized queries)

2. **Database Security:**
   - Private subnet (no public IP)
   - Encrypted at rest
   - SSL connections required
   - Regular security patches
   - Minimal privilege IAM roles

3. **Secrets Management:**
   - AWS Secrets Manager / GCP Secret Manager
   - Environment variables injected at runtime
   - Key rotation policies
   - No hardcoded credentials

4. **Mobile App Security:**
   - Certificate pinning (API calls)
   - Keychain storage (iOS) / Keystore (Android)
   - Obfuscation for release builds
   - App Transport Security (ATS) enabled

---

## Scalability & Performance

### Horizontal Scaling
| Component | Scaling Strategy | Max Load |
|-----------|------------------|----------|
| API Containers | Auto-scale on CPU/memory | 50+ instances |
| Database Reads | Read replicas | 5 replicas |
| Database Writes | Vertical scaling + sharding | Single primary |
| Mobile Clients | N/A | Unlimited |

### Caching Strategy
1. **Application Cache:**
   - Redis for AI responses (1-hour TTL)
   - Readiness calculations (15-min TTL)
   - Session storage

2. **Database Cache:**
   - PostgreSQL query cache
   - Materialized views for summaries

3. **CDN Cache:**
   - Static assets (images, fonts)
   - API responses (GET only, short TTL)

---

## Disaster Recovery & Business Continuity

### Backup Strategy
- **Database:** Automated daily snapshots + point-in-time recovery (5-minute RPO)
- **Object Storage:** Versioning enabled for uploaded files
- **Configuration:** Infrastructure as Code in Git

### Recovery Procedures
- **RTO (Recovery Time Objective):** 1 hour
- **RPO (Recovery Point Objective):** 5 minutes
- **Failover:** Automated for database, manual for full DR

### Monitoring & Alerts
- **Uptime:** Target 99.9% (< 8.7 hours downtime/year)
- **Response Time:** P95 < 500ms, P99 < 2s
- **Error Rate:** < 0.1%
- **Alerts:**
  - API error rate > 1%
  - Database connections > 80%
  - Disk usage > 85%
  - Memory usage > 90%

---

## CI/CD Pipeline

### Automated Workflow
```
Developer Push
    ↓
GitHub Actions Triggered
    ↓
┌─────────────────────────────────────┐
│  1. Lint & Format Check             │
│     • Python (black, flake8)        │
│     • Dart (flutter analyze)        │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  2. Unit & Integration Tests        │
│     • pytest (backend)              │
│     • flutter test (frontend)       │
│     • Coverage: 80%+ target         │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  3. Build Artifacts                 │
│     • Docker image (API)            │
│     • Flutter APK/IPA (mobile)      │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  4. Security Scan                   │
│     • Snyk (dependencies)           │
│     • Trivy (container scan)        │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  5. Push to Registry                │
│     • ECR/GCR (backend)             │
│     • TestFlight/Play Console (app) │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  6. Deploy to Environment           │
│     • Dev: Auto-deploy              │
│     • Staging: Auto-deploy          │
│     • Prod: Manual approval         │
└─────────────────────────────────────┘
```

---

## Cost Estimation (Monthly, USD)

### AWS Example (Medium Load: 10K active users)
| Service | Configuration | Est. Cost |
|---------|--------------|-----------|
| ECS Fargate | 3 x 0.5 vCPU, 1GB (API) | $50 |
| RDS PostgreSQL | db.t3.medium (Multi-AZ) | $120 |
| ALB | Standard load balancer | $25 |
| S3 | 100GB storage + transfer | $10 |
| CloudWatch | Logs + metrics | $15 |
| OpenAI API | ~1M tokens/month | $200 |
| **Total** | | **~$420/month** |

### GCP Example (Medium Load: 10K active users)
| Service | Configuration | Est. Cost |
|---------|--------------|-----------|
| Cloud Run | 3 instances, 512MB | $40 |
| Cloud SQL | db-n1-standard-1 (HA) | $100 |
| Load Balancer | Standard | $20 |
| Cloud Storage | 100GB | $5 |
| Monitoring | Logs + metrics | $10 |
| OpenAI API | ~1M tokens/month | $200 |
| **Total** | | **~$375/month** |

**Note:** Costs scale with usage; auto-scaling can increase costs during peak times.

---

## Migration Path from Dev to Production

### Phase 1: Foundation (Week 1-2)
- [ ] Set up cloud account and VPC
- [ ] Provision managed PostgreSQL database
- [ ] Migrate schema from SQLite to PostgreSQL
- [ ] Configure secrets manager

### Phase 2: API Deployment (Week 2-3)
- [ ] Build and push Docker image
- [ ] Deploy to container service (ECS/Cloud Run)
- [ ] Configure load balancer with SSL
- [ ] Set up health checks and auto-scaling

### Phase 3: Database Migration (Week 3-4)
- [ ] Export data from dev database
- [ ] Import to production PostgreSQL
- [ ] Set up automated backups
- [ ] Configure read replicas

### Phase 4: Mobile App Release (Week 4-6)
- [ ] Submit iOS app to App Review
- [ ] Submit Android app to Play Console
- [ ] Configure analytics and crash reporting
- [ ] Set up push notifications (optional)

### Phase 5: Monitoring & Optimization (Week 6+)
- [ ] Set up APM and logging
- [ ] Configure alerts and on-call
- [ ] Load testing and performance tuning
- [ ] Cost optimization review

---

## Production Checklist

### Pre-Launch
- [ ] Security audit completed
- [ ] Load testing passed (1000 concurrent users)
- [ ] Disaster recovery plan documented
- [ ] Monitoring dashboards configured
- [ ] SSL certificates valid (6+ months remaining)
- [ ] Rate limiting configured
- [ ] Error tracking enabled (Sentry/Rollbar)
- [ ] Privacy policy and terms of service published
- [ ] GDPR/compliance requirements met
- [ ] On-call rotation established

### Post-Launch
- [ ] Monitor error rates daily (first week)
- [ ] Review scaling metrics
- [ ] Optimize database queries
- [ ] Fine-tune auto-scaling thresholds
- [ ] User feedback collection
- [ ] Performance benchmarking
- [ ] Cost analysis and optimization

---

## Support & Maintenance

### Ongoing Operations
- **Database Maintenance:** Weekly vacuum, monthly index optimization
- **Security Patches:** Apply within 7 days of release
- **Dependency Updates:** Monthly review, quarterly major updates
- **Log Retention:** 30 days hot, 90 days cold (S3 Glacier)
- **Incident Response:** < 1 hour acknowledgment, < 4 hours resolution (P1)

### Team Responsibilities
- **DevOps:** Infrastructure, deployments, monitoring
- **Backend Team:** API features, database migrations, AI integration
- **Mobile Team:** App updates, platform-specific features
- **QA:** Test automation, regression testing
- **On-Call Rotation:** 24/7 coverage for production issues

---

## Appendix: Technology Stack Summary

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Mobile** | Flutter | 3.22+ | Cross-platform UI |
| | Dart | 3.x | Programming language |
| **Backend** | Python | 3.11+ | API runtime |
| | FastAPI | Latest | Web framework |
| | Uvicorn | Latest | ASGI server |
| **Database** | PostgreSQL | 14+ | Primary datastore |
| | SQLite | 3.x | Development/testing |
| **AI** | OpenAI | GPT-4 | Primary AI provider |
| | Anthropic | Claude | Fallback AI provider |
| **Container** | Docker | 24+ | Containerization |
| **Orchestration** | Kubernetes/ECS | Latest | Container orchestration |
| **CI/CD** | GitHub Actions | N/A | Automation pipeline |
| **Monitoring** | Prometheus | Latest | Metrics collection |
| | Grafana | Latest | Visualization |
| **Testing** | Pytest | Latest | Backend testing |
| | Flutter Test | N/A | Frontend testing |

---

**Document Version:** 1.0  
**Last Updated:** November 16, 2025  
**Next Review:** February 2026
