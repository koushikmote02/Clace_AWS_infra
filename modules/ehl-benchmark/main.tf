# -----------------------------------------------------------------------------
# EHL Benchmark Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates a memory-optimized EC2 instance (r6i.12xlarge) for EHL benchmarking.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  key_name    = var.ssh_public_key != "" ? aws_key_pair.ehl[0].key_name : var.key_pair_name
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_key_pair" "ehl" {
  count = var.ssh_public_key != "" ? 1 : 0

  key_name   = "${local.name_prefix}-ehl-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${local.name_prefix}-ehl-key"
  }
}

resource "aws_security_group" "ehl" {
  name        = "${local.name_prefix}-ehl-benchmark-sg"
  description = "Security group for EHL Benchmark instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-ehl-benchmark-sg"
  }
}

resource "aws_security_group_rule" "ehl_ingress_ssh" {
  count = length(var.ssh_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  description       = "Allow SSH from admin"
  security_group_id = aws_security_group.ehl.id
}

resource "aws_security_group_rule" "ehl_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.ehl.id
}

resource "aws_instance" "ehl" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.ehl.id]
  key_name                    = local.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "EHL_Benchmark"
    Project     = var.project_name
    Environment = var.environment
  }
}
