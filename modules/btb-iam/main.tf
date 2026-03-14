# -----------------------------------------------------------------------------
# BTB IAM Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates IAM role with EC2 trust policy, Bedrock permissions, and instance
# profile for the btb-service EC2 instance.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "btb_service" {
  name = "${local.name_prefix}-btb-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-btb-service-role"
  }
}

# -----------------------------------------------------------------------------
# Bedrock Inline Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "btb_bedrock" {
  name = "${local.name_prefix}-btb-bedrock-policy"
  role = aws_iam_role.btb_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CodeDeploy Inline Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "btb_codedeploy" {
  name = "${local.name_prefix}-btb-codedeploy-policy"
  role = aws_iam_role.btb_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy-commands-secure:GetDeploymentSpecification",
          "codedeploy-commands-secure:PollHostCommand",
          "codedeploy-commands-secure:PutHostCommandAcknowledgement",
          "codedeploy-commands-secure:PutHostCommandComplete"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::aws-codedeploy-*",
          "arn:aws:s3:::aws-codedeploy-*/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CodeCommit Inline Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "btb_codecommit" {
  name = "${local.name_prefix}-btb-codecommit-policy"
  role = aws_iam_role.btb_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull",
          "codecommit:GetRepository",
          "codecommit:GetBranch",
          "codecommit:ListRepositories",
          "codecommit:BatchGetRepositories"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Instance Profile
# -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "btb_service" {
  name = "${local.name_prefix}-btb-service-profile"
  role = aws_iam_role.btb_service.name

  tags = {
    Name = "${local.name_prefix}-btb-service-profile"
  }
}
