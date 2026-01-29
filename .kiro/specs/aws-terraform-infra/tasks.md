# Implementation Plan: AWS Terraform Infrastructure

## Overview

This plan implements the AWS Terraform infrastructure for deploying a Rust Axum API. Tasks are organized by module, with property tests integrated close to implementation. The infrastructure uses HCL (Terraform's native language).

## Tasks

- [x] 1. Set up Terraform project structure and bootstrap state management
  - [x] 1.1 Create directory structure with modules/, environments/, scripts/ folders
    - Create terraform/ root directory
    - Create all module subdirectories as defined in design
    - _Requirements: 12.2_
  
  - [x] 1.2 Create versions.tf with Terraform and AWS provider version constraints
    - Terraform >= 1.5.0
    - AWS provider >= 5.0
    - _Requirements: 12.1_
  
  - [x] 1.3 Create variables.tf with all root-level input variables
    - project_name, environment, region, vpc_cidr, availability_zones
    - ECS, RDS, Redis configuration variables
    - SSL certificate ARN, API keys as sensitive variables
    - _Requirements: 12.1_
  
  - [x] 1.4 Create locals.tf with naming conventions and common tags
    - name_prefix = "${var.project_name}-${var.environment}"
    - common_tags map
    - _Requirements: 12.5_
  
  - [x] 1.5 Create backend.tf with S3 backend configuration (commented template)
    - S3 bucket, key, region, DynamoDB table, encrypt = true
    - _Requirements: 11.1, 11.2, 11.4_
  
  - [x] 1.6 Create scripts/bootstrap-state.sh to provision state management resources
    - Create S3 bucket with versioning
    - Create DynamoDB table for locking
    - _Requirements: 11.3_
  
  - [x] 1.7 Create environment tfvars files (dev.tfvars, staging.tfvars, prod.tfvars)
    - Configure resource sizing per environment as specified in design
    - _Requirements: 12.2, 12.3, 12.4_

- [x] 2. Implement VPC module
  - [x] 2.1 Create modules/vpc/main.tf with VPC, subnets, IGW, route tables
    - VPC with configurable CIDR
    - Public subnets across AZs with map_public_ip_on_launch = true
    - Database subnets across AZs (private)
    - Internet Gateway attached to VPC
    - Route table with 0.0.0.0/0 -> IGW for public subnets
    - NO NAT Gateway resources
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_
  
  - [x] 2.2 Create modules/vpc/variables.tf and outputs.tf
    - Inputs: project_name, environment, vpc_cidr, availability_zones
    - Outputs: vpc_id, public_subnet_ids, database_subnet_ids, internet_gateway_id
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [ ]* 2.3 Write property test: No NAT Gateway creation
    - **Property 1: No NAT Gateway Creation**
    - Verify terraform plan contains no aws_nat_gateway resources
    - **Validates: Requirements 1.6**
  
  - [ ]* 2.4 Write property test: Subnet count matches AZ count
    - **Property 2: Subnet Count Matches Availability Zone Count**
    - Verify public_subnet count == len(availability_zones)
    - Verify database_subnet count == len(availability_zones)
    - **Validates: Requirements 1.2, 1.3**

- [x] 3. Implement Security Groups module
  - [x] 3.1 Create modules/security-groups/main.tf with all security groups
    - ALB SG: ingress 80, 443 from 0.0.0.0/0
    - ECS SG: ingress 8080 from ALB SG, egress all to 0.0.0.0/0
    - RDS SG: ingress 5432 from ECS SG
    - Redis SG (conditional): ingress 6379 from ECS SG
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [x] 3.2 Create modules/security-groups/variables.tf and outputs.tf
    - Inputs: project_name, environment, vpc_id, enable_redis
    - Outputs: alb_security_group_id, ecs_security_group_id, rds_security_group_id, redis_security_group_id
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 4. Implement ECR module
  - [x] 4.1 Create modules/ecr/main.tf with repository and lifecycle policy
    - ECR repository with image scanning on push
    - Lifecycle policy retaining last 30 images
    - _Requirements: 2.1, 2.2, 2.3_
  
  - [x] 4.2 Create modules/ecr/variables.tf and outputs.tf
    - Inputs: project_name, environment, image_retention_count
    - Outputs: repository_url, repository_arn
    - _Requirements: 2.4_

- [x] 5. Checkpoint - Verify base infrastructure modules
  - Ensure terraform validate passes for vpc, security-groups, ecr modules
  - Ask the user if questions arise

- [-] 6. Implement Secrets module
  - [x] 6.1 Create modules/secrets/main.tf with all Secrets Manager secrets
    - Create secrets for: DATABASE_URL, REDIS_URL (conditional), SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, OPENAI_API_KEY, GEMINI_API_KEY, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, BRAVE_SEARCH_API_KEY
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  
  - [x] 6.2 Create modules/secrets/variables.tf and outputs.tf
    - Inputs: all API keys and constructed URLs
    - Outputs: secret_arns map
    - _Requirements: 8.1, 8.5_
  
  - [ ] 6.3 Write property test: Required secrets completeness
    - **Property 6: Required Secrets Completeness**
    - Verify all 9 required secrets are created in plan
    - **Validates: Requirements 8.1, 8.4**

- [-] 7. Implement RDS module
  - [x] 7.1 Create modules/rds/main.tf with PostgreSQL instance
    - RDS PostgreSQL in database subnet group
    - Instance class from variable
    - Multi-AZ from variable (true for prod)
    - Automated backups with retention period
    - Deletion protection from variable
    - Store credentials in Secrets Manager
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_
  
  - [x] 7.2 Create modules/rds/variables.tf and outputs.tf
    - Inputs: project_name, environment, database_subnet_ids, security_group_id, instance_class, multi_az, backup_retention_period, deletion_protection
    - Outputs: endpoint, database_name, master_password_secret_arn
    - _Requirements: 5.1, 5.5_
  
  - [ ] 7.3 Write property test: Production Multi-AZ enforcement
    - **Property 4: Production Multi-AZ Enforcement**
    - Verify multi_az = true when environment = "prod"
    - **Validates: Requirements 5.2**

- [-] 8. Implement ElastiCache module
  - [x] 8.1 Create modules/elasticache/main.tf with Redis cluster (conditional)
    - ElastiCache Redis cluster in database subnets
    - Node type from variable
    - Subnet group using database subnets
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [x] 8.2 Create modules/elasticache/variables.tf and outputs.tf
    - Inputs: project_name, environment, database_subnet_ids, security_group_id, node_type
    - Outputs: endpoint, port
    - _Requirements: 6.4_
  
  - [ ] 8.3 Write property test: Redis conditional creation
    - **Property 5: Redis Conditional Resource Creation**
    - Verify ElastiCache exists when enable_redis = true
    - Verify ElastiCache absent when enable_redis = false
    - **Validates: Requirements 6.1**

- [x] 9. Checkpoint - Verify data layer modules
  - Ensure terraform validate passes for secrets, rds, elasticache modules
  - Ask the user if questions arise

- [x] 10. Implement ALB module
  - [x] 10.1 Create modules/alb/main.tf with load balancer and listeners
    - ALB in public subnets
    - HTTPS listener on 443 with SSL certificate
    - HTTP listener on 80 with redirect to HTTPS
    - Target group on port 8080 with /health health check
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [x] 10.2 Create modules/alb/variables.tf and outputs.tf
    - Inputs: project_name, environment, vpc_id, public_subnet_ids, security_group_id, certificate_arn, access_logs_bucket, health_check_path
    - Outputs: alb_arn, alb_dns_name, target_group_arn, https_listener_arn
    - _Requirements: 4.6_

- [-] 11. Implement ECS module
  - [x] 11.1 Create modules/ecs/main.tf with cluster, task definition, service
    - ECS cluster
    - Task definition with CPU/memory from variables
    - Container definition referencing ECR image
    - Secrets injection from Secrets Manager ARNs
    - CloudWatch log configuration
    - Health check on /health
    - Service with public IP assignment
    - Target group registration
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_
  
  - [x] 11.2 Create IAM roles for ECS task execution and task role
    - Execution role with ECR pull and Secrets Manager read permissions
    - Task role for application permissions
    - _Requirements: 8.5_
  
  - [x] 11.3 Create modules/ecs/variables.tf and outputs.tf
    - Inputs: project_name, environment, vpc_id, public_subnet_ids, security_group_id, target_group_arn, ecr_repository_url, cpu, memory, desired_count, secrets_arns, log_group_name
    - Outputs: cluster_arn, service_name, task_definition_arn
    - _Requirements: 3.1, 3.4_
  
  - [ ]* 11.4 Write property test: Environment-based resource sizing
    - **Property 3: Environment-Based Resource Sizing**
    - Verify ECS CPU/memory matches environment expectations
    - Test with dev, staging, prod tfvars
    - **Validates: Requirements 3.3, 5.3, 6.2, 12.3, 12.4**
  
  - [ ]* 11.5 Write property test: ECS task secret references
    - **Property 7: ECS Task Secret References**
    - Verify task definition secrets block contains all required secret ARNs
    - **Validates: Requirements 3.7**

- [x] 12. Implement WAF module
  - [x] 12.1 Create modules/waf/main.tf with Web ACL and rules
    - WAF Web ACL
    - AWS managed rules: CommonRuleSet, KnownBadInputsRuleSet
    - Rate limiting rule (default 2000 per 5 min)
    - Associate with ALB
    - _Requirements: 9.1, 9.2, 9.3_
  
  - [x] 12.2 Create modules/waf/variables.tf and outputs.tf
    - Inputs: project_name, environment, alb_arn, rate_limit
    - Outputs: web_acl_arn
    - _Requirements: 9.1_

- [x] 13. Implement Monitoring module
  - [x] 13.1 Create modules/monitoring/main.tf with CloudWatch and S3
    - CloudWatch log group for ECS
    - S3 bucket for ALB access logs with proper bucket policy
    - CloudWatch alarms: CPU > 80%, Memory > 80%, 5xx > 5%
    - _Requirements: 10.1, 10.3, 10.5_
  
  - [x] 13.2 Create modules/monitoring/variables.tf and outputs.tf
    - Inputs: project_name, environment, ecs_cluster_name, ecs_service_name, alb_arn_suffix, log_retention_days
    - Outputs: log_group_name, alb_logs_bucket
    - _Requirements: 10.1, 10.3_

- [x] 14. Checkpoint - Verify application layer modules
  - Ensure terraform validate passes for alb, ecs, waf, monitoring modules
  - Ask the user if questions arise

- [-] 15. Wire all modules together in root main.tf
  - [x] 15.1 Create main.tf with all module calls and dependencies
    - Call vpc module
    - Call security-groups module with vpc outputs
    - Call ecr module
    - Call monitoring module (needed for log group before ECS)
    - Call secrets module with constructed URLs
    - Call rds module with vpc and security-groups outputs
    - Call elasticache module (conditional) with vpc and security-groups outputs
    - Call alb module with vpc, security-groups, monitoring outputs
    - Call ecs module with all dependencies
    - Call waf module with alb output
    - _Requirements: All_
  
  - [x] 15.2 Create outputs.tf with key infrastructure outputs
    - ALB DNS name
    - ECR repository URL
    - RDS endpoint
    - Redis endpoint (conditional)
    - CloudWatch log group name
    - _Requirements: 2.4, 4.6, 6.4_
  
  - [ ]* 15.3 Write property test: Consistent naming convention
    - **Property 8: Consistent Naming Convention**
    - Verify all resource names follow {project}-{environment}-{resource} pattern
    - **Validates: Requirements 12.5**

- [x] 16. Final validation and documentation
  - [x] 16.1 Run terraform validate and fmt on entire project
    - Fix any validation errors
    - Ensure consistent formatting
    - _Requirements: All_
  
  - [x] 16.2 Create README.md with usage instructions
    - Prerequisites (AWS CLI, Terraform)
    - Bootstrap state management steps
    - Deployment commands per environment
    - Required input variables
    - _Requirements: 11.1, 11.2, 12.1_

- [x] 17. Final checkpoint - Ensure all tests pass
  - Run terraform validate on complete configuration
  - Run terraform plan with each environment tfvars
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional property tests that can be skipped for faster MVP
- Required property tests (6.3, 7.3, 8.3) validate critical infrastructure constraints
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests use Terratest (Go) for terraform plan inspection
- All modules follow consistent interface patterns from design document
