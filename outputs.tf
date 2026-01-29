# -----------------------------------------------------------------------------
# Root Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

# -----------------------------------------------------------------------------
# ECR Outputs
# -----------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "URL of the ECR repository for CI/CD integration"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

# -----------------------------------------------------------------------------
# ALB Outputs
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer for DNS configuration"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB for Route53 alias records"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

# -----------------------------------------------------------------------------
# RDS Outputs
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.rds.database_name
}

# -----------------------------------------------------------------------------
# ElastiCache Outputs (Conditional)
# -----------------------------------------------------------------------------

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint (null if Redis is disabled)"
  value       = var.enable_redis ? module.elasticache[0].endpoint : null
}

output "redis_port" {
  description = "ElastiCache Redis port (null if Redis is disabled)"
  value       = var.enable_redis ? module.elasticache[0].port : null
}

# -----------------------------------------------------------------------------
# ECS Outputs
# -----------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for ECS"
  value       = module.monitoring_prereq.log_group_name
}

output "alb_logs_bucket" {
  description = "Name of the S3 bucket for ALB access logs"
  value       = module.monitoring_prereq.alb_logs_bucket
}

# -----------------------------------------------------------------------------
# WAF Outputs
# -----------------------------------------------------------------------------

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.waf.web_acl_arn
}
