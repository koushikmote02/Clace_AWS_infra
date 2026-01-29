# AWS Terraform Infrastructure

This Terraform project deploys a Rust Axum API application to AWS using ECS Fargate, RDS PostgreSQL, and optional ElastiCache Redis. The architecture prioritizes cost efficiency by avoiding NAT Gateways while maintaining security through layered security groups and AWS WAF.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Region                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         VPC (10.0.0.0/16)                              │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    Public Subnets                                │  │  │
│  │  │  ┌─────────────┐    ┌─────────────────────────────────────────┐ │  │  │
│  │  │  │     ALB     │───▶│  ECS Fargate Tasks (Public IPs)         │ │  │  │
│  │  │  │  (HTTPS)    │    │  - Rust Axum API                        │ │  │  │
│  │  │  └─────────────┘    │  - Port 8080                            │ │  │  │
│  │  │        ▲            └─────────────────────────────────────────┘ │  │  │
│  │  └────────│────────────────────────────────────────────────────────┘  │  │
│  │           │                           │                                │  │
│  │      ┌────┴────┐                      │                                │  │
│  │      │   WAF   │                      ▼                                │  │
│  │      └─────────┘         ┌────────────────────────────────────────┐   │  │
│  │                          │         Database Subnets (Private)      │   │  │
│  │                          │  ┌──────────────┐  ┌─────────────────┐ │   │  │
│  │                          │  │     RDS      │  │   ElastiCache   │ │   │  │
│  │                          │  │  PostgreSQL  │  │     Redis       │ │   │  │
│  │                          │  └──────────────┘  └─────────────────┘ │   │  │
│  │                          └────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────┐  ┌──────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │   ECR    │  │ Secrets Manager  │  │   CloudWatch   │  │  S3 (Logs)   │  │
│  └──────────┘  └──────────────────┘  └────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- An ACM certificate for HTTPS (in the same region)
- Docker image pushed to ECR (after initial deployment)

## Quick Start

### 1. Bootstrap State Management

Before using Terraform, create the S3 bucket and DynamoDB table for remote state:

```bash
# Make the script executable
chmod +x scripts/bootstrap-state.sh

# Run the bootstrap script
./scripts/bootstrap-state.sh <project-name> <region>

# Example:
./scripts/bootstrap-state.sh my-api us-east-1
```

### 2. Configure Backend

After bootstrapping, update `backend.tf` with your configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-api-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-api-terraform-locks"
    encrypt        = true
  }
}
```

### 3. Set Required Variables

Create a `terraform.tfvars` file or set environment variables:

```bash
# Required variables
export TF_VAR_project_name="my-api"
export TF_VAR_certificate_arn="arn:aws:acm:us-east-1:123456789:certificate/abc-123"

# Sensitive API keys (use environment variables)
export TF_VAR_supabase_url="https://xxx.supabase.co"
export TF_VAR_supabase_anon_key="your-anon-key"
export TF_VAR_supabase_service_role_key="your-service-role-key"
export TF_VAR_openai_api_key="sk-xxx"
export TF_VAR_gemini_api_key="xxx"
export TF_VAR_stripe_secret_key="sk_xxx"
export TF_VAR_stripe_webhook_secret="whsec_xxx"
export TF_VAR_brave_search_api_key="xxx"
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment (development environment)
terraform plan -var-file=environments/dev.tfvars

# Apply the configuration
terraform apply -var-file=environments/dev.tfvars
```

## Environment Configurations

The project includes pre-configured tfvars files for each environment:

| Environment | File | Description |
|-------------|------|-------------|
| Development | `environments/dev.tfvars` | Minimal resources, no Redis, single AZ |
| Staging | `environments/staging.tfvars` | Medium resources, optional Redis |
| Production | `environments/prod.tfvars` | Full resources, Multi-AZ, Redis enabled |

### Resource Sizing by Environment

| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| ECS CPU | 256 | 512 | 1024 |
| ECS Memory | 512 MB | 1024 MB | 2048 MB |
| ECS Tasks | 1 | 2 | 2 |
| RDS Instance | db.t3.micro | db.t3.small | db.t3.medium |
| RDS Multi-AZ | No | No | Yes |
| Redis | Disabled | Optional | Enabled |
| Redis Node | cache.t3.micro | cache.t3.micro | cache.t3.small |

## Deployment Commands

```bash
# Development
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Staging
terraform plan -var-file=environments/staging.tfvars
terraform apply -var-file=environments/staging.tfvars

# Production
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

## Required Input Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `project_name` | Name of the project (used in resource naming) | Yes |
| `environment` | Deployment environment (dev, staging, prod) | Yes |
| `certificate_arn` | ARN of ACM certificate for HTTPS | Yes |
| `supabase_url` | Supabase project URL | Yes |
| `supabase_anon_key` | Supabase anonymous key | Yes |
| `supabase_service_role_key` | Supabase service role key | Yes |
| `openai_api_key` | OpenAI API key | Yes |
| `gemini_api_key` | Google Gemini API key | Yes |
| `stripe_secret_key` | Stripe secret key | Yes |
| `stripe_webhook_secret` | Stripe webhook secret | Yes |
| `brave_search_api_key` | Brave Search API key | Yes |

## Outputs

After deployment, Terraform outputs important values:

```bash
# Get all outputs
terraform output

# Get specific outputs
terraform output ecr_repository_url  # For CI/CD
terraform output alb_dns_name        # For DNS configuration
terraform output rds_endpoint        # Database endpoint
```

## CI/CD Integration

### Push Docker Image to ECR

```bash
# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Build and push image
docker build -t $ECR_URL:latest .
docker push $ECR_URL:latest

# Update ECS service to deploy new image
aws ecs update-service --cluster <cluster-name> --service <service-name> --force-new-deployment
```

## Security Features

- **WAF Protection**: AWS managed rules for common attacks and rate limiting
- **HTTPS Only**: HTTP redirects to HTTPS
- **Security Groups**: Layered security with least-privilege access
- **Secrets Manager**: All sensitive configuration stored securely
- **Encryption**: RDS and S3 encryption at rest
- **No NAT Gateway**: ECS tasks use public IPs (cost optimization)

## Monitoring

- **CloudWatch Logs**: ECS task logs with configurable retention
- **CloudWatch Alarms**: CPU, memory, and 5xx error rate alerts
- **ALB Access Logs**: Stored in S3 for analysis
- **WAF Logs**: Blocked requests logged to CloudWatch

## Cost Optimization

This architecture is optimized for cost:

1. **No NAT Gateway**: ECS tasks run in public subnets with public IPs
2. **Fargate Spot**: Development uses Fargate Spot for ~70% savings
3. **Right-sized Resources**: Environment-specific sizing
4. **Optional Redis**: Only enabled when needed

## Cleanup

To destroy all resources:

```bash
# Destroy infrastructure
terraform destroy -var-file=environments/dev.tfvars

# Note: S3 buckets with data may need manual cleanup
```

## Directory Structure

```
.
├── main.tf                 # Root module configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider versions
├── backend.tf              # S3 backend configuration
├── locals.tf               # Local values
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/
│   ├── vpc/
│   ├── security-groups/
│   ├── ecr/
│   ├── alb/
│   ├── ecs/
│   ├── rds/
│   ├── elasticache/
│   ├── secrets/
│   ├── waf/
│   ├── monitoring-prereq/
│   └── monitoring-alarms/
└── scripts/
    └── bootstrap-state.sh
```

## Troubleshooting

### ECS Tasks Not Starting

1. Check CloudWatch logs: `/ecs/<project>-<env>-api`
2. Verify ECR image exists and is accessible
3. Check security group rules
4. Verify secrets are populated in Secrets Manager

### Database Connection Issues

1. Verify RDS security group allows ECS security group
2. Check DATABASE_URL secret value
3. Ensure database is in the correct subnet group

### ALB Health Check Failures

1. Verify `/health` endpoint returns 200
2. Check ECS task logs for startup errors
3. Verify security group allows ALB to ECS on port 8080

## License

MIT
