# -----------------------------------------------------------------------------
# RDS Module - Outputs
# -----------------------------------------------------------------------------

output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "RDS instance address (hostname only)"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.main.username
}

output "master_password_secret_arn" {
  description = "ARN of the secret containing the master password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

# Constructed DATABASE_URL for application use
output "database_url" {
  description = "Constructed DATABASE_URL for application"
  value       = "postgresql://${aws_db_instance.main.username}:${random_password.db_password.result}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive   = true
}
