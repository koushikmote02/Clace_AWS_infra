# -----------------------------------------------------------------------------
# BTB EC2 Module - Input Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the instance"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach to the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 50
}

variable "ssh_public_key" {
  description = "SSH public key material (creates a new key pair if provided)"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Name of an existing key pair (used if ssh_public_key is empty)"
  type        = string
  default     = ""
}

variable "btb_repo_url" {
  description = "Git URL for the btb repository (used in user_data)"
  type        = string
  default     = ""
}

variable "enable_user_data" {
  description = "Enable automated provisioning via user_data on first boot"
  type        = bool
  default     = false
}
