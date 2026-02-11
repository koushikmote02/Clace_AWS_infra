# btb-service Post-Provisioning Guide

This guide covers everything you need to do after `terraform apply` to get a fully working btb-service with GitHub webhook integration.

**Prerequisites:** You have already run `terraform apply` with `enable_btb_ec2 = true` and have the instance running.

---

## 1. Get Your Instance IP

```bash
terraform output btb_ec2_public_ip
```

Store it for use throughout this guide:

```bash
export BTB_IP=$(terraform output -raw btb_ec2_public_ip)
```

---

## 2. SSH into the Instance

Connect using the key pair you configured in Terraform:

```bash
# If you provided ssh_public_key (Terraform-managed key pair):
ssh -i ~/.ssh/your-private-key ec2-user@$BTB_IP

# If you used an existing key_pair_name:
ssh -i /path/to/that/key.pem ec2-user@$BTB_IP
```

> **Note:** The default user for Amazon Linux 2023 is `ec2-user`. If SSH times out, verify the security group allows port 22 from your IP (check `btb_ssh_cidr_blocks`).

---

## 3. Clone and Provision (Manual Setup)

Skip this section if you enabled `btb_enable_user_data = true` — the instance already ran these steps on first boot. You can verify by checking:

```bash
ls /opt/btb/deploy/provision.sh && echo "Already provisioned" || echo "Needs provisioning"
```

### 3.1 Clone the btb Repository

```bash
sudo git clone https://github.com/your-org/btb.git /opt/btb
```

### 3.2 Run the Provisioning Script

```bash
sudo bash /opt/btb/deploy/provision.sh
```

This script installs dependencies and creates the `btb-service` systemd unit.

### 3.3 Verify Directory Structure

The provisioning script creates the following directories under `/var/btb/`:

```bash
for dir in /var/btb/queue /var/btb/completed /var/btb/jobs /var/btb/logs; do
  ls -ld "$dir"
done
```

Expected output — all four directories exist:

```
/var/btb/queue
/var/btb/completed
/var/btb/jobs
/var/btb/logs
```

---

## 4. Configure the Service

### 4.1 Generate the Webhook Secret

```bash
openssl rand -hex 32
```

Copy the output — you'll need it here and again when setting up the GitHub webhook.

### 4.2 Create a GitHub Token

Create a **fine-grained personal access token** at [github.com/settings/tokens](https://github.com/settings/tokens?type=beta):

- **Repository access:** Select the repositories btb will process
- **Permissions:** `Contents: Read` (this is the only permission required)

### 4.3 Write the Config File

```bash
sudo tee /etc/btb-service/config.env << 'EOF'
WEBHOOK_SECRET=<paste-your-webhook-secret-here>
GITHUB_TOKEN=<paste-your-github-token-here>
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

Replace `<paste-your-webhook-secret-here>` and `<paste-your-github-token-here>` with actual values.

**Environment variables reference:**

| Variable | Description |
|---|---|
| `WEBHOOK_SECRET` | Shared secret for GitHub webhook HMAC validation |
| `GITHUB_TOKEN` | Fine-grained token with `Contents:Read` for cloning repos |
| `QUEUE_DIR` | Directory for queued jobs |
| `COMPLETED_DIR` | Directory for completed jobs |
| `JOBS_DIR` | Directory for active job data |
| `LOGS_DIR` | Directory for job logs |
| `BTB_PATH` | Path to the btb repository |
| `PORT` | HTTPS port the service listens on |
| `TLS_CERT` | Path to TLS certificate file |
| `TLS_KEY` | Path to TLS private key file |
| `JOB_TIMEOUT` | Maximum job runtime in seconds (default: 7200 = 2 hours) |
| `LOG_RETENTION_DAYS` | Days to keep log files before cleanup (prevents disk exhaustion) |

### 4.4 Set Config File Permissions

```bash
sudo chown root:btb /etc/btb-service/config.env
sudo chmod 640 /etc/btb-service/config.env
```

This ensures only root and the `btb` service group can read the secrets.

---

## 5. Set Up TLS Certificates

The btb-service requires HTTPS on port 8443. Choose one of the two options below.

### Option A: Self-Signed Certificate (Quick Setup, No Domain Required)

```bash
sudo openssl req -x509 \
  -newkey rsa:4096 \
  -keyout /etc/btb-service/key.pem \
  -out /etc/btb-service/cert.pem \
  -days 365 \
  -nodes \
  -subj "/CN=btb-service"
```

> **Important:** With a self-signed certificate, you must disable SSL verification in the GitHub webhook settings (see Section 7).

### Option B: Let's Encrypt Certificate (Requires a Domain Name)

If you have a domain name pointing to the instance IP, use certbot for a CA-signed certificate:

```bash
# Install certbot
sudo dnf install -y certbot

# Obtain certificate (temporarily stop btb-service if it's running on 443)
sudo certbot certonly --standalone -d your-domain.com

# Copy/symlink certs to the btb-service location
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /etc/btb-service/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /etc/btb-service/key.pem
```

CA-signed certificates are preferred because GitHub can verify them without disabling SSL verification.

### Set Certificate File Permissions

Regardless of which option you chose:

```bash
sudo chown root:btb /etc/btb-service/cert.pem /etc/btb-service/key.pem
sudo chmod 640 /etc/btb-service/cert.pem /etc/btb-service/key.pem
```

---

## 6. Start and Verify the Service

### Start the Service

```bash
sudo systemctl start btb-service
```

### Check Status

```bash
sudo systemctl status btb-service
```

You should see `Active: active (running)`. The service is configured to auto-start on boot and auto-restart on failure (within 10 seconds).

### View Live Logs

```bash
sudo journalctl -u btb-service -f
```

### Other Useful Commands

```bash
# Stop the service
sudo systemctl stop btb-service

# Restart the service (e.g., after config changes)
sudo systemctl restart btb-service

# Disable auto-start on boot
sudo systemctl disable btb-service

# View recent logs (last 100 lines)
sudo journalctl -u btb-service -n 100 --no-pager
```

---

## 7. Configure GitHub Webhooks

You need to set up a webhook on each GitHub repository that btb should process. There are two ways to do this.

### Option A: Manual Setup via GitHub UI

1. Go to your repository → **Settings** → **Webhooks** → **Add webhook**
2. Configure:
   - **Payload URL:** `https://<your-btb-ip>:8443/webhook`
     ```
     https://$BTB_IP:8443/webhook
     ```
   - **Content type:** `application/json`
   - **Secret:** Paste the same `WEBHOOK_SECRET` value from your config.env
   - **SSL verification:**
     - If using a **self-signed certificate**: select **Disable** (you can always switch to Enable after moving to a CA-signed cert)
     - If using a **Let's Encrypt / CA-signed certificate**: leave **Enable SSL verification** selected
   - **Which events:** Select **Just the push event**
3. Click **Add webhook**

### Option B: Helper Script

The btb repo includes a helper script that automates webhook creation:

```bash
bash /opt/btb/deploy/setup-webhook.sh
```

> **Important:** This script requires a GitHub token with `admin:repo_hook` permission. This is a **separate token** from the `GITHUB_TOKEN` in config.env (which only needs `Contents:Read`). The `admin:repo_hook` scope allows creating and managing webhooks on repositories.

---

## 8. Opt Repositories into btb Processing

For btb to process a repository, it needs a `.btb` file at the repository root.

### Create the .btb File

In each repository you want btb to process, add a `.btb` file:

```bash
echo "spec=my-feature-spec" > .btb
git add .btb
git commit -m "Enable btb processing"
git push
```

Replace `my-feature-spec` with the name of the spec you want btb to run.

### How It Works

When a push event is received for a repo with a `.btb` file:

1. btb-service reads the spec name from the `.btb` file
2. Enqueues a job
3. Clones the repository
4. Runs btb with the specified spec
5. Pushes results back to the repository
6. Updates the `.btb` file with status
7. Cleans up the cloned repository

---

## 9. Access the Dashboard

The btb-service serves a web dashboard at:

```
https://<your-btb-ip>:8443/
```

```bash
echo "https://$BTB_IP:8443/"
```

The dashboard shows:

- **Running jobs** with live terminal output
- **Queued jobs** waiting to be processed
- **Completed jobs** with logs and a retry option for failed jobs

The dashboard auto-refreshes every 10 seconds.

> **Note:** If using a self-signed certificate, your browser will show a security warning. Accept the risk to proceed — the connection is still encrypted.

---

## Troubleshooting

### Service won't start

```bash
# Check logs for errors
sudo journalctl -u btb-service -n 50 --no-pager

# Verify config file exists and is readable
sudo ls -la /etc/btb-service/config.env

# Verify TLS certs exist and are readable
sudo ls -la /etc/btb-service/cert.pem /etc/btb-service/key.pem

# Verify the btb binary/repo is in place
ls -la /opt/btb/
```

### Webhooks not arriving

```bash
# Check the service is listening
sudo ss -tlnp | grep 8443

# Check GitHub webhook delivery history
# Go to repo → Settings → Webhooks → Recent Deliveries

# Common issues:
# - Security group doesn't allow port 8443 from GitHub IPs (check btb_https_cidr_blocks)
# - WEBHOOK_SECRET mismatch between config.env and GitHub
# - SSL verification enabled with self-signed cert
```

### User data provisioning failed

```bash
# Check the user_data log
cat /var/log/user-data.log
```

### Disk space issues

```bash
# Check disk usage
df -h

# LOG_RETENTION_DAYS in config.env controls automatic log cleanup
# Increase btb_root_volume_size in Terraform if needed
```

### AWS Bedrock not working

The IAM instance profile provides credentials automatically via IMDS — no manual credential configuration or SSO login is needed. If Bedrock calls fail:

```bash
# Verify the instance profile is attached
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Verify Bedrock is available in your region
aws bedrock list-foundation-models --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region) --max-results 1
```
