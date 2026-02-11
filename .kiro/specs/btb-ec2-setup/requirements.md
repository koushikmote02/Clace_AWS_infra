# Requirements Document

## Introduction

This document specifies the requirements for deploying a btb-service on an AWS EC2 instance. The btb-service is a webhook-driven CI/CD-style service that listens for GitHub push events, clones repositories, runs btb (with kiro-cli), and pushes results back. The deployment involves Terraform-managed infrastructure (EC2 instance, IAM role, security group) integrated into the existing Terraform project, plus post-provisioning steps that can be automated via user_data or performed manually via SSH.

## Glossary

- **BTB_Service**: The btb-service application running on the EC2 instance, listening for GitHub webhooks on port 8443 over HTTPS
- **EC2_Module**: The Terraform module that provisions the EC2 instance, key pair, and associated resources
- **IAM_Module**: The Terraform module that creates the IAM role and instance profile for the EC2 instance
- **Security_Group**: The Terraform-managed security group controlling network access to the EC2 instance
- **Provisioning_Script**: The btb repo's `deploy/provision.sh` script that installs dependencies and sets up the btb-service systemd unit
- **Config_File**: The `/etc/btb-service/config.env` file containing service configuration and secrets
- **TLS_Certificate**: The self-signed or CA-issued TLS certificate used for HTTPS on port 8443
- **Webhook**: A GitHub webhook configured to send push events to the BTB_Service endpoint
- **Dashboard**: The web UI served by BTB_Service at `https://<instance>:8443/` showing job status
- **User_Data**: The EC2 instance startup script that runs on first boot to automate provisioning

## Requirements

### Requirement 1: EC2 Instance Provisioning

**User Story:** As a DevOps engineer, I want to provision an EC2 instance via Terraform, so that the btb-service has a dedicated compute environment with appropriate sizing and storage.

#### Acceptance Criteria

1. WHEN the Terraform EC2 module is applied, THE EC2_Module SHALL create an EC2 instance with a configurable instance type defaulting to `t3.medium`
2. WHEN the Terraform EC2 module is applied, THE EC2_Module SHALL use Amazon Linux 2023 as the default AMI, resolved dynamically via an SSM parameter or data source
3. WHEN the Terraform EC2 module is applied, THE EC2_Module SHALL attach a root EBS volume of at least 50 GB using the gp3 volume type
4. WHEN the Terraform EC2 module is applied, THE EC2_Module SHALL create or reference an SSH key pair for instance access
5. WHEN the Terraform EC2 module is applied, THE EC2_Module SHALL assign the instance a public IP address for external webhook access
6. WHEN the Terraform EC2 module is applied, THE EC2_Module SHALL tag the instance with the project name, environment, and a Name tag of `btb-service`
7. WHEN the Terraform EC2 module is applied, THE EC2_Module SHALL attach the IAM instance profile created by the IAM module

### Requirement 2: IAM Role and Instance Profile

**User Story:** As a DevOps engineer, I want to create an IAM role with Bedrock permissions attached as an instance profile, so that the btb-service can invoke AI models using the default AWS credential chain without embedding long-lived credentials or requiring manual SSO login.

#### Acceptance Criteria

1. WHEN the Terraform IAM module is applied, THE IAM_Module SHALL create an IAM role with an EC2 trust policy allowing the `ec2.amazonaws.com` service to assume the role
2. WHEN the Terraform IAM module is applied, THE IAM_Module SHALL attach a policy granting `bedrock:InvokeModel` and `bedrock:InvokeModelWithResponseStream` permissions
3. WHEN the Terraform IAM module is applied, THE IAM_Module SHALL create an instance profile and associate the IAM role with the instance profile
4. WHEN the Terraform IAM module is applied, THE IAM_Module SHALL name the role using the project naming convention `{project_name}-{environment}-btb-service-role`
5. WHEN the BTB_Service runs on the instance, THE IAM instance profile SHALL provide credentials automatically via the EC2 Instance Metadata Service (IMDS), requiring no manual credential configuration or SSO login

### Requirement 3: Security Group Configuration

**User Story:** As a DevOps engineer, I want to configure network access rules for the EC2 instance, so that only authorized traffic can reach the btb-service.

#### Acceptance Criteria

1. WHEN the security group is created, THE Security_Group SHALL allow inbound SSH (port 22) from a configurable list of CIDR blocks
2. WHEN the security group is created, THE Security_Group SHALL allow inbound HTTPS (port 8443) from a configurable list of CIDR blocks defaulting to `0.0.0.0/0`
3. WHEN the security group is created, THE Security_Group SHALL allow all outbound traffic so the instance can reach GitHub, AWS APIs, and package repositories
4. WHEN the security group is created, THE Security_Group SHALL be associated with the existing VPC from the VPC module

### Requirement 4: Root Module Integration

**User Story:** As a DevOps engineer, I want the btb EC2 resources integrated into the existing Terraform root module, so that the infrastructure is managed consistently alongside other project resources.

#### Acceptance Criteria

1. WHEN the btb EC2 feature is enabled, THE root module SHALL wire the EC2 module, IAM module, and security group into `main.tf` with proper variable passing
2. THE root module SHALL expose the EC2 instance public IP, instance ID, and IAM role ARN as outputs
3. THE root module SHALL support enabling or disabling the btb EC2 resources via a boolean variable `enable_btb_ec2` defaulting to `false`
4. WHEN `enable_btb_ec2` is false, THE root module SHALL not create any btb EC2 related resources

### Requirement 5: Automated Instance Provisioning via User Data

**User Story:** As a DevOps engineer, I want the EC2 instance to optionally self-provision on first boot using a user_data script, so that the instance is ready to run btb-service without manual SSH setup.

#### Acceptance Criteria

1. WHEN the EC2 instance boots with user_data enabled, THE User_Data script SHALL clone the btb repository to `/opt/btb`
2. WHEN the EC2 instance boots with user_data enabled, THE User_Data script SHALL execute the Provisioning_Script (`/opt/btb/deploy/provision.sh`) to install dependencies and create the systemd service
3. WHEN the Provisioning_Script completes, THE User_Data script SHALL verify that the directory structure exists at `/var/btb/` (queue, completed, jobs, logs)
4. THE EC2_Module SHALL support a variable to provide the btb Git repository URL for cloning
5. THE EC2_Module SHALL support disabling user_data automation so that manual SSH provisioning remains an option

### Requirement 6: Manual Post-Provisioning Documentation

**User Story:** As a DevOps engineer, I want clear documentation of the manual steps to deploy the btb-service after Terraform provisioning, so that I can complete the setup via SSH if user_data automation is not used.

#### Acceptance Criteria

1. WHEN the EC2 instance is running, THE documentation SHALL describe how to SSH into the instance using the key pair
2. WHEN connected via SSH, THE documentation SHALL describe how to clone the btb repository to `/opt/btb`
3. WHEN the btb repo is cloned, THE documentation SHALL describe how to run `sudo bash /opt/btb/deploy/provision.sh` to install dependencies and create the systemd service
4. WHEN the provisioning script completes, THE documentation SHALL describe the directory structure created at `/var/btb/` (queue, completed, jobs, logs)

### Requirement 7: Service Configuration

**User Story:** As a DevOps engineer, I want to configure the btb-service with the correct environment variables and secrets, so that the service can authenticate with GitHub and process webhooks securely.

#### Acceptance Criteria

1. WHEN configuring the service, THE Config_File SHALL contain all required environment variables: WEBHOOK_SECRET, GITHUB_TOKEN, QUEUE_DIR, COMPLETED_DIR, JOBS_DIR, LOGS_DIR, BTB_PATH, PORT, TLS_CERT, TLS_KEY, JOB_TIMEOUT, LOG_RETENTION_DAYS
2. WHEN the WEBHOOK_SECRET is generated, THE documentation SHALL specify using `openssl rand -hex 32` to produce a 256-bit random secret
3. WHEN the Config_File is written, THE documentation SHALL specify setting ownership to `root:btb` and permissions to `640`
4. WHEN the GITHUB_TOKEN is configured, THE documentation SHALL specify that the token requires `Contents:Read` permission on target repositories
5. WHEN LOG_RETENTION_DAYS is configured, THE BTB_Service SHALL clean up log files on disk older than the specified retention period to prevent disk space exhaustion

### Requirement 8: TLS Certificate Setup

**User Story:** As a DevOps engineer, I want to set up TLS for the btb-service, so that GitHub webhooks can communicate over HTTPS as required.

#### Acceptance Criteria

1. WHEN a TLS certificate is needed and no domain is available, THE documentation SHALL describe generating a self-signed certificate using `openssl req -x509 -newkey rsa:4096`
2. WHEN the TLS certificate files are created, THE documentation SHALL specify storing them at `/etc/btb-service/cert.pem` and `/etc/btb-service/key.pem`
3. WHEN the TLS certificate files are created, THE documentation SHALL specify setting ownership to `root:btb` and permissions to `640`
4. WHERE a domain name is available, THE documentation SHALL describe using Let's Encrypt with certbot as the preferred alternative to self-signed certificates, noting that CA-signed certificates avoid the need to disable SSL verification in GitHub webhooks

### Requirement 9: Service Lifecycle Management

**User Story:** As a DevOps engineer, I want the btb-service managed by systemd, so that the service starts on boot, auto-restarts on failure, and is easy to monitor.

#### Acceptance Criteria

1. WHEN the service is started, THE documentation SHALL describe using `systemctl start btb-service` and verifying status with `systemctl status btb-service`
2. WHEN the service is running, THE BTB_Service SHALL auto-start on instance boot via systemd enablement
3. IF the BTB_Service crashes, THEN THE systemd unit SHALL restart the service within 10 seconds
4. WHEN viewing logs, THE documentation SHALL describe using `journalctl -u btb-service -f` for live log tailing

### Requirement 10: GitHub Webhook Configuration

**User Story:** As a DevOps engineer, I want to configure GitHub webhooks for target repositories, so that push events trigger the btb-service to process specs.

#### Acceptance Criteria

1. WHEN setting up a webhook, THE documentation SHALL describe configuring the payload URL as `https://<ec2-public-ip>:8443/webhook`
2. WHEN setting up a webhook, THE documentation SHALL specify using `application/json` content type and the same WEBHOOK_SECRET from the Config_File
3. IF a self-signed TLS certificate is used, THEN THE documentation SHALL note that SSL verification must be disabled in the webhook settings
4. WHEN setting up a webhook, THE documentation SHALL specify selecting only the `push` event
5. WHEN using the helper script, THE documentation SHALL describe running `deploy/setup-webhook.sh` and note that the script requires a GitHub token with `admin:repo_hook` permission (separate from the Config_File GITHUB_TOKEN)

### Requirement 11: Repository Opt-In and Workflow

**User Story:** As a developer, I want to opt a repository into btb processing by adding a `.btb` file, so that pushes to the repo trigger automated spec execution.

#### Acceptance Criteria

1. WHEN opting in a repository, THE documentation SHALL describe creating a `.btb` file at the repository root containing `spec=my-feature-spec`
2. WHEN a push event is received for a repo with a `.btb` file, THE BTB_Service SHALL read the spec name, enqueue a job, clone the repo, run btb, push results, and update the `.btb` file
3. WHEN the btb processing completes, THE BTB_Service SHALL clean up the cloned repository

### Requirement 12: Dashboard Access

**User Story:** As a DevOps engineer, I want to monitor btb jobs through a web dashboard, so that I can see running, queued, and completed jobs with their logs.

#### Acceptance Criteria

1. WHEN accessing the dashboard, THE BTB_Service SHALL serve a web UI at `https://<instance>:8443/` showing running jobs with live terminal output, queued jobs, and completed jobs with logs
2. WHEN displaying job status, THE Dashboard SHALL auto-refresh every 10 seconds
3. WHEN viewing completed jobs, THE Dashboard SHALL provide a retry option for failed jobs
