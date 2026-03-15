# -----------------------------------------------------------------------------
# MGN (Application Migration Service) Module - Main Configuration
# -----------------------------------------------------------------------------
# Sets up IAM roles, security groups, and prerequisites for AWS MGN
# to migrate EC2 instances from multiple regions into us-east-2.
# Note: AWS MGN itself is initialized via CLI/Console, not Terraform.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# IAM Role for MGN Replication Agent (installed on source instances)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "mgn_replication" {
  name = "${local.name_prefix}-mgn-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "mgn.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-mgn-replication-role"
  }
}

resource "aws_iam_role_policy_attachment" "mgn_replication" {
  role       = aws_iam_role.mgn_replication.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSApplicationMigrationReplicationServerPolicy"
}

# -----------------------------------------------------------------------------
# IAM Role for MGN Conversion Server
# -----------------------------------------------------------------------------

resource "aws_iam_role" "mgn_conversion" {
  name = "${local.name_prefix}-mgn-conversion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "mgn.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-mgn-conversion-role"
  }
}

resource "aws_iam_role_policy_attachment" "mgn_conversion" {
  role       = aws_iam_role.mgn_conversion.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSApplicationMigrationConversionServerPolicy"
}

# -----------------------------------------------------------------------------
# IAM User for MGN Agent (installed on source instances)
# -----------------------------------------------------------------------------

resource "aws_iam_user" "mgn_agent" {
  name = "${local.name_prefix}-mgn-agent"

  tags = {
    Name = "${local.name_prefix}-mgn-agent"
  }
}

resource "aws_iam_user_policy_attachment" "mgn_agent" {
  user       = aws_iam_user.mgn_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AWSApplicationMigrationAgentInstallationPolicy"
}

resource "aws_iam_access_key" "mgn_agent" {
  user = aws_iam_user.mgn_agent.name
}

# -----------------------------------------------------------------------------
# Security Group for MGN Replication Servers (in target VPC)
# -----------------------------------------------------------------------------

resource "aws_security_group" "mgn_replication" {
  name        = "${local.name_prefix}-mgn-replication-sg"
  description = "Security group for MGN replication servers"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-mgn-replication-sg"
  }
}

resource "aws_security_group_rule" "mgn_replication_ingress" {
  type              = "ingress"
  from_port         = 1500
  to_port           = 1500
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow replication data from source instances (TCP 1500)"
  security_group_id = aws_security_group.mgn_replication.id
}

resource "aws_security_group_rule" "mgn_replication_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.mgn_replication.id
}

# -----------------------------------------------------------------------------
# Security Group for Migrated Instances (post-cutover)
# -----------------------------------------------------------------------------

resource "aws_security_group" "mgn_migrated" {
  name        = "${local.name_prefix}-mgn-migrated-sg"
  description = "Security group for migrated EC2 instances"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-mgn-migrated-sg"
  }
}

resource "aws_security_group_rule" "mgn_migrated_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "Allow SSH from admin"
  security_group_id = aws_security_group.mgn_migrated.id
}

resource "aws_security_group_rule" "mgn_migrated_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.mgn_migrated.id
}
