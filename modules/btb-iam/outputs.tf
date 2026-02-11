# -----------------------------------------------------------------------------
# BTB IAM Module - Outputs
# -----------------------------------------------------------------------------

output "role_arn" {
  description = "ARN of the btb-service IAM role"
  value       = aws_iam_role.btb_service.arn
}

output "role_name" {
  description = "Name of the btb-service IAM role"
  value       = aws_iam_role.btb_service.name
}

output "instance_profile_name" {
  description = "Name of the btb-service instance profile"
  value       = aws_iam_instance_profile.btb_service.name
}

output "instance_profile_arn" {
  description = "ARN of the btb-service instance profile"
  value       = aws_iam_instance_profile.btb_service.arn
}
