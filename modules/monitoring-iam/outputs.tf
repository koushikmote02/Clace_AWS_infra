# -----------------------------------------------------------------------------
# Monitoring IAM Module - Outputs
# -----------------------------------------------------------------------------

output "iam_user_name" {
  description = "Name of the monitoring IAM user"
  value       = aws_iam_user.monitoring.name
}

output "iam_user_arn" {
  description = "ARN of the monitoring IAM user"
  value       = aws_iam_user.monitoring.arn
}

output "access_key_id" {
  description = "AWS Access Key ID for the monitoring user"
  value       = aws_iam_access_key.monitoring.id
}

output "secret_access_key" {
  description = "AWS Secret Access Key for the monitoring user"
  value       = aws_iam_access_key.monitoring.secret
  sensitive   = true
}
