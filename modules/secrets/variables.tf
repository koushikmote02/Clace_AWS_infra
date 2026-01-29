# -----------------------------------------------------------------------------
# Secrets Module - Input Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------

variable "database_url" {
  description = "Database connection URL (constructed from RDS endpoint)"
  type        = string
  sensitive   = true
}

variable "redis_url" {
  description = "Redis connection URL (constructed from ElastiCache endpoint)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Supabase Configuration
# -----------------------------------------------------------------------------

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_anon_key" {
  description = "Supabase anonymous key"
  type        = string
  sensitive   = true
}

variable "supabase_service_role_key" {
  description = "Supabase service role key"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# AI API Keys
# -----------------------------------------------------------------------------

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API key"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Stripe Configuration
# -----------------------------------------------------------------------------

variable "stripe_secret_key" {
  description = "Stripe secret key"
  type        = string
  sensitive   = true
}

variable "stripe_webhook_secret" {
  description = "Stripe webhook secret"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Search API
# -----------------------------------------------------------------------------

variable "brave_search_api_key" {
  description = "Brave Search API key"
  type        = string
  sensitive   = true
}
