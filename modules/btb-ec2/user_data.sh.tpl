#!/bin/bash
set -euo pipefail

# Log all output for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== btb-service provisioning started ==="

# Clone btb repository
echo "Cloning btb repository..."
git clone ${btb_repo_url} /opt/btb

# Run provisioning script
echo "Running provision.sh..."
bash /opt/btb/deploy/provision.sh

# Verify directory structure
echo "Verifying /var/btb/ directory structure..."
for dir in /var/btb/queue /var/btb/completed /var/btb/jobs /var/btb/logs; do
  if [ ! -d "$dir" ]; then
    echo "ERROR: Expected directory $dir does not exist"
    exit 1
  fi
  echo "  OK: $dir exists"
done

echo "=== btb-service provisioning completed ==="
