# -----------------------------------------------------------------------------
# ECS Module - IAM Roles
# -----------------------------------------------------------------------------
# Creates IAM roles for ECS task execution and task role
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# ECS Task Execution Role
# -----------------------------------------------------------------------------
# Used by ECS to pull images from ECR and read secrets from Secrets Manager

resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ecs-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${local.name_prefix}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.secrets_arns.database_url,
          var.secrets_arns.supabase_url,
          var.secrets_arns.supabase_anon_key,
          var.secrets_arns.supabase_service_role_key,
          var.secrets_arns.openai_api_key,
          var.secrets_arns.gemini_api_key,
          var.secrets_arns.stripe_secret_key,
          var.secrets_arns.stripe_webhook_secret,
          var.secrets_arns.brave_search_api_key
        ]
      }
    ]
  })
}

# Additional policy for Redis URL secret (conditional)
resource "aws_iam_role_policy" "ecs_execution_redis_secret" {
  count = var.secrets_arns.redis_url != null ? 1 : 0

  name = "${local.name_prefix}-ecs-execution-redis-secret"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [var.secrets_arns.redis_url]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECS Task Role
# -----------------------------------------------------------------------------
# Used by the application running in the container

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ecs-task-role"
  }
}

# Task role policy for application permissions
# Add additional permissions here as needed by the application
resource "aws_iam_role_policy" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
