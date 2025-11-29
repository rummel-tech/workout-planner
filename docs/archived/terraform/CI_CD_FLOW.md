# CI/CD Flow

## Goals
- Immutable container images
- Declarative infrastructure changes via Terraform
- Least-privilege OIDC-based deploy role
- Automated validation (lint, tests, security) before deploy

## Pipeline Stages
| Stage | Purpose | Key Commands |
|-------|---------|--------------|
| Checkout & Setup | Fetch code, configure Python & Terraform | `actions/checkout`, `setup-python`, `terraform init` |
| Build | Build backend Docker image & tag with commit SHA | `docker build -t $ECR_URI:$GITHUB_SHA` |
| Test | Run unit & integration tests for backend | `pytest -q` |
| Scan | Optional security / vuln scan (Trivy, Bandit) | `trivy image --exit-code 1` |
| Push | Push image to ECR | `docker push $ECR_URI:$GITHUB_SHA` |
| Plan | Terraform plan with image tag variable | `terraform plan -var image_tag=$GITHUB_SHA` |
| Apply | Terraform apply on approved branch (main) | `terraform apply -auto-approve` |
| Verify | Hit readiness & health endpoints | `curl /ready` + `/health` |
| Notify | Send build/deploy status (Slack, email) | Custom action |

## Trigger Strategy
- `push` to `main`: full pipeline (plan + apply)
- `pull_request` against `main`: build + test + scan + plan (no apply)
- Scheduled (nightly): drift detection (`terraform plan -detailed-exitcode`)

## Rollback
1. Identify last successful image tag (`git rev-list --max-count=1 main` or ECR list).
2. Re-run pipeline with `image_tag=<previous_sha>` forcing ECS new deployment.
3. If infra regression, use `terraform state pull` + revert commit and apply.

## Required GitHub Secrets / Variables
| Name | Type | Description |
|------|------|-------------|
| `AWS_ROLE_TO_ASSUME` | secret | OIDC role ARN for deployments |
| `AWS_REGION` | variable | Deployment region (e.g. `us-east-1`) |
| `ECR_REPOSITORY` | variable | ECR repo name |
| `TF_VAR_database_url` | secret (optional) | Inject DB URL if not using Secrets Manager ARN pattern |

(If using Secrets Manager ARNs from Terraform variables, no plaintext DB URL required.)

## Example Job Snippet (Deploy)
```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: ${{ vars.AWS_REGION }}
      - name: Login to ECR
        run: |
          aws ecr get-login-password --region ${{ vars.AWS_REGION }} | \
            docker login --username AWS --password-stdin $ECR_URI
      - name: Build Image
        run: |
          ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --query 'repositories[0].repositoryUri' --output text)
          docker build -t $ECR_URI:${{ github.sha }} applications/backend/python_fastapi_server
      - name: Push Image
        run: |
          ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --query 'repositories[0].repositoryUri' --output text)
          docker push $ECR_URI:${{ github.sha }}
      - name: Terraform Init & Plan
        working-directory: infra/terraform
        run: |
          terraform init
          terraform plan -var image_tag=${{ github.sha }} -out plan.tfplan
      - name: Terraform Apply
        working-directory: infra/terraform
        run: terraform apply -auto-approve plan.tfplan
      - name: Post-Deploy Health Check
        run: |
          SERVICE_URL="http://$PUBLIC_IP:8000" # Acquire via terraform output or Route53
          curl -f "$SERVICE_URL/health" && curl -f "$SERVICE_URL/ready"
```

## Drift Detection
Scheduled job:
```yaml
on:
  schedule:
    - cron: '0 3 * * *'
jobs:
  drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: ${{ vars.AWS_REGION }}
      - name: Terraform Drift Plan
        working-directory: infra/terraform
        run: |
          terraform init
          set +e
          terraform plan -detailed-exitcode || code=$?; echo "exit=$code"; [ $code -eq 0 ] || [ $code -eq 2 ]
```
Interpret `exit code 2` as drift detected; notify maintainers.

## Observability Integration
- Add log shipping (CloudWatch -> OpenSearch) in future.
- Expose `/metrics` for Prometheus scraping.

## Security Enhancements (Future)
- Image signing (cosign) pre-deploy.
- SAST/Dependency scanning (CodeQL, Dependabot, Trivy). Add gating on severity thresholds.
- Policy as code (OPA / Conftest) for Terraform plans.

## Manual Hotfix
For emergency:
```sh
docker build -t $ECR_URI:hotfix .
docker push $ECR_URI:hotfix
aws ecs update-service --cluster fitness-agent-cluster --service fitness-agent-service --force-new-deployment
```
Follow with regular commit + pipeline run to return to declarative state.

## Roll Forward vs Rollback Decision
Prefer roll forward (new commit) unless root cause requires immediate revert. Keep last N image tags accessible (ECR lifecycle policy to retain recent tags).

---
The CI/CD flow above completes backend readiness for automated builds, infra evolution, and safe deployments.
