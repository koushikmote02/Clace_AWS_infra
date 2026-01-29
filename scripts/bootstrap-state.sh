#!/bin/bash
# -----------------------------------------------------------------------------
# Bootstrap Terraform State Management Resources
# -----------------------------------------------------------------------------
# This script creates the S3 bucket and DynamoDB table required for
# Terraform remote state management with locking.
#
# Usage:
#   ./scripts/bootstrap-state.sh <project-name> <region>
#
# Example:
#   ./scripts/bootstrap-state.sh my-project us-east-1
# -----------------------------------------------------------------------------

set -e

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <project-name> <region>"
    echo "Example: $0 my-project us-east-1"
    exit 1
fi

PROJECT_NAME=$1
REGION=$2
BUCKET_NAME="${PROJECT_NAME}-terraform-state"
TABLE_NAME="${PROJECT_NAME}-terraform-locks"

echo "=============================================="
echo "Bootstrapping Terraform State Management"
echo "=============================================="
echo "Project Name: ${PROJECT_NAME}"
echo "Region: ${REGION}"
echo "S3 Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${TABLE_NAME}"
echo "=============================================="

# Create S3 bucket for state storage
echo ""
echo "Creating S3 bucket for Terraform state..."

if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    echo "Bucket ${BUCKET_NAME} already exists, skipping creation."
else
    if [ "${REGION}" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${REGION}"
    else
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${REGION}" \
            --create-bucket-configuration LocationConstraint="${REGION}"
    fi
    echo "Bucket ${BUCKET_NAME} created successfully."
fi

# Enable versioning on the bucket
echo ""
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled
echo "Versioning enabled."

# Enable server-side encryption
echo ""
echo "Enabling server-side encryption on S3 bucket..."
aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'
echo "Server-side encryption enabled."

# Block public access
echo ""
echo "Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
echo "Public access blocked."

# Create DynamoDB table for state locking
echo ""
echo "Creating DynamoDB table for state locking..."

if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${REGION}" 2>/dev/null; then
    echo "Table ${TABLE_NAME} already exists, skipping creation."
else
    aws dynamodb create-table \
        --table-name "${TABLE_NAME}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${REGION}"
    
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${REGION}"
    echo "Table ${TABLE_NAME} created successfully."
fi

echo ""
echo "=============================================="
echo "Bootstrap Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "1. Update backend.tf with your configuration:"
echo ""
echo "   terraform {"
echo "     backend \"s3\" {"
echo "       bucket         = \"${BUCKET_NAME}\""
echo "       key            = \"env/dev/terraform.tfstate\""
echo "       region         = \"${REGION}\""
echo "       dynamodb_table = \"${TABLE_NAME}\""
echo "       encrypt        = true"
echo "     }"
echo "   }"
echo ""
echo "2. Initialize Terraform with the new backend:"
echo "   terraform init -reconfigure"
echo ""
