# -----------------------------------------------------------------------------
# EHL Benchmark Module - Outputs
# -----------------------------------------------------------------------------

output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.ehl.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.ehl.public_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ehl.id
}
