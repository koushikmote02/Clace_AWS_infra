# -----------------------------------------------------------------------------
# ECR Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates ECR repository with image scanning and lifecycle policy
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name                 = "${local.name_prefix}-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# -----------------------------------------------------------------------------
# ECR Lifecycle Policy
# -----------------------------------------------------------------------------
# Retains the last N images (default 30)

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECR Repository Policy (Optional - for cross-account access)
# -----------------------------------------------------------------------------
# Uncomment if you need to allow other AWS accounts to pull images

# resource "aws_ecr_repository_policy" "main" {
#   repository = aws_ecr_repository.main.name
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowPull"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::ACCOUNT_ID:root"
#         }
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "ecr:BatchCheckLayerAvailability"
#         ]
#       }
#     ]
#   })
# }
