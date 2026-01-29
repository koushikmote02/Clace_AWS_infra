# -----------------------------------------------------------------------------
# ECR Module - Input Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "image_retention_count" {
  description = "Number of images to retain in the repository"
  type        = number
  default     = 30
}
