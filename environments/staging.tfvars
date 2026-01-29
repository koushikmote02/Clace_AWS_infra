# -----------------------------------------------------------------------------
# Staging Environment Configuration
# -----------------------------------------------------------------------------

# General
environment = "staging"
# project_name = "your-project"  # Set via CLI or environment variable
# region       = "us-east-1"     # Default in variables.tf

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b"]

# ECS Configuration - Medium sizing for staging
ecs_cpu           = 512
ecs_memory        = 1024
ecs_desired_count = 2
# ecs_image_tag   = "latest"  # Default in variables.tf

# RDS Configuration - Medium sizing for staging
rds_instance_class          = "db.t3.small"
rds_allocated_storage       = 50
rds_multi_az                = false
rds_backup_retention_period = 7
rds_deletion_protection     = false
database_name               = "appdb"

# ElastiCache Configuration - Optional for staging
enable_redis    = false
redis_node_type = "cache.t3.micro"

# WAF Configuration
waf_rate_limit = 2000

# Monitoring Configuration
log_retention_days = 30

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
