# -----------------------------------------------------------------------------
# BTB EC2 Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates an EC2 instance for the btb-service with dynamic AMI lookup,
# configurable instance type and volume, optional key pair creation,
# and optional user_data provisioning.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Determine the key pair name: create new if ssh_public_key provided, else use existing
  key_name = var.ssh_public_key != "" ? aws_key_pair.btb[0].key_name : var.key_pair_name
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# -----------------------------------------------------------------------------
# SSH Key Pair (conditional)
# -----------------------------------------------------------------------------

resource "aws_key_pair" "btb" {
  count = var.ssh_public_key != "" ? 1 : 0

  key_name   = "${local.name_prefix}-btb-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${local.name_prefix}-btb-key"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------

resource "aws_instance" "btb" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = var.instance_profile_name
  key_name                    = local.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = var.enable_user_data ? templatefile("${path.module}/user_data.sh.tpl", {
    btb_repo_url = var.btb_repo_url
  }) : null

  tags = {
    Name        = "${local.name_prefix}-btb-service"
    Project     = var.project_name
    Environment = var.environment
  }
}
