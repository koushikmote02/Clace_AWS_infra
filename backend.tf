# -----------------------------------------------------------------------------
# Terraform Backend Configuration
# -----------------------------------------------------------------------------
# 
# This backend configuration stores Terraform state in S3 with DynamoDB locking.
# Before using this backend, run the bootstrap script to create the required resources:
#   ./scripts/bootstrap-state.sh
#
# After bootstrapping, uncomment the backend block below and run:
#   terraform init -reconfigure
#
# -----------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     # S3 bucket for state storage (created by bootstrap script)
#     bucket = "YOUR_PROJECT_NAME-terraform-state"
#     
#     # State file path within the bucket
#     # Use different keys for different environments
#     key = "env/dev/terraform.tfstate"
#     
#     # AWS region where the S3 bucket is located
#     region = "us-east-1"
#     
#     # DynamoDB table for state locking (created by bootstrap script)
#     dynamodb_table = "YOUR_PROJECT_NAME-terraform-locks"
#     
#     # Enable server-side encryption for state file
#     encrypt = true
#   }
# }

# -----------------------------------------------------------------------------
# Backend Configuration Examples per Environment
# -----------------------------------------------------------------------------
#
# Development:
#   key = "env/dev/terraform.tfstate"
#
# Staging:
#   key = "env/staging/terraform.tfstate"
#
# Production:
#   key = "env/prod/terraform.tfstate"
#
# -----------------------------------------------------------------------------
