# -----------------------------------------------------------------------------
# Security Groups Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates security groups for ALB, ECS, RDS, and Redis (conditional)
# Follows principle of least privilege with specific ingress/egress rules
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------
# Allows inbound HTTP (80) and HTTPS (443) from anywhere

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from anywhere"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from anywhere"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# ECS Security Group
# -----------------------------------------------------------------------------
# Allows inbound on port 8080 from ALB only
# Allows all outbound for external API access (OpenAI, Stripe, etc.)

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

resource "aws_security_group_rule" "ecs_ingress_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow traffic from ALB on port 8080"
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all outbound traffic for external API access"
}

# -----------------------------------------------------------------------------
# RDS Security Group
# -----------------------------------------------------------------------------
# Allows inbound PostgreSQL (5432) from ECS only

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from ECS tasks"
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# Redis Security Group (Conditional)
# -----------------------------------------------------------------------------
# Allows inbound Redis (6379) from ECS only

resource "aws_security_group" "redis" {
  count = var.enable_redis ? 1 : 0

  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-redis-sg"
  }
}

resource "aws_security_group_rule" "redis_ingress_ecs" {
  count = var.enable_redis ? 1 : 0

  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.redis[0].id
  description              = "Allow Redis from ECS tasks"
}

resource "aws_security_group_rule" "redis_egress" {
  count = var.enable_redis ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis[0].id
  description       = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# BTB EC2 Security Group (Conditional)
# -----------------------------------------------------------------------------
# Allows inbound SSH (22) from configurable CIDRs
# Allows inbound HTTPS (8443) from configurable CIDRs
# Allows all outbound traffic

resource "aws_security_group" "btb_ec2" {
  count = var.enable_btb_ec2 ? 1 : 0

  name        = "${local.name_prefix}-btb-ec2-sg"
  description = "Security group for btb EC2 instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-btb-ec2-sg"
  }
}

resource "aws_security_group_rule" "btb_ec2_ingress_ssh" {
  count = var.enable_btb_ec2 ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.btb_ssh_cidr_blocks
  security_group_id = aws_security_group.btb_ec2[0].id
  description       = "Allow SSH from configured CIDR blocks"
}

resource "aws_security_group_rule" "btb_ec2_ingress_https" {
  count = var.enable_btb_ec2 ? 1 : 0

  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = var.btb_https_cidr_blocks
  security_group_id = aws_security_group.btb_ec2[0].id
  description       = "Allow HTTPS on port 8443 from configured CIDR blocks"
}

resource "aws_security_group_rule" "btb_ec2_egress" {
  count = var.enable_btb_ec2 ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.btb_ec2[0].id
  description       = "Allow all outbound traffic"
}
