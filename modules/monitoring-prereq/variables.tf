# -----------------------------------------------------------------------------
# Monitoring Pre-requisites Module - Input Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}
