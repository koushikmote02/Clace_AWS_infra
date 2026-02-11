# -----------------------------------------------------------------------------
# Development Environment Configuration
# -----------------------------------------------------------------------------

# General
environment = "dev"
# project_name = "your-project"  # Set via CLI or environment variable
# region       = "us-east-1"     # Default in variables.tf

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b"]

# ECS Configuration - Minimal sizing for development
ecs_cpu           = 256
ecs_memory        = 512
ecs_desired_count = 1
# ecs_image_tag   = "latest"  # Default in variables.tf

# RDS Configuration - Minimal sizing for development
rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_multi_az                = false
rds_backup_retention_period = 7
rds_deletion_protection     = false
database_name               = "appdb"

# ElastiCache Configuration - Disabled for development
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

# -----------------------------------------------------------------------------
# BTB EC2 Configuration - Disabled by default
# -----------------------------------------------------------------------------
# Uncomment and configure the following to deploy the btb-service EC2 instance.
# At minimum, set enable_btb_ec2 = true and provide SSH access via either
# btb_ssh_public_key or btb_key_pair_name, plus btb_ssh_cidr_blocks.
# -----------------------------------------------------------------------------

enable_btb_ec2        = true
btb_instance_type     = "t3.medium"
btb_root_volume_size  = 50
btb_ssh_cidr_blocks   = ["0.0.0.0/0"]          # Open for now, restrict later
btb_https_cidr_blocks = ["0.0.0.0/0"]          # GitHub webhooks need public access
btb_enable_user_data  = false

# btb_ssh_public_key - Set via environment variable TF_VAR_btb_ssh_public_key
