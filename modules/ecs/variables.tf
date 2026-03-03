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
    anthropic_api_key         = optional(string)
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

variable "cors_origins" {
  description = "Comma-separated list of allowed CORS origins"
  type        = string
  default     = ""
}

variable "stripe_trial_period_days" {
  description = "Number of days for Stripe free trial period"
  type        = number
  default     = 30
}

variable "stripe_account_id" {
  description = "Stripe account ID"
  type        = string
  default     = ""
}

variable "stripe_success_url" {
  description = "URL to redirect to after successful Stripe checkout"
  type        = string
}

variable "stripe_cancel_url" {
  description = "URL to redirect to after cancelled Stripe checkout"
  type        = string
}

variable "stripe_price_p1" {
  description = "Stripe Price ID for Plan 1 (Pro)"
  type        = string
  default     = ""
}

variable "stripe_price_p2" {
  description = "Stripe Price ID for Plan 2 (Enterprise)"
  type        = string
  default     = ""
}

variable "supabase_project_url" {
  description = "Original Supabase project URL for JWT issuer validation (e.g., https://xxx.supabase.co)"
  type        = string
  default     = ""
}
