# -----------------------------------------------------------------------------
# App Updates Module - Outputs
# -----------------------------------------------------------------------------

output "s3_bucket_name" {
  description = "Name of the S3 bucket for update artifacts"
  value       = aws_s3_bucket.app_updates.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for update artifacts"
  value       = aws_s3_bucket.app_updates.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.app_updates.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.app_updates.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name — add a CNAME at Porkbun pointing updates_domain_name to this"
  value       = aws_cloudfront_distribution.app_updates.domain_name
}

output "updates_url" {
  description = "Full URL for the updates endpoint"
  value       = "https://${var.updates_domain_name}/latest.json"
}

output "ci_updater_role_arn" {
  description = "ARN of the IAM role for GitHub Actions CI/CD"
  value       = aws_iam_role.ci_updater.arn
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the updates domain"
  value       = aws_acm_certificate.updates.arn
}

output "acm_validation_records" {
  description = "DNS records to add at Porkbun for ACM certificate validation"
  value = {
    for dvo in aws_acm_certificate.updates.domain_validation_options : dvo.domain_name => {
      type  = dvo.resource_record_type
      name  = dvo.resource_record_name
      value = dvo.resource_record_value
    }
  }
}
