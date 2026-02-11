# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-2"
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

# -----------------------------------------------------------------------------
# ECS Configuration
# -----------------------------------------------------------------------------

variable "ecs_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_cpu)
    error_message = "ECS CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "ecs_memory" {
  description = "Memory (MB) for ECS task"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "health_check_path" {
  description = "Health check path for ALB and ECS"
  type        = string
  default     = "/health"
}

# -----------------------------------------------------------------------------
# RDS Configuration
# -----------------------------------------------------------------------------

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

# -----------------------------------------------------------------------------
# ElastiCache Configuration
# -----------------------------------------------------------------------------

variable "enable_redis" {
  description = "Enable ElastiCache Redis cluster"
  type        = bool
  default     = false
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

# -----------------------------------------------------------------------------
# SSL/TLS Configuration
# -----------------------------------------------------------------------------

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS (optional - leave empty for HTTP only)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# WAF Configuration
# -----------------------------------------------------------------------------

variable "waf_rate_limit" {
  description = "WAF rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Sensitive API Keys (passed via environment variables or tfvars)
# -----------------------------------------------------------------------------

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_anon_key" {
  description = "Supabase anonymous key"
  type        = string
  sensitive   = true
}

variable "supabase_service_role_key" {
  description = "Supabase service role key"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API key"
  type        = string
  sensitive   = true
}

variable "stripe_secret_key" {
  description = "Stripe secret key"
  type        = string
  sensitive   = true
}

variable "stripe_webhook_secret" {
  description = "Stripe webhook secret"
  type        = string
  sensitive   = true
}

variable "brave_search_api_key" {
  description = "Brave Search API key"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

variable "cors_origins" {
  description = "Comma-separated list of allowed CORS origins for the backend"
  type        = string
  default     = "http://localhost:1420,tauri://localhost,https://tauri.localhost"
}

# -----------------------------------------------------------------------------
# BTB EC2 Configuration
# -----------------------------------------------------------------------------

variable "enable_btb_ec2" {
  description = "Enable btb-service EC2 instance and related resources"
  type        = bool
  default     = false
}

variable "btb_instance_type" {
  description = "EC2 instance type for btb-service"
  type        = string
  default     = "t3.medium"
}

variable "btb_root_volume_size" {
  description = "Root EBS volume size in GB for btb-service EC2 instance"
  type        = number
  default     = 50
}

variable "btb_ssh_public_key" {
  description = "SSH public key for btb-service EC2 instance access (creates a new key pair)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "btb_key_pair_name" {
  description = "Existing AWS key pair name for btb-service EC2 instance (used if btb_ssh_public_key is empty)"
  type        = string
  default     = ""
}

variable "btb_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access to btb-service EC2 instance"
  type        = list(string)
  default     = []
}

variable "btb_https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS (port 8443) access to btb-service EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "btb_repo_url" {
  description = "Git repository URL for btb (used in user_data provisioning)"
  type        = string
  default     = ""
}

variable "btb_enable_user_data" {
  description = "Enable automated provisioning via EC2 user_data on first boot"
  type        = bool
  default     = false
}
