# -----------------------------------------------------------------------------
# ECS Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates ECS Fargate cluster, task definition, and service
# Tasks run in public subnets with public IPs for external API access
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Base secrets that are always included
  base_secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = var.secrets_arns.database_url
    },
    {
      name      = "SUPABASE_URL"
      valueFrom = var.secrets_arns.supabase_url
    },
    {
      name      = "SUPABASE_ANON_KEY"
      valueFrom = var.secrets_arns.supabase_anon_key
    },
    {
      name      = "SUPABASE_SERVICE_ROLE_KEY"
      valueFrom = var.secrets_arns.supabase_service_role_key
    },
    {
      name      = "OPENAI_API_KEY"
      valueFrom = var.secrets_arns.openai_api_key
    },
    {
      name      = "GEMINI_API_KEY"
      valueFrom = var.secrets_arns.gemini_api_key
    },
    {
      name      = "STRIPE_SECRET_KEY"
      valueFrom = var.secrets_arns.stripe_secret_key
    },
    {
      name      = "STRIPE_WEBHOOK_SECRET"
      valueFrom = var.secrets_arns.stripe_webhook_secret
    },
    {
      name      = "BRAVE_SEARCH_API_KEY"
      valueFrom = var.secrets_arns.brave_search_api_key
    }
  ]

  # Redis secret (conditional)
  redis_secret = var.secrets_arns.redis_url != null ? [
    {
      name      = "REDIS_URL"
      valueFrom = var.secrets_arns.redis_url
    }
  ] : []

  # Combined secrets
  all_secrets = concat(local.base_secrets, local.redis_secret)
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.environment == "prod" ? "enabled" : "disabled"
  }

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.environment == "prod" ? "FARGATE" : "FARGATE_SPOT"
  }
}

# -----------------------------------------------------------------------------
# ECS Task Definition
# -----------------------------------------------------------------------------

resource "aws_ecs_task_definition" "main" {
  family                   = "${local.name_prefix}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "${var.ecr_repository_url}:${var.image_tag}"

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      secrets = local.all_secrets

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "8080"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      essential = true
    }
  ])

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# -----------------------------------------------------------------------------
# ECS Service
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "main" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api"
    container_port   = 8080
  }

  # Deployment configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = 60

  # Enable ECS managed tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # Ignore changes to desired_count for auto-scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_execution]
}
