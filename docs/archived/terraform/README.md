# Fitness Agent AWS Infrastructure (Terraform)

This directory defines the core AWS infrastructure for the Fitness Agent platform using Terraform with an S3 + DynamoDB remote backend.

## Provisioned Resources
| Layer | Resources |
|-------|-----------|
| Compute | ECS Fargate Cluster, Task Definition, Service |
| Image Registry | ECR Repository (fitness-agent-dev) |
| Identity & Access | ECS Task Execution Role, GitHub Actions OIDC Role + policy attachments |
| Secrets | References existing Secrets Manager ARNs (DATABASE_URL, JWT_SECRET) or optionally creates them when ARNs omitted |
| State Backend | S3 bucket + DynamoDB table (configured in `main.tf` backend block) |

## Secret Handling Modes
Terraform supports two mutually exclusive approaches:
1. Provide `database_secret_arn` and `jwt_secret_arn` (recommended) → No plaintext secrets in state.
2. Omit ARNs and pass `-var=database_url=... -var=jwt_secret=...` (dev only; secrets created and plaintext stored in state).

Application container receives secrets via ECS task definition `secrets` entries—never via environment variables in Terraform code.

## Inputs (variables.tf)
| Variable | Required | Description |
|----------|----------|-------------|
| `subnet_ids` | yes | List of VPC subnets for Fargate ENIs |
| `security_group_id` | yes | Security group ID for task networking |
| `database_secret_arn` | conditional | ARN if using existing DB secret |
| `jwt_secret_arn` | conditional | ARN if using existing JWT secret |
| `database_url` | conditional | Plaintext DB URL when creating secret |
| `jwt_secret` | conditional | Plaintext JWT secret when creating secret |
| `github_owner` | yes | GitHub owner/org for OIDC trust condition |
| `github_repo` | yes | GitHub repository name for OIDC trust condition |

## Remote State Backend
Configured in the `terraform { backend "s3" { ... } }` block:
```
bucket         = "fitness-agent-tf-state-901746942632"
key            = "dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "fitness-agent-tf-lock"
```
Ensure bucket + table exist before `terraform init -reconfigure`.

## Usage (Existing Secrets Recommended)
```sh
terraform init -reconfigure
terraform apply \
   -var="github_owner=srummel" \
   -var="github_repo=workout-planner" \
   -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]" \
   -var="security_group_id=sg-xxx" \
   -var="database_secret_arn=arn:aws:secretsmanager:...:secret:fitness-agent/dev/database_url-abc" \
   -var="jwt_secret_arn=arn:aws:secretsmanager:...:secret:fitness-agent/dev/jwt_secret-def"
```

## Usage (Create Secrets – Dev Only)
```sh
terraform apply \
   -var="github_owner=srummel" \
   -var="github_repo=workout-planner" \
   -var="subnet_ids=[...]" \
   -var="security_group_id=sg-xxx" \
   -var="database_url=postgresql://user:pass@host:5432/db" \
   -var="jwt_secret=$(openssl rand -hex 32)"
```

## Outputs
| Output | Purpose |
|--------|---------|
| `ecr_repository_url` | Push Docker images here (`:latest` tag for dev). |
| `ecs_cluster_id` | Cluster ARN for operational commands. |
| `ecs_service_name` | Service name for deploy updates. |
| `github_actions_oidc_role_arn` | IAM Role assumed by GitHub Actions via OIDC. |
| `database_secret_arn` | Effective DB secret ARN (input or created). |
| `jwt_secret_arn` | Effective JWT secret ARN (input or created). |

## CI/CD Integration
GitHub Actions workflow assumes `github_actions_oidc_role_arn` and builds/pushes image to ECR. ECS service is updated either by workflow or manual `aws ecs update-service --force-new-deployment`.

## Least Privilege Improvements (Future)
Replace wide managed policies with a custom policy limited to:
- `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:PutImage`
- `ecs:DescribeServices`, `ecs:UpdateService`, `ecs:RegisterTaskDefinition`
- `logs:CreateLogStream`, `logs:PutLogEvents`
- Secrets Manager read on specific ARNs

## RDS Integration (External)
RDS instance created outside this module; its endpoint populates the `DATABASE_URL` secret. Consider adding an `aws_db_instance` resource in a dedicated `database` module for production with Multi-AZ + automatic minor version upgrades.

## Troubleshooting
| Issue | Resolution |
|-------|------------|
| Lock errors | Clear DynamoDB lock item: scan & delete stale `LockID`. |
| Missing service-linked role | `aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com` |
| ECS service AccessDenied on subnets | Ensure service-linked role exists and correct IAM permissions. |
| Secret ARN outputs empty | Confirm you passed ARNs or allowed resource creation. |

## Environment Tiers
Replicate this stack per environment using different `key` prefixes (e.g. `prod/terraform.tfstate`) and distinct secret names (`fitness-agent/prod/...`). Parameterize with workspaces or separate folders.

---
**Note:** Avoid committing plaintext secrets. Prefer ARNs and external secret management (Vault → Secrets Manager or direct Secrets Manager creation).
