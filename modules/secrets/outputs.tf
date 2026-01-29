# -----------------------------------------------------------------------------
# Secrets Module - Outputs
# -----------------------------------------------------------------------------

output "secret_arns" {
  description = "Map of secret names to their ARNs"
  value = {
    database_url              = aws_secretsmanager_secret.database_url.arn
    redis_url                 = var.redis_url != "" ? aws_secretsmanager_secret.redis_url[0].arn : null
    supabase_url              = aws_secretsmanager_secret.supabase_url.arn
    supabase_anon_key         = aws_secretsmanager_secret.supabase_anon_key.arn
    supabase_service_role_key = aws_secretsmanager_secret.supabase_service_role_key.arn
    openai_api_key            = aws_secretsmanager_secret.openai_api_key.arn
    gemini_api_key            = aws_secretsmanager_secret.gemini_api_key.arn
    stripe_secret_key         = aws_secretsmanager_secret.stripe_secret_key.arn
    stripe_webhook_secret     = aws_secretsmanager_secret.stripe_webhook_secret.arn
    brave_search_api_key      = aws_secretsmanager_secret.brave_search_api_key.arn
  }
}

output "database_url_secret_arn" {
  description = "ARN of the database URL secret"
  value       = aws_secretsmanager_secret.database_url.arn
}

output "redis_url_secret_arn" {
  description = "ARN of the Redis URL secret (null if Redis is disabled)"
  value       = var.redis_url != "" ? aws_secretsmanager_secret.redis_url[0].arn : null
}
