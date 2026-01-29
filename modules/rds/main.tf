# -----------------------------------------------------------------------------
# RDS Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates RDS PostgreSQL instance with automated backups and optional Multi-AZ
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Random Password for Database
# -----------------------------------------------------------------------------

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# Store Database Password in Secrets Manager
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${local.name_prefix}/rds-master-password"
  description = "RDS master password for ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-rds-master-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# -----------------------------------------------------------------------------
# RDS Parameter Group
# -----------------------------------------------------------------------------

resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-pg-params"
  family      = "postgres15"
  description = "PostgreSQL parameter group for ${local.name_prefix}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name = "${local.name_prefix}-pg-params"
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-postgres"

  # Engine configuration
  engine                = "postgres"
  engine_version        = "15"
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  db_name  = var.database_name
  username = "dbadmin"
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  port                   = 5432

  # High availability
  multi_az = var.multi_az

  # Backup configuration
  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.name_prefix}-final-snapshot" : null

  # Performance and monitoring
  parameter_group_name            = aws_db_parameter_group.main.name
  performance_insights_enabled    = var.environment == "prod"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Protection
  deletion_protection = var.deletion_protection

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = {
    Name = "${local.name_prefix}-postgres"
  }
}
