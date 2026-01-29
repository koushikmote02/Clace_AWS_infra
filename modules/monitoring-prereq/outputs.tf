# -----------------------------------------------------------------------------
# Monitoring Pre-requisites Module - Outputs
# -----------------------------------------------------------------------------

output "log_group_name" {
  description = "Name of the CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "alb_logs_bucket" {
  description = "Name of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "alb_logs_bucket_arn" {
  description = "ARN of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.arn
}
