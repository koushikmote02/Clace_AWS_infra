#!/bin/bash
# -----------------------------------------------------------------------------
# AWS MGN Setup & Agent Installation Script
# -----------------------------------------------------------------------------
# Usage:
#   1. Initialize MGN in target region:
#      ./scripts/mgn-setup.sh init
#
#   2. Install agent on a source instance (run via SSH on the source):
#      ./scripts/mgn-setup.sh install-agent <ACCESS_KEY> <SECRET_KEY> <TARGET_REGION>
#
#   3. Check replication status:
#      ./scripts/mgn-setup.sh status
# -----------------------------------------------------------------------------

set -euo pipefail

TARGET_REGION="${TARGET_REGION:-us-east-2}"

case "${1:-help}" in
  init)
    echo "=== Initializing AWS MGN in ${TARGET_REGION} ==="
    aws mgn initialize-service --region "${TARGET_REGION}" 2>/dev/null || echo "MGN already initialized in ${TARGET_REGION}"
    echo ""
    echo "MGN initialized. Next steps:"
    echo "  1. Run 'terraform apply' to create IAM roles and security groups"
    echo "  2. Get agent credentials from Terraform outputs"
    echo "  3. Install agent on each source instance"
    echo ""
    ;;

  install-agent)
    ACCESS_KEY="${2:?Usage: $0 install-agent <ACCESS_KEY> <SECRET_KEY> <TARGET_REGION>}"
    SECRET_KEY="${3:?Usage: $0 install-agent <ACCESS_KEY> <SECRET_KEY> <TARGET_REGION>}"
    REGION="${4:-$TARGET_REGION}"

    echo "=== Installing MGN Replication Agent ==="
    echo "Target region: ${REGION}"

    # Download and install the agent (Linux)
    if [ -f /etc/os-release ]; then
      wget -O ./aws-replication-installer-init https://aws-application-migration-service-${REGION}.s3.${REGION}.amazonaws.com/latest/linux/aws-replication-installer-init
      chmod +x aws-replication-installer-init
      sudo ./aws-replication-installer-init \
        --region "${REGION}" \
        --aws-access-key-id "${ACCESS_KEY}" \
        --aws-secret-access-key "${SECRET_KEY}" \
        --no-prompt
      echo "Agent installed successfully."
    else
      echo "This script supports Linux only. For Windows, download the agent from:"
      echo "https://aws-application-migration-service-${REGION}.s3.${REGION}.amazonaws.com/latest/windows/AwsReplicationWindowsInstaller.exe"
    fi
    ;;

  status)
    echo "=== MGN Replication Status in ${TARGET_REGION} ==="
    aws mgn describe-source-servers --region "${TARGET_REGION}" \
      --query 'items[*].{SourceID:sourceServerID,Hostname:sourceProperties.identificationHints.hostname,State:dataReplicationInfo.dataReplicationState,Lag:dataReplicationInfo.lagDuration}' \
      --output table
    ;;

  *)
    echo "Usage: $0 {init|install-agent|status}"
    echo ""
    echo "Commands:"
    echo "  init           - Initialize MGN service in target region"
    echo "  install-agent  - Install replication agent on source instance"
    echo "  status         - Check replication status of all source servers"
    ;;
esac
