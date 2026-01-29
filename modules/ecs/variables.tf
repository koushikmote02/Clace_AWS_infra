# -----------------------------------------------------------------------------
# ECS Module - Input Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ECS tasks"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MB) for the task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "secrets_arns" {
  description = "Map of secret names to their ARNs"
  type = object({
    database_url              = string
    redis_url                 = optional(string)
    supabase_url              = string
    supabase_anon_key         = string
    supabase_service_role_key = string
    openai_api_key            = string
    gemini_api_key            = string
    stripe_secret_key         = string
    stripe_webhook_secret     = string
    brave_search_api_key      = string
  })
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "health_check_path" {
  description = "Health check path for the container"
  type        = string
  default     = "/health"
}
