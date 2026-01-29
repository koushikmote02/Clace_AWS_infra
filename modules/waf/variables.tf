# -----------------------------------------------------------------------------
# WAF Module - Input Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to protect"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}
