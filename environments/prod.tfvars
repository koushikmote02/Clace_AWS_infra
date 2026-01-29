# -----------------------------------------------------------------------------
# Production Environment Configuration
# -----------------------------------------------------------------------------

# General
environment = "prod"
# project_name = "your-project"  # Set via CLI or environment variable
# region       = "us-east-1"     # Default in variables.tf

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

# ECS Configuration - Production sizing
ecs_cpu           = 1024
ecs_memory        = 2048
ecs_desired_count = 2
# ecs_image_tag   = "latest"  # Default in variables.tf

# RDS Configuration - Production sizing with high availability
rds_instance_class          = "db.t3.medium"
rds_allocated_storage       = 100
rds_multi_az                = true
rds_backup_retention_period = 14
rds_deletion_protection     = true
database_name               = "appdb"

# ElastiCache Configuration - Enabled for production
enable_redis    = true
redis_node_type = "cache.t3.small"

# WAF Configuration
waf_rate_limit = 2000

# Monitoring Configuration
log_retention_days = 90

# SSL Certificate ARN (required - set via CLI or environment variable)
# certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERTIFICATE_ID"

# -----------------------------------------------------------------------------
# Sensitive Variables - Set via environment variables or separate secure file
# -----------------------------------------------------------------------------
# TF_VAR_supabase_url
# TF_VAR_supabase_anon_key
# TF_VAR_supabase_service_role_key
# TF_VAR_openai_api_key
# TF_VAR_gemini_api_key
# TF_VAR_stripe_secret_key
# TF_VAR_stripe_webhook_secret
# TF_VAR_brave_search_api_key
