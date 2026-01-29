# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------

locals {
  # Naming convention: {project}-{environment}-{resource}
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Environment-specific configurations
  environment_config = {
    dev = {
      ecs_cpu            = 256
      ecs_memory         = 512
      rds_instance_class = "db.t3.micro"
      redis_node_type    = "cache.t3.micro"
      multi_az           = false
    }
    staging = {
      ecs_cpu            = 512
      ecs_memory         = 1024
      rds_instance_class = "db.t3.small"
      redis_node_type    = "cache.t3.micro"
      multi_az           = false
    }
    prod = {
      ecs_cpu            = 1024
      ecs_memory         = 2048
      rds_instance_class = "db.t3.medium"
      redis_node_type    = "cache.t3.small"
      multi_az           = true
    }
  }
}
