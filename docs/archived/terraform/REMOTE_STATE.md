# Remote Terraform State Guidance (S3 + DynamoDB)

Production infrastructure now uses the S3 backend with DynamoDB locking. This document expands guidance for multi-environment usage, recovery, and troubleshooting.

## 1. Create (or Verify) S3 Bucket and DynamoDB Table
If already created by Terraform bootstrap, skip creation commands. Otherwise run (ensure AWS credentials are exported):

```sh
# Adjust if bucket name already taken globally
STATE_BUCKET="fitness-agent-tf-state-901746942632"  # must be globally unique
LOCK_TABLE="fitness-agent-tf-lock"
REGION="us-east-1"

aws s3api create-bucket \
  --bucket "$STATE_BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Block public access & enable versioning
aws s3api put-public-access-block \
  --bucket "$STATE_BUCKET" \
  --public-access-block-configuration 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled

# (Optional) Default encryption
aws s3api put-bucket-encryption \
  --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# DynamoDB table for locking
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region "$REGION"
```

## 2. Backend Block (Example Dev Environment)
Configure in `main.tf` (already active):

```hcl
terraform {
  backend "s3" {
    bucket         = "fitness-agent-tf-state"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fitness-agent-tf-lock"
    encrypt        = true
  }
}
```

## 3. Migrating From Local State
From `infra/terraform` directory:

```sh
terraform init -migrate-state
terraform state list   # verify resources present
```
If migration errors due to pre-existing resources and empty local state:
- Import them:
```sh
# Examples (adjust identifiers if names differ):
terraform import aws_ecr_repository.fitness_agent fitness-agent-dev
terraform import aws_ecs_cluster.fitness_agent fitness-agent-dev-cluster
terraform import aws_iam_role.ecs_task_execution_role ecsTaskExecutionRole
terraform import aws_iam_role.github_actions_oidc_role github-actions-oidc-role
terraform import aws_secretsmanager_secret.database_url arn:aws:secretsmanager:us-east-1:901746942632:secret:fitness-agent/dev/database_url-r5cdmJ
terraform import aws_secretsmanager_secret.jwt_secret arn:aws:secretsmanager:us-east-1:901746942632:secret:fitness-agent/dev/jwt_secret-tFA03B
```
Then:
```sh
terraform plan
terraform apply
```

## 4. Troubleshooting & Lock Management
| Symptom | Cause | Action |
|---------|-------|--------|
| `Error acquiring the state lock` | Stale lock item after crash | Delete corresponding `LockID` row in DynamoDB table |
| Access denied S3/DynamoDB | Missing IAM permissions | Update role policy (see section 5) |
| Bucket name already in use | Global namespace collision | Pick a unique bucket and update backend |
| Drift not detected | State not refreshed | Run `terraform refresh` or a new plan |

## 5. CI/CD Role Policy (OIDC)
GitHub Actions (OIDC) role must include minimal S3 + DynamoDB access for backend operations:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject","s3:PutObject","s3:ListBucket","s3:GetBucketLocation",
    "dynamodb:GetItem","dynamodb:PutItem","dynamodb:DeleteItem"
  ],
  "Resource": [
    "arn:aws:s3:::fitness-agent-tf-state-901746942632",
    "arn:aws:s3:::fitness-agent-tf-state-901746942632/*",
    "arn:aws:dynamodb:us-east-1:901746942632:table/fitness-agent-tf-lock"
  ]
}
```
Add to existing inline policy or create a new one.

## 6. Multi-Environment Pattern
Use separate state keys per environment:
| Environment | State Key |
|-------------|-----------|
| dev | `envs/dev/terraform.tfstate` |
| staging | `envs/staging/terraform.tfstate` |
| prod | `envs/prod/terraform.tfstate` |

Keep variables isolated via different `*.tfvars` files or environment variable injection.

## 7. Disaster Recovery
| Scenario | Recovery |
|----------|----------|
| Bucket deleted | Recreate bucket + lock table, restore latest object (enable versioning proactively) |
| State corruption | Roll back to previous version (versioning) |
| Lost lock (phantom) | Manually delete DynamoDB item after verifying no active apply |

## 8. Security Hardening
- Enable bucket encryption (AES256 or KMS).
- Restrict bucket public access (already applied).
- Limit IAM role to exact bucket ARN + table ARN.
- Avoid storing plaintext secrets in state (design passes only ARNs).

## 9. Verification Steps
After init:
```sh
terraform state list
terraform plan -refresh-only
```
If resources list matches expectations and plan is empty (aside from expected drift), backend is healthy.

## 10. Recommended Automation
In CI pipeline steps:
1. `terraform init`
2. `terraform fmt -check`
3. `terraform validate`
4. `terraform plan -out plan.tfplan`
5. Manual/auto approval
6. `terraform apply -auto-approve plan.tfplan`

---
Remote state is now production-ready; proceed with normal `terraform plan/apply` and `./deploy.sh` for deployments.
