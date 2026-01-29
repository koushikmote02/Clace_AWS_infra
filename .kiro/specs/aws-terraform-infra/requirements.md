# Requirements Document

## Introduction

This document defines the requirements for deploying a Rust Axum API application to AWS using Terraform. The infrastructure prioritizes cost efficiency by avoiding NAT Gateways while maintaining security through properly configured security groups and AWS WAF. The deployment supports environment-based configuration (dev/staging/prod) with remote state management.

## Glossary

- **Terraform_Module**: A reusable Terraform configuration that encapsulates related infrastructure resources
- **ECS_Fargate**: AWS managed container orchestration service running containers without managing servers
- **ALB**: Application Load Balancer that distributes incoming HTTP/HTTPS traffic
- **RDS_PostgreSQL**: AWS managed PostgreSQL database service
- **ElastiCache_Redis**: AWS managed Redis service for caching and rate limiting
- **WAF**: Web Application Firewall that filters malicious web traffic
- **Secrets_Manager**: AWS service for securely storing and retrieving sensitive configuration
- **ECR**: Elastic Container Registry for storing Docker container images
- **VPC**: Virtual Private Cloud providing isolated network infrastructure
- **Security_Group**: Virtual firewall controlling inbound and outbound traffic rules

## Requirements

### Requirement 1: VPC Network Infrastructure

**User Story:** As a DevOps engineer, I want a properly configured VPC with public and database subnets, so that I can deploy application containers with internet access while isolating database resources.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create a VPC with a configurable CIDR block (default 10.0.0.0/16)
2. WHEN the VPC is created, THE Terraform_Module SHALL provision public subnets across multiple availability zones
3. WHEN the VPC is created, THE Terraform_Module SHALL provision database subnets (private) across multiple availability zones
4. THE Terraform_Module SHALL create an Internet Gateway attached to the VPC
5. THE Terraform_Module SHALL configure route tables directing public subnet traffic through the Internet Gateway
6. THE Terraform_Module SHALL NOT create NAT Gateways to minimize infrastructure costs

### Requirement 2: Container Registry and Image Management

**User Story:** As a developer, I want a container registry to store Docker images, so that ECS can pull and deploy the application.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create an ECR repository for the application container images
2. WHEN the ECR repository is created, THE Terraform_Module SHALL configure image scanning on push
3. THE Terraform_Module SHALL configure an image lifecycle policy to retain the last 30 images
4. THE Terraform_Module SHALL output the ECR repository URL for CI/CD integration

### Requirement 3: ECS Fargate Deployment

**User Story:** As a DevOps engineer, I want ECS Fargate tasks running in public subnets with public IPs, so that containers can access external APIs without NAT Gateway costs.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create an ECS cluster for the application
2. THE Terraform_Module SHALL create an ECS task definition referencing the ECR image
3. WHEN the task definition is created, THE Terraform_Module SHALL configure CPU and memory based on environment (dev: 256/512, staging: 512/1024, prod: 1024/2048)
4. THE Terraform_Module SHALL create an ECS service with configurable desired count
5. WHEN the ECS service is deployed, THE Terraform_Module SHALL assign public IP addresses to tasks
6. THE Terraform_Module SHALL configure the ECS service to register targets with the ALB target group
7. WHEN the ECS task starts, THE Terraform_Module SHALL inject environment variables from Secrets Manager
8. THE Terraform_Module SHALL configure health check path as /health with appropriate intervals

### Requirement 4: Application Load Balancer with HTTPS

**User Story:** As a DevOps engineer, I want an ALB with HTTPS termination, so that users can securely access the API through a single endpoint.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create an Application Load Balancer in public subnets
2. THE Terraform_Module SHALL create an HTTPS listener on port 443 with the provided SSL certificate ARN
3. THE Terraform_Module SHALL create an HTTP listener on port 80 that redirects to HTTPS
4. THE Terraform_Module SHALL create a target group for ECS tasks on port 8080
5. WHEN configuring the target group, THE Terraform_Module SHALL set health check path to /health
6. THE Terraform_Module SHALL output the ALB DNS name for DNS configuration

### Requirement 5: RDS PostgreSQL Database

**User Story:** As a developer, I want a managed PostgreSQL database, so that the application has persistent data storage with automated backups.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create an RDS PostgreSQL instance in database subnets
2. WHEN the environment is prod, THE Terraform_Module SHALL enable Multi-AZ deployment
3. THE Terraform_Module SHALL configure instance class based on environment (dev: db.t3.micro, staging: db.t3.small, prod: db.t3.medium)
4. THE Terraform_Module SHALL enable automated backups with configurable retention period (default 7 days)
5. THE Terraform_Module SHALL store database credentials in Secrets Manager
6. THE Terraform_Module SHALL create a database subnet group using the database subnets
7. IF deletion protection is enabled, THEN THE Terraform_Module SHALL prevent accidental database deletion

### Requirement 6: ElastiCache Redis (Optional)

**User Story:** As a developer, I want an optional Redis cache, so that the application can implement rate limiting when needed.

#### Acceptance Criteria

1. WHERE Redis is enabled, THE Terraform_Module SHALL create an ElastiCache Redis cluster
2. WHERE Redis is enabled, THE Terraform_Module SHALL configure node type based on environment (dev: cache.t3.micro, prod: cache.t3.small)
3. WHERE Redis is enabled, THE Terraform_Module SHALL place the cluster in database subnets
4. WHERE Redis is enabled, THE Terraform_Module SHALL output the Redis endpoint for application configuration

### Requirement 7: Security Groups

**User Story:** As a security engineer, I want properly configured security groups, so that network access is restricted to only necessary traffic.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create an ALB security group allowing inbound HTTP (80) and HTTPS (443) from anywhere
2. THE Terraform_Module SHALL create an ECS security group allowing inbound traffic only from the ALB security group on port 8080
3. THE Terraform_Module SHALL create an RDS security group allowing inbound PostgreSQL (5432) only from the ECS security group
4. WHERE Redis is enabled, THE Terraform_Module SHALL create a Redis security group allowing inbound (6379) only from the ECS security group
5. WHEN security groups are created, THE Terraform_Module SHALL allow all outbound traffic from ECS tasks for external API access

### Requirement 8: Secrets Management

**User Story:** As a security engineer, I want sensitive configuration stored in Secrets Manager, so that API keys and credentials are not exposed in code or environment variables.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create Secrets Manager secrets for all sensitive environment variables
2. THE Terraform_Module SHALL store DATABASE_URL constructed from RDS endpoint and credentials
3. WHERE Redis is enabled, THE Terraform_Module SHALL store REDIS_URL constructed from ElastiCache endpoint
4. THE Terraform_Module SHALL accept and store external API keys: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, OPENAI_API_KEY, GEMINI_API_KEY, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, BRAVE_SEARCH_API_KEY
5. THE Terraform_Module SHALL grant ECS task execution role permission to read secrets

### Requirement 9: WAF and Security

**User Story:** As a security engineer, I want WAF protection on the ALB, so that the API is protected from common web attacks.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create a WAF Web ACL associated with the ALB
2. THE Terraform_Module SHALL enable AWS managed rule groups: AWSManagedRulesCommonRuleSet, AWSManagedRulesKnownBadInputsRuleSet
3. THE Terraform_Module SHALL configure rate limiting rule (default 2000 requests per 5 minutes per IP)
4. THE Terraform_Module SHALL enable AWS Shield Standard (automatically included with WAF)

### Requirement 10: Monitoring and Logging

**User Story:** As a DevOps engineer, I want centralized logging and monitoring, so that I can troubleshoot issues and track application health.

#### Acceptance Criteria

1. THE Terraform_Module SHALL create a CloudWatch log group for ECS task logs
2. THE Terraform_Module SHALL configure ECS tasks to send logs to CloudWatch
3. THE Terraform_Module SHALL create an S3 bucket for ALB access logs
4. THE Terraform_Module SHALL configure the ALB to write access logs to S3
5. THE Terraform_Module SHALL create CloudWatch alarms for: ECS CPU utilization > 80%, ECS memory utilization > 80%, ALB 5xx error rate > 5%

### Requirement 11: Terraform State Management

**User Story:** As a DevOps engineer, I want remote state management with locking, so that multiple team members can safely collaborate on infrastructure changes.

#### Acceptance Criteria

1. THE Terraform_Module SHALL document S3 backend configuration for state storage
2. THE Terraform_Module SHALL document DynamoDB table configuration for state locking
3. THE Terraform_Module SHALL provide a bootstrap script to create state management resources
4. THE Terraform_Module SHALL configure state file encryption at rest

### Requirement 12: Environment Configuration

**User Story:** As a DevOps engineer, I want environment-specific configurations, so that I can deploy to dev, staging, and prod with appropriate resource sizing.

#### Acceptance Criteria

1. THE Terraform_Module SHALL accept an environment variable (dev, staging, prod)
2. THE Terraform_Module SHALL provide tfvars files for each environment
3. WHEN environment is dev, THE Terraform_Module SHALL use minimal resource sizing
4. WHEN environment is prod, THE Terraform_Module SHALL enable Multi-AZ and larger instance sizes
5. THE Terraform_Module SHALL use consistent naming convention: {project}-{environment}-{resource}
