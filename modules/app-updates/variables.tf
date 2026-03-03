# -----------------------------------------------------------------------------
# App Updates Module - Input Variables
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "updates_domain_name" {
  description = "Custom domain name for the updates CDN (e.g., updates.clace.ai)"
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repositories in format 'owner/repo' for OIDC trust policy"
  type        = list(string)
  default     = ["koushikmote02/Client"]
}

variable "enable_github_oidc" {
  description = "Whether to create GitHub OIDC provider (set false if already exists in account)"
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = "ARN of existing GitHub OIDC provider (required if enable_github_oidc is false)"
  type        = string
  default     = ""
}

variable "acm_certificate_validated" {
  description = "Set to true after the ACM certificate has been validated via DNS at Porkbun"
  type        = bool
  default     = false
}
