# -----------------------------------------------------------------------------
# ALB Module - Input Variables
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
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS (optional - leave empty for HTTP only)"
  type        = string
  default     = ""
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}
