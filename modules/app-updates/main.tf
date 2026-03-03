# -----------------------------------------------------------------------------
# App Updates Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates S3 bucket, CloudFront distribution, ACM certificate, and IAM role
# for GitHub Actions CI/CD to serve Tauri desktop app auto-update artifacts.
#
# DNS is managed externally (e.g., Porkbun). After apply, you need to:
#   1. Add the ACM validation CNAME record at your DNS provider
#   2. Add a CNAME for updates_domain_name → cloudfront_domain_name
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  bucket_name = "${var.project_name}-app-updates"
}

# -----------------------------------------------------------------------------
# S3 Bucket for Update Artifacts
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "app_updates" {
  bucket = local.bucket_name

  tags = {
    Name = "${local.name_prefix}-app-updates"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_updates" {
  bucket = aws_s3_bucket.app_updates.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_updates" {
  bucket = aws_s3_bucket.app_updates.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_updates" {
  bucket = aws_s3_bucket.app_updates.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - Allow CloudFront OAC Access
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "app_updates" {
  bucket = aws_s3_bucket.app_updates.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.app_updates.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.app_updates.arn
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Control
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "app_updates" {
  name                              = "${local.name_prefix}-app-updates-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# ACM Certificate (us-east-1 required for CloudFront)
# After apply, add the CNAME from acm_validation_records output at Porkbun.
# The certificate will stay in "pending validation" until you do.
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "updates" {
  provider          = aws.us_east_1
  domain_name       = var.updates_domain_name
  validation_method = "DNS"

  tags = {
    Name = "${local.name_prefix}-updates-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "app_updates" {
  origin {
    domain_name              = aws_s3_bucket.app_updates.bucket_regional_domain_name
    origin_id                = "s3-app-updates"
    origin_access_control_id = aws_cloudfront_origin_access_control.app_updates.id
  }

  enabled             = true
  default_root_object = "latest.json"
  comment             = "${local.name_prefix} app update artifacts CDN"

  # Custom domain alias only works after ACM cert is validated
  aliases = var.acm_certificate_validated ? [var.updates_domain_name] : []

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-app-updates"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Short TTL so latest.json propagates quickly
    min_ttl     = 0
    default_ttl = 60
    max_ttl     = 300

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use custom cert after validation, default CloudFront cert before
  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_validated ? [1] : []
    content {
      acm_certificate_arn      = aws_acm_certificate.updates.arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_validated ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = {
    Name = "${local.name_prefix}-app-updates-cdn"
  }
}

# -----------------------------------------------------------------------------
# GitHub OIDC Provider (conditional - create once per AWS account)
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "${local.name_prefix}-github-oidc"
  }
}

# -----------------------------------------------------------------------------
# IAM Role for GitHub Actions CI/CD
# -----------------------------------------------------------------------------

locals {
  github_oidc_arn = var.enable_github_oidc ? aws_iam_openid_connect_provider.github[0].arn : var.github_oidc_provider_arn
}

resource "aws_iam_role" "ci_updater" {
  name = "${local.name_prefix}-ci-updater"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.github_oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [for repo in var.github_repos : "repo:${repo}:*"]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ci-updater"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy for S3 Upload and CloudFront Invalidation
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "ci_updater" {
  name = "${local.name_prefix}-ci-updater-policy"
  role = aws_iam_role.ci_updater.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Upload"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.app_updates.arn}/*"
      },
      {
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = aws_cloudfront_distribution.app_updates.arn
      }
    ]
  })
}
