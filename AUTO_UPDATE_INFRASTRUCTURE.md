# Auto-Update Infrastructure Plan

## Problem

The Clace desktop app uses Tauri's built-in updater to check for new versions. The updater
fetches a `latest.json` manifest from a URL, compares versions, and downloads the update
artifact if a newer version exists.

Currently, `tauri.conf.json` points the updater at:

```
https://github.com/koushikmote02/Client/releases/latest/download/latest.json
```

This fails because the GitHub repo is private. GitHub's `/releases/latest/download/` URL
returns 404 for private repos, even for authenticated users in a browser. The Tauri updater
has no way to authenticate with GitHub's release asset API.

## Solution

Host the update manifest (`latest.json`) and update artifacts (`.app.tar.gz`, `.nsis.zip`,
`.AppImage.tar.gz`) on a public S3 bucket behind CloudFront, served under the existing
`api.clace.ai` domain (or a new subdomain like `updates.clace.ai`).

The CI/CD pipeline uploads artifacts to S3 after each release build. The desktop app fetches
from the public CloudFront URL. No authentication needed.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌────────────┐     ┌──────────┐
│  GitHub CI   │────▶│  S3 Bucket   │────▶│ CloudFront │────▶│ Desktop  │
│  (release    │     │  (artifacts) │     │  (CDN)     │     │  App     │
│   workflow)  │     │              │     │            │     │ (Tauri)  │
└─────────────┘     └──────────────┘     └────────────┘     └──────────┘
```

**Flow:**
1. CI builds the app, produces `.app.tar.gz` + `.sig` + `latest.json`
2. CI uploads all artifacts to S3 via `aws s3 cp`
3. CloudFront serves them publicly over HTTPS
4. Desktop app checks `https://updates.clace.ai/latest.json` on launch
5. If a new version exists, it downloads the platform artifact from the same CDN

## What You Need to Create (Terraform)

### 1. S3 Bucket

A private S3 bucket to store update artifacts. CloudFront accesses it via Origin Access
Control (OAC) — the bucket itself is not publicly accessible.

```hcl
resource "aws_s3_bucket" "app_updates" {
  bucket = "clace-app-updates"
}

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
```

**Bucket structure:**
```
clace-app-updates/
  latest.json                              # Updater manifest (always overwritten)
  v0.2.0/
    clace_0.2.0_universal.app.tar.gz       # macOS update bundle
    clace_0.2.0_universal.app.tar.gz.sig   # macOS signature
    clace_0.2.0_universal.dmg              # macOS installer (optional, for download page)
    clace_0.2.0_x64-setup.nsis.zip         # Windows update bundle
    clace_0.2.0_x64-setup.nsis.zip.sig     # Windows signature
    clace_0.2.0_amd64.AppImage.tar.gz      # Linux update bundle
    clace_0.2.0_amd64.AppImage.tar.gz.sig  # Linux signature
```

### 2. CloudFront Distribution

Serves the S3 bucket over HTTPS. Use a custom domain like `updates.clace.ai`.

```hcl
resource "aws_cloudfront_distribution" "app_updates" {
  origin {
    domain_name              = aws_s3_bucket.app_updates.bucket_regional_domain_name
    origin_id                = "s3-app-updates"
    origin_access_control_id = aws_cloudfront_origin_access_control.app_updates.id
  }

  enabled             = true
  default_root_object = "latest.json"

  aliases = ["updates.clace.ai"]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-app-updates"
    viewer_protocol_policy = "redirect-to-https"

    # Short TTL for latest.json so updates propagate quickly
    min_ttl     = 0
    default_ttl = 60    # 1 minute
    max_ttl     = 300   # 5 minutes

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.updates.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_origin_access_control" "app_updates" {
  name                              = "clace-app-updates-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

### 3. ACM Certificate

An SSL certificate for `updates.clace.ai`. Must be in `us-east-1` for CloudFront.

```hcl
resource "aws_acm_certificate" "updates" {
  provider          = aws.us_east_1  # CloudFront requires us-east-1
  domain_name       = "updates.clace.ai"
  validation_method = "DNS"
}
```

### 4. DNS Record

A Route 53 (or your DNS provider) CNAME/alias pointing `updates.clace.ai` to the
CloudFront distribution.

```hcl
resource "aws_route53_record" "updates" {
  zone_id = data.aws_route53_zone.clace.zone_id
  name    = "updates.clace.ai"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app_updates.domain_name
    zone_id                = aws_cloudfront_distribution.app_updates.hosted_zone_id
    evaluate_target_health = false
  }
}
```

### 5. IAM User for CI

An IAM user (or OIDC role) that GitHub Actions uses to upload artifacts to S3.

```hcl
resource "aws_iam_user" "ci_updater" {
  name = "clace-ci-updater"
}

resource "aws_iam_user_policy" "ci_updater" {
  name = "clace-ci-updater-s3"
  user = aws_iam_user.ci_updater.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:PutObjectAcl"]
        Resource = "${aws_s3_bucket.app_updates.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = aws_cloudfront_distribution.app_updates.arn
      }
    ]
  })
}
```

**Better alternative:** Use GitHub OIDC instead of static IAM credentials. This avoids
storing long-lived AWS keys in GitHub secrets.

```hcl
# GitHub OIDC provider (create once per AWS account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "ci_updater" {
  name = "clace-ci-updater"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:koushikmote02/Client:*"
        }
      }
    }]
  })
}
```

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_REGION` | AWS region where the S3 bucket lives (e.g., `us-east-1`) |
| `AWS_S3_BUCKET` | Bucket name (e.g., `clace-app-updates`) |
| `AWS_CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID for cache invalidation |
| `AWS_ROLE_ARN` | IAM role ARN (if using OIDC) or `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` (if using IAM user) |

## Changes to This Repo

### 1. `tauri.conf.json` — Update the endpoint

```json
"updater": {
  "endpoints": [
    "https://updates.clace.ai/latest.json"
  ],
  "pubkey": "<unchanged>"
}
```

### 2. `latest.json` — URLs point to S3/CloudFront

The CI workflow generates `latest.json` with download URLs like:

```json
{
  "version": "0.2.0",
  "pub_date": "2026-02-27T00:00:00Z",
  "platforms": {
    "darwin-universal": {
      "signature": "<sig content>",
      "url": "https://updates.clace.ai/v0.2.0/clace_0.2.0_universal.app.tar.gz"
    },
    "windows-x86_64": {
      "signature": "<sig content>",
      "url": "https://updates.clace.ai/v0.2.0/clace_0.2.0_x64-setup.nsis.zip"
    },
    "linux-x86_64": {
      "signature": "<sig content>",
      "url": "https://updates.clace.ai/v0.2.0/clace_0.2.0_amd64.AppImage.tar.gz"
    }
  }
}
```

### 3. Release workflow — Add S3 upload step

After building and collecting artifacts, upload to S3 and invalidate CloudFront cache:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ secrets.AWS_REGION }}

- name: Upload artifacts to S3
  run: |
    VERSION="${TAG#v}"
    # Upload versioned artifacts
    aws s3 cp release-files/ "s3://${{ secrets.AWS_S3_BUCKET }}/v${VERSION}/" \
      --recursive --exclude "latest.json"
    # Upload latest.json to root
    aws s3 cp release-files/latest.json "s3://${{ secrets.AWS_S3_BUCKET }}/latest.json"

- name: Invalidate CloudFront cache
  run: |
    aws cloudfront create-invalidation \
      --distribution-id ${{ secrets.AWS_CLOUDFRONT_DISTRIBUTION_ID }} \
      --paths "/latest.json"
```

## Cost Estimate

This is extremely cheap infrastructure:

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| S3 storage (~500MB of artifacts) | ~$0.01 |
| S3 requests (~10K GET/month) | ~$0.004 |
| CloudFront data transfer (~50GB/month) | ~$4.25 |
| CloudFront requests (~10K/month) | ~$0.01 |
| ACM certificate | Free |
| Route 53 hosted zone (if new) | $0.50 |
| **Total** | **~$5/month** |

Scales linearly with user count. Even at 100K monthly update checks, you're under $20/month.

## Implementation Order

1. **Terraform:** Create S3 bucket, CloudFront distribution, ACM cert, DNS record, IAM role
2. **GitHub secrets:** Add `AWS_ROLE_ARN`, `AWS_REGION`, `AWS_S3_BUCKET`, `AWS_CLOUDFRONT_DISTRIBUTION_ID`
3. **This repo:** Update `tauri.conf.json` endpoint, add S3 upload steps to release workflows
4. **Test:** Build v0.1.0, install it, then release v0.2.0 through the pipeline, verify update
