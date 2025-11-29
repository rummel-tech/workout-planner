# Infrastructure (Archived)

⚠️ **This directory has been deprecated and archived.**

## Migration Notice

All infrastructure and deployment configuration has been **moved to the centralized infrastructure repository**:

**Repository**: [infrastructure](https://github.com/srummel/infrastructure)

### What Moved

- ✅ **GitHub Actions Workflows** → `infrastructure/.github/workflows/`
  - `deploy-workout-planner-frontend.yml`
  - `deploy-workout-planner-backend.yml`
  - `test-workout-planner-backend.yml`
  - `security-scan-workout-planner.yml`

- ✅ **Terraform Infrastructure** → `infrastructure/terraform/`
  - Enhanced with ALB, RDS, auto-scaling, monitoring, backups
  - Much more comprehensive than the old setup

- ✅ **ECS Task Definitions** → `infrastructure/aws/ecs-task-definitions/`
  - `workout-planner.json`

- ✅ **Utility Scripts** → `infrastructure/scripts/`
  - `get_ecs_public_ip.sh`
  - `health_check.sh`
  - `trigger-deployment.sh`

- ✅ **Configuration** → `infrastructure/config/`
  - `workout-planner.yml`

### For Developers

**To deploy or manage infrastructure for workout-planner:**

1. Clone the infrastructure repository:
   ```bash
   git clone https://github.com/srummel/infrastructure.git
   ```

2. Follow the deployment guide:
   ```bash
   cd infrastructure
   cat README.md
   ```

3. Trigger deployments via GitHub Actions:
   ```bash
   gh workflow run deploy-workout-planner-backend.yml --repo srummel/infrastructure
   ```

### Archived Documentation

Historical Terraform documentation from this directory has been archived to:
- [docs/archived/terraform/](../docs/archived/terraform/)

This includes:
- `README.md` - Original Terraform setup guide
- `REMOTE_STATE.md` - Remote state configuration
- `CI_CD_FLOW.md` - CI/CD flow documentation

### Why the Move?

**Benefits of centralized infrastructure:**
- ✅ Single source of truth for all deployments
- ✅ Consistent CI/CD patterns across all applications
- ✅ Easier to maintain and update
- ✅ Better resource management (RDS, ALB shared across apps)
- ✅ Unified monitoring and logging
- ✅ Reduced repository bloat (removed 293 MB of AWS CLI files)

---

**Last Updated**: November 21, 2025
**Status**: Archived
**Active Infrastructure**: https://github.com/srummel/infrastructure
