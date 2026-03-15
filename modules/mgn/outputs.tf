# -----------------------------------------------------------------------------
# MGN Module - Outputs
# -----------------------------------------------------------------------------

output "replication_role_arn" {
  description = "ARN of the MGN replication server IAM role"
  value       = aws_iam_role.mgn_replication.arn
}

output "conversion_role_arn" {
  description = "ARN of the MGN conversion server IAM role"
  value       = aws_iam_role.mgn_conversion.arn
}

output "agent_access_key_id" {
  description = "Access key ID for the MGN agent user (use on source instances)"
  value       = aws_iam_access_key.mgn_agent.id
}

output "agent_secret_access_key" {
  description = "Secret access key for the MGN agent user (use on source instances)"
  value       = aws_iam_access_key.mgn_agent.secret
  sensitive   = true
}

output "replication_security_group_id" {
  description = "Security group ID for MGN replication servers"
  value       = aws_security_group.mgn_replication.id
}

output "migrated_security_group_id" {
  description = "Security group ID for migrated instances"
  value       = aws_security_group.mgn_migrated.id
}
