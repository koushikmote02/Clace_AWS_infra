# -----------------------------------------------------------------------------
# Security Groups Module - Input Variables
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
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "enable_redis" {
  description = "Whether to create Redis security group"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# BTB EC2 Variables
# -----------------------------------------------------------------------------

variable "enable_btb_ec2" {
  description = "Whether to create btb EC2 security group"
  type        = bool
  default     = false
}

variable "btb_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access to btb EC2 instance"
  type        = list(string)
  default     = []
}

variable "btb_https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS (port 8443) access to btb EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
