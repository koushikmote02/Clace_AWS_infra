# btb-service Deployment Guide

Complete guide to deploying the btb-service on AWS EC2 using the Terraform infrastructure in this repo.

---

## What We Built

This project provisions the following AWS resources for the btb-service via Terraform:

| Resource | Module | Purpose |
|---|---|---|
| EC2 Instance | `modules/btb-ec2` | Amazon Linux 2023, t3.medium (configurable), 50GB gp3 encrypted volume, public IP |
| IAM Role + Instance Profile | `modules/btb-iam` | EC2 trust policy with `bedrock:InvokeModel` and `bedrock:InvokeModelWithResponseStream` permissions |
| Security Group | `modules/security-groups` | SSH (port 22) from your IP, HTTPS (port 8443) for GitHub webhooks, all outbound |

Everything is gated behind `enable_btb_ec2 = true` — when false, zero btb resources are created.

### Terraform Outputs (when enabled)

| Output | Description |
|---|---|
| `btb_ec2_public_ip` | Public IP of the EC2 instance |
| `btb_ec2_instance_id` | EC2 instance ID |
| `btb_iam_role_arn` | IAM role ARN for the btb-service |

---

## Prerequisites

Before deploying, you need:

1. **Terraform installed** (check with `terraform version`)
2. **AWS credentials configured** with permissions to create EC2, IAM, and VPC resources
3. **An SSH key pair** — either an existing AWS key pair name, or a public key to create one
4. **Your public IP** for SSH access (find it at https://checkip.amazonaws.com)
5. **The btb GitHub repo URL** (you'll clone this onto the EC2 instance)
6. **Two GitHub tokens** (created during post-provisioning):
   - Token 1: Fine-grained with `Contents:Read` on target repos (for config.env)
   - Token 2: Classic or fine-grained with `admin:repo_hook` (for webhook setup, one-time per repo)

---

## Step 1: Configure Terraform Variables

Edit `environments/dev.tfvars` and uncomment the btb section:

```hcl
enable_btb_ec2        = true
btb_instance_type     = "t3.medium"       # or t3.large for more RAM
btb_root_volume_size  = 50                # GB, minimum 50
btb_key_pair_name     = "your-key-pair"   # existing AWS key pair name
btb_ssh_cidr_blocks   = ["YOUR.IP.HERE/32"]  # your IP for SSH
btb_https_cidr_blocks = ["0.0.0.0/0"]     # GitHub webhooks need public access
btb_repo_url          = "https://github.com/your-org/btb.git"
btb_enable_user_data  = false             # true = auto-provision on boot
```

If you want Terraform to create a new key pair instead of using an existing one, set the public key via environment variable:

```bash
export TF_VAR_btb_ssh_public_key="ssh-rsa AAAA... your-email@example.com"
```

And leave `btb_key_pair_name` empty.

---

## Step 2: Deploy the Infrastructure

```bash
# Initialize (registers the new btb modules)
terraform init

# Preview what will be created
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars
```

Terraform creates 8 resources: EC2 instance, IAM role, IAM policy, instance profile, security group, and 3 security group rules.

After apply, grab the instance IP:

```bash
export BTB_IP=$(terraform output -raw btb_ec2_public_ip)
echo "Instance IP: $BTB_IP"
```

---

## Step 3: SSH into the Instance

```bash
ssh -i /path/to/your-key.pem ec2-user@$BTB_IP
```

> Default user for Amazon Linux 2023 is `ec2-user`. If SSH times out, verify your IP is in `btb_ssh_cidr_blocks`.

---

## Step 4: Clone the btb Repo and Provision

Skip this if you set `btb_enable_user_data = true` (it ran automatically on boot).

```bash
# Clone btb
sudo git clone https://github.com/your-org/btb.git /opt/btb

# Run the provisioning script
sudo bash /opt/btb/deploy/provision.sh
```

This installs: bash, git, python3, pip, perl, aiohttp, kiro-cli (via npm), creates the `btb` service user, sets up `/var/btb/` directories, installs the systemd unit, and copies the example config.

Verify the directory structure:

```bash
ls -d /var/btb/queue /var/btb/completed /var/btb/jobs /var/btb/logs
```

---

## Step 5: Configure the Service

### 5.1 Generate a webhook secret

```bash
openssl rand -hex 32
# Save this output — you need it here AND in the GitHub webhook setup
```

### 5.2 Create a GitHub token

Go to [github.com/settings/tokens](https://github.com/settings/tokens?type=beta) and create a fine-grained token:
- Repository access: select the repos btb will process
- Permissions: `Contents: Read` only

### 5.3 Write the config file

```bash
sudo tee /etc/btb-service/config.env << 'EOF'
WEBHOOK_SECRET=<your-generated-secret>
GITHUB_TOKEN=<your-github-token>
QUEUE_DIR=/var/btb/queue
COMPLETED_DIR=/var/btb/completed
JOBS_DIR=/var/btb/jobs
LOGS_DIR=/var/btb/logs
BTB_PATH=/opt/btb
PORT=8443
TLS_CERT=/etc/btb-service/cert.pem
TLS_KEY=/etc/btb-service/key.pem
JOB_TIMEOUT=7200
LOG_RETENTION_DAYS=7
EOF
```

### 5.4 Lock down permissions

```bash
sudo chown root:btb /etc/btb-service/config.env
sudo chmod 640 /etc/btb-service/config.env
```

---

## Step 6: Set Up TLS

GitHub webhooks require HTTPS. Pick one:

### Option A: Self-Signed (quick, no domain needed)

```bash
sudo openssl req -x509 \
  -newkey rsa:4096 \
  -keyout /etc/btb-service/key.pem \
  -out /etc/btb-service/cert.pem \
  -days 365 -nodes \
  -subj "/CN=btb-service"
```

> You'll need to disable SSL verification in the GitHub webhook settings with this option.

### Option B: Let's Encrypt (if you have a domain)

```bash
sudo dnf install -y certbot
sudo certbot certonly --standalone -d your-domain.com
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /etc/btb-service/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /etc/btb-service/key.pem
```

### Set cert permissions (either option)

```bash
sudo chown root:btb /etc/btb-service/cert.pem /etc/btb-service/key.pem
sudo chmod 640 /etc/btb-service/cert.pem /etc/btb-service/key.pem
```

---

## Step 7: Start the Service

```bash
sudo systemctl start btb-service
sudo systemctl status btb-service
```

You should see `Active: active (running)`. The service auto-starts on boot and auto-restarts within 10 seconds if it crashes.

View logs:

```bash
sudo journalctl -u btb-service -f
```

---

## Step 8: Set Up GitHub Webhooks

For each repo you want btb to process:

### Manual (GitHub UI)

1. Repo → Settings → Webhooks → Add webhook
2. Payload URL: `https://<BTB_IP>:8443/webhook`
3. Content type: `application/json`
4. Secret: same `WEBHOOK_SECRET` from config.env
5. SSL verification: **Disable** if self-signed cert, **Enable** if Let's Encrypt
6. Events: **Just the push event**

### Script (from the instance)

```bash
export GITHUB_TOKEN=ghp_your_admin_repo_hook_token
bash /opt/btb/deploy/setup-webhook.sh your-org/your-repo https://$BTB_IP:8443 your-webhook-secret
```

> This token needs `admin:repo_hook` permission — separate from the `Contents:Read` token in config.env.

---

## Step 9: Opt In a Repo

Create a `.btb` file at the repo root:

```bash
echo "spec=my-feature-spec" > .btb
git add .btb && git commit -m "Enable btb" && git push
```

The `spec` value must match a directory name in `.kiro/specs/` in that repo. For example, if the repo has `.kiro/specs/user-authentication/`, use `spec=user-authentication`.

On push, btb-service will: receive the webhook → read the `.btb` file → enqueue a job → clone the repo → run btb against the spec → push results → clean up.

---

## Step 10: Access the Dashboard

```
https://<BTB_IP>:8443/
```

Shows running jobs (live terminal via xterm.js), queued jobs, and completed jobs with logs and retry. Auto-refreshes every 10 seconds.

> Accept the browser security warning if using a self-signed cert.

---

## Quick Reference

| What | Where / Command |
|---|---|
| Service logs | `sudo journalctl -u btb-service -f` |
| Config file | `/etc/btb-service/config.env` |
| Job queue | `/var/btb/queue/` |
| Completed jobs | `/var/btb/completed/` |
| Preserved logs | `/var/btb/logs/{job_id}/` |
| btb code | `/opt/btb/` |
| Restart service | `sudo systemctl restart btb-service` |
| Stop service | `sudo systemctl stop btb-service` |
| Dashboard | `https://<BTB_IP>:8443/` |
| User data log | `/var/log/user-data.log` |

---

## GitHub Token Summary

| Token | Scope | Used For |
|---|---|---|
| config.env `GITHUB_TOKEN` | `Contents:Read` on target repos | btb-service checks for `.btb` files and clones repos on every push |
| setup-webhook.sh token | `admin:repo_hook` | One-time webhook creation per repo |

For org-wide access, create tokens at the org level or use a GitHub App with the right permissions.

---

## AWS Credentials

The IAM instance profile provides Bedrock credentials automatically via IMDS. No manual `aws configure`, no SSO login, no access keys needed on the instance. If your org uses IAM Identity Center and you need additional permissions beyond Bedrock, you can optionally configure SSO:

```bash
aws configure sso --profile btb-service
aws sso login --profile btb-service
```

Then add `AWS_PROFILE=btb-service` to config.env. But for most setups, the instance profile is sufficient.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| SSH timeout | Check `btb_ssh_cidr_blocks` includes your IP |
| Service won't start | `sudo journalctl -u btb-service -n 50 --no-pager` — check for missing config or bad cert paths |
| Webhooks not arriving | Verify port 8443 is open (`btb_https_cidr_blocks`), check WEBHOOK_SECRET matches, check SSL verification setting |
| Bedrock errors | `curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/` to verify instance profile |
| Disk full | Check `df -h`, adjust `LOG_RETENTION_DAYS` or increase `btb_root_volume_size` in Terraform |
| User data failed | `cat /var/log/user-data.log` on the instance |
