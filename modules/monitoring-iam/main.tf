# -----------------------------------------------------------------------------
# Monitoring IAM Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates an IAM user with programmatic access for monitoring dashboards.
# Grants read-only access to CloudWatch, ELB, ECS, CloudWatch Logs, and
# ALB access logs in S3.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# IAM User
# -----------------------------------------------------------------------------

resource "aws_iam_user" "monitoring" {
  name = "${local.name_prefix}-monitoring-user"
  path = "/monitoring/"

  tags = {
    Name        = "${local.name_prefix}-monitoring-user"
    Purpose     = "monitoring-dashboard"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Programmatic Access Key
# -----------------------------------------------------------------------------

resource "aws_iam_access_key" "monitoring" {
  user = aws_iam_user.monitoring.name
}

# -----------------------------------------------------------------------------
# Monitoring Policy
# -----------------------------------------------------------------------------

resource "aws_iam_user_policy" "monitoring" {
  name = "${local.name_prefix}-monitoring-policy"
  user = aws_iam_user.monitoring.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchReadOnly"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmsForMetric"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELBReadOnly"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSReadOnly"
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:ListTasks",
          "ecs:DescribeContainerInstances",
          "ecs:ListContainerInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsReadOnly"
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "ALBLogsS3ReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.alb_logs_bucket_arn,
          "${var.alb_logs_bucket_arn}/*"
        ]
      }
    ]
  })
}
