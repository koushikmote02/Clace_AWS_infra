# -----------------------------------------------------------------------------
# ElastiCache Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates ElastiCache Redis cluster for caching and rate limiting
# This module is conditionally created based on enable_redis variable
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# ElastiCache Parameter Group
# -----------------------------------------------------------------------------

resource "aws_elasticache_parameter_group" "main" {
  name        = "${local.name_prefix}-redis-params"
  family      = "redis7"
  description = "Redis parameter group for ${local.name_prefix}"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  tags = {
    Name = "${local.name_prefix}-redis-params"
  }
}

# -----------------------------------------------------------------------------
# ElastiCache Redis Cluster
# -----------------------------------------------------------------------------

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.main.name
  port                 = 6379

  subnet_group_name  = var.elasticache_subnet_group_name
  security_group_ids = [var.security_group_id]

  # Maintenance window
  maintenance_window = "sun:05:00-sun:06:00"

  # Snapshot configuration (for single node)
  snapshot_retention_limit = var.environment == "prod" ? 7 : 0
  snapshot_window          = var.environment == "prod" ? "04:00-05:00" : null

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}
