# -----------------------------------------------------------------------------
# Root Module - Main Configuration
# -----------------------------------------------------------------------------
# Wires all modules together with proper dependencies
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# -----------------------------------------------------------------------------
# Security Groups Module
# -----------------------------------------------------------------------------

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  enable_redis = var.enable_redis
}

# -----------------------------------------------------------------------------
# ECR Module
# -----------------------------------------------------------------------------

module "ecr" {
  source = "./modules/ecr"

  project_name          = var.project_name
  environment           = var.environment
  image_retention_count = 30
}

# -----------------------------------------------------------------------------
# Monitoring Pre-requisites (S3 bucket and log group needed before ALB/ECS)
# -----------------------------------------------------------------------------

module "monitoring_prereq" {
  source = "./modules/monitoring-prereq"

  project_name       = var.project_name
  environment        = var.environment
  log_retention_days = var.log_retention_days
}

# -----------------------------------------------------------------------------
# RDS Module
# -----------------------------------------------------------------------------

module "rds" {
  source = "./modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  db_subnet_group_name    = module.vpc.db_subnet_group_name
  security_group_id       = module.security_groups.rds_security_group_id
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
  database_name           = var.database_name
}

# -----------------------------------------------------------------------------
# ElastiCache Module (Conditional)
# -----------------------------------------------------------------------------

module "elasticache" {
  source = "./modules/elasticache"
  count  = var.enable_redis ? 1 : 0

  project_name                  = var.project_name
  environment                   = var.environment
  elasticache_subnet_group_name = module.vpc.elasticache_subnet_group_name
  security_group_id             = module.security_groups.redis_security_group_id
  node_type                     = var.redis_node_type
}

# -----------------------------------------------------------------------------
# Secrets Module
# -----------------------------------------------------------------------------

module "secrets" {
  source = "./modules/secrets"

  project_name              = var.project_name
  environment               = var.environment
  database_url              = module.rds.database_url
  redis_url                 = var.enable_redis ? module.elasticache[0].redis_url : ""
  supabase_url              = var.supabase_url
  supabase_anon_key         = var.supabase_anon_key
  supabase_service_role_key = var.supabase_service_role_key
  openai_api_key            = var.openai_api_key
  gemini_api_key            = var.gemini_api_key
  stripe_secret_key         = var.stripe_secret_key
  stripe_webhook_secret     = var.stripe_webhook_secret
  brave_search_api_key      = var.brave_search_api_key
}

# -----------------------------------------------------------------------------
# ALB Module
# -----------------------------------------------------------------------------

module "alb" {
  source = "./modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_id  = module.security_groups.alb_security_group_id
  certificate_arn    = var.certificate_arn
  access_logs_bucket = module.monitoring_prereq.alb_logs_bucket
  health_check_path  = var.health_check_path
}

# -----------------------------------------------------------------------------
# ECS Module
# -----------------------------------------------------------------------------

module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_id  = module.security_groups.ecs_security_group_id
  target_group_arn   = module.alb.target_group_arn
  ecr_repository_url = module.ecr.repository_url
  image_tag          = var.ecs_image_tag
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = var.ecs_desired_count
  secrets_arns       = module.secrets.secret_arns
  log_group_name     = module.monitoring_prereq.log_group_name
  health_check_path  = var.health_check_path
  cors_origins       = var.cors_origins
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms (after ECS and ALB are created)
# -----------------------------------------------------------------------------

module "monitoring_alarms" {
  source = "./modules/monitoring-alarms"

  project_name     = var.project_name
  environment      = var.environment
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
  alb_arn_suffix   = module.alb.alb_arn_suffix
}

# -----------------------------------------------------------------------------
# WAF Module
# -----------------------------------------------------------------------------

module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.alb.alb_arn
  rate_limit   = var.waf_rate_limit
}
