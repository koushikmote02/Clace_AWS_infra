# -----------------------------------------------------------------------------
# Monitoring Alarms Module - Input Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster for CloudWatch alarms"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service for CloudWatch alarms"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metrics"
  type        = string
}
