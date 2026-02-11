# Implementation Plan: btb-ec2-setup

## Overview

Implement the btb-service EC2 infrastructure as Terraform modules integrated into the existing project. Work proceeds bottom-up: IAM module first, then security group extension, then EC2 module, then root module wiring, and finally post-provisioning documentation. Each module follows the existing project patterns (naming conventions, variable structure, output format).

## Tasks

- [x] 1. Create the btb-iam Terraform module
  - [x] 1.1 Create `modules/btb-iam/main.tf` with IAM role, trust policy (ec2.amazonaws.com), inline Bedrock policy (bedrock:InvokeModel, bedrock:InvokeModelWithResponseStream), and instance profile
    - Use `${var.project_name}-${var.environment}-btb-service-role` naming convention
    - Trust policy allows `ec2.amazonaws.com` to assume the role
    - Bedrock policy uses `Resource: "*"`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - [x] 1.2 Create `modules/btb-iam/variables.tf` with `project_name` and `environment` inputs
    - _Requirements: 2.4_
  - [x] 1.3 Create `modules/btb-iam/outputs.tf` exposing `role_arn`, `role_name`, `instance_profile_name`, `instance_profile_arn`
    - _Requirements: 2.3_

- [x] 2. Extend the security-groups module for btb EC2
  - [x] 2.1 Add `enable_btb_ec2`, `btb_ssh_cidr_blocks`, and `btb_https_cidr_blocks` variables to `modules/security-groups/variables.tf`
    - `enable_btb_ec2` bool, default false
    - `btb_ssh_cidr_blocks` list(string), default []
    - `btb_https_cidr_blocks` list(string), default ["0.0.0.0/0"]
    - _Requirements: 3.1, 3.2_
  - [x] 2.2 Add btb EC2 security group resources to `modules/security-groups/main.tf`
    - Security group, SSH ingress (port 22), HTTPS ingress (port 8443), all egress
    - All resources conditional on `enable_btb_ec2` using count
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [x] 2.3 Add `btb_ec2_security_group_id` output to `modules/security-groups/outputs.tf`
    - Return null when `enable_btb_ec2` is false
    - _Requirements: 3.4_

- [x] 3. Create the btb-ec2 Terraform module
  - [x] 3.1 Create `modules/btb-ec2/main.tf` with EC2 instance resource
    - Dynamic AMI lookup via `aws_ssm_parameter` for Amazon Linux 2023
    - Configurable instance type (default t3.medium), root volume (default 50GB gp3, encrypted)
    - Conditional key pair creation (if `ssh_public_key` provided) or reference existing `key_pair_name`
    - Public IP assignment via `associate_public_ip_address = true`
    - IAM instance profile attachment
    - Tagging with project name, environment, and Name = `{prefix}-btb-service`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_
  - [x] 3.2 Create `modules/btb-ec2/user_data.sh.tpl` template
    - Clone btb repo to /opt/btb
    - Run provision.sh
    - Verify /var/btb/ directory structure (queue, completed, jobs, logs)
    - Log to /var/log/user-data.log
    - Use `set -euo pipefail` for error handling
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 3.3 Create `modules/btb-ec2/variables.tf` with all input variables
    - project_name, environment, subnet_id, security_group_id, instance_profile_name, instance_type, root_volume_size, ssh_public_key, key_pair_name, btb_repo_url, enable_user_data
    - _Requirements: 1.1, 5.4, 5.5_
  - [x] 3.4 Create `modules/btb-ec2/outputs.tf` exposing instance_id, public_ip, public_dns
    - _Requirements: 4.2_

- [x] 4. Checkpoint - Validate module syntax
  - Run `terraform validate` on each module directory to catch HCL syntax errors. Ask the user if questions arise.

- [x] 5. Integrate btb modules into the root module
  - [x] 5.1 Add btb-related variables to root `variables.tf`
    - enable_btb_ec2 (bool, default false), btb_instance_type, btb_root_volume_size, btb_ssh_public_key (sensitive), btb_key_pair_name, btb_ssh_cidr_blocks, btb_https_cidr_blocks, btb_repo_url, btb_enable_user_data
    - _Requirements: 4.3_
  - [x] 5.2 Add btb module blocks to root `main.tf`
    - Wire `module.btb_iam` and `module.btb_ec2` with `count = var.enable_btb_ec2 ? 1 : 0`
    - Pass `enable_btb_ec2` and CIDR variables to `module.security_groups`
    - Wire subnet_id from `module.vpc.public_subnet_ids[0]`, security_group_id from `module.security_groups`, instance_profile_name from `module.btb_iam`
    - _Requirements: 4.1, 4.3, 4.4_
  - [x] 5.3 Add btb outputs to root `outputs.tf`
    - btb_ec2_public_ip, btb_ec2_instance_id, btb_iam_role_arn — all null when disabled
    - _Requirements: 4.2_
  - [x] 5.4 Add btb variables to `environments/dev.tfvars` (commented out with documentation)
    - Include example values for all btb variables
    - _Requirements: 4.1_

- [x] 6. Checkpoint - Full terraform validate and plan
  - Run `terraform validate` on the root module. Run `terraform plan -var-file=environments/dev.tfvars` with `enable_btb_ec2=false` to verify no btb resources are created. Ask the user if questions arise.

- [x] 7. Create post-provisioning documentation
  - [x] 7.1 Create `modules/btb-ec2/POST_PROVISIONING.md` covering all manual setup steps
    - SSH access instructions (using key pair and public IP from Terraform output)
    - Manual clone and provision steps (if user_data not used)
    - Config file setup with all required environment variables and permissions (root:btb, 640)
    - WEBHOOK_SECRET generation via `openssl rand -hex 32`
    - GITHUB_TOKEN requirements (Contents:Read permission)
    - TLS certificate generation (self-signed with openssl, and Let's Encrypt alternative)
    - Certificate file permissions (root:btb, 640)
    - Service start/status/logs commands (systemctl, journalctl)
    - GitHub webhook setup (manual and deploy/setup-webhook.sh helper, noting separate admin:repo_hook token)
    - SSL verification note for self-signed certs
    - Repository opt-in with .btb file
    - Dashboard access URL
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.4, 9.1, 9.2, 9.3, 9.4, 10.1, 10.2, 10.3, 10.4, 10.5, 11.1, 11.2, 11.3, 12.1, 12.2, 12.3_

- [x] 8. Final checkpoint - Ensure all modules validate and plan succeeds
  - Run `terraform validate` and `terraform plan` with btb enabled (`enable_btb_ec2=true` plus required variables). Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation via `terraform validate` and `terraform plan`
- The btb-service application code is NOT part of this spec — it lives in the btb repo and is cloned onto the instance
- Post-provisioning documentation (task 7) covers all manual/runtime requirements that cannot be automated via Terraform
