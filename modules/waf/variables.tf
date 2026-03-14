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

variable "geo_restrict_enabled" {
  description = "Enable geo-restriction to allowed countries only"
  type        = bool
  default     = false
}

variable "allowed_country_codes" {
  description = "List of ISO 3166-1 alpha-2 country codes to allow (blocks all others when geo_restrict_enabled is true)"
  type        = list(string)
  default     = ["US", "CA", "MX"]
}
