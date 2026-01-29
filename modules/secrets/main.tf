# -----------------------------------------------------------------------------
# Secrets Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates Secrets Manager secrets for all sensitive configuration
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Database URL Secret
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "database_url" {
  name        = "${local.name_prefix}/database-url"
  description = "Database connection URL for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-database-url"
  }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = var.database_url
}

# -----------------------------------------------------------------------------
# Redis URL Secret (Conditional)
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "redis_url" {
  count = var.redis_url != "" ? 1 : 0

  name        = "${local.name_prefix}/redis-url"
  description = "Redis connection URL for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-redis-url"
  }
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  count = var.redis_url != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.redis_url[0].id
  secret_string = var.redis_url
}

# -----------------------------------------------------------------------------
# Supabase Secrets
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "supabase_url" {
  name        = "${local.name_prefix}/supabase-url"
  description = "Supabase project URL for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-supabase-url"
  }
}

resource "aws_secretsmanager_secret_version" "supabase_url" {
  secret_id     = aws_secretsmanager_secret.supabase_url.id
  secret_string = var.supabase_url
}

resource "aws_secretsmanager_secret" "supabase_anon_key" {
  name        = "${local.name_prefix}/supabase-anon-key"
  description = "Supabase anonymous key for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-supabase-anon-key"
  }
}

resource "aws_secretsmanager_secret_version" "supabase_anon_key" {
  secret_id     = aws_secretsmanager_secret.supabase_anon_key.id
  secret_string = var.supabase_anon_key
}

resource "aws_secretsmanager_secret" "supabase_service_role_key" {
  name        = "${local.name_prefix}/supabase-service-role-key"
  description = "Supabase service role key for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-supabase-service-role-key"
  }
}

resource "aws_secretsmanager_secret_version" "supabase_service_role_key" {
  secret_id     = aws_secretsmanager_secret.supabase_service_role_key.id
  secret_string = var.supabase_service_role_key
}

# -----------------------------------------------------------------------------
# AI API Keys
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "openai_api_key" {
  name        = "${local.name_prefix}/openai-api-key"
  description = "OpenAI API key for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-openai-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = var.openai_api_key
}

resource "aws_secretsmanager_secret" "gemini_api_key" {
  name        = "${local.name_prefix}/gemini-api-key"
  description = "Google Gemini API key for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-gemini-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  secret_id     = aws_secretsmanager_secret.gemini_api_key.id
  secret_string = var.gemini_api_key
}

# -----------------------------------------------------------------------------
# Stripe Secrets
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "stripe_secret_key" {
  name        = "${local.name_prefix}/stripe-secret-key"
  description = "Stripe secret key for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-stripe-secret-key"
  }
}

resource "aws_secretsmanager_secret_version" "stripe_secret_key" {
  secret_id     = aws_secretsmanager_secret.stripe_secret_key.id
  secret_string = var.stripe_secret_key
}

resource "aws_secretsmanager_secret" "stripe_webhook_secret" {
  name        = "${local.name_prefix}/stripe-webhook-secret"
  description = "Stripe webhook secret for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-stripe-webhook-secret"
  }
}

resource "aws_secretsmanager_secret_version" "stripe_webhook_secret" {
  secret_id     = aws_secretsmanager_secret.stripe_webhook_secret.id
  secret_string = var.stripe_webhook_secret
}

# -----------------------------------------------------------------------------
# Brave Search API Key
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "brave_search_api_key" {
  name        = "${local.name_prefix}/brave-search-api-key"
  description = "Brave Search API key for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-brave-search-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "brave_search_api_key" {
  secret_id     = aws_secretsmanager_secret.brave_search_api_key.id
  secret_string = var.brave_search_api_key
}
