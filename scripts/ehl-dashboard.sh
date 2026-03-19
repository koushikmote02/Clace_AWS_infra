#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# EHL Benchmark CloudWatch Dashboard
# Creates a dashboard with CPU, Memory, Disk IOPS, and Network metrics
# Usage: ./scripts/ehl-dashboard.sh
# -----------------------------------------------------------------------------
set -euo pipefail

REGION="us-east-2"
INSTANCE_ID="i-0853304014d266be6"
DASHBOARD_NAME="EHL-Benchmark-Dashboard"

# Get the EBS volume ID attached to the instance
VOLUME_ID=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
  --output text)

echo "Instance: $INSTANCE_ID"
echo "Volume:   $VOLUME_ID"
echo "Creating dashboard: $DASHBOARD_NAME"

aws cloudwatch put-dashboard \
  --region "$REGION" \
  --dashboard-name "$DASHBOARD_NAME" \
  --dashboard-body "$(cat <<EOF
{
  "widgets": [
    {
      "type": "text",
      "x": 0, "y": 0, "width": 24, "height": 1,
      "properties": {
        "markdown": "# EHL Benchmark (r6i.12xlarge — 48 vCPU, 384 GB RAM) — Instance: ${INSTANCE_ID}"
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 1, "width": 12, "height": 6,
      "properties": {
        "title": "CPU Utilization (%)",
        "metrics": [
          ["AWS/EC2", "CPUUtilization", "InstanceId", "${INSTANCE_ID}", {"stat": "Average", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0, "max": 100}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 1, "width": 12, "height": 6,
      "properties": {
        "title": "Memory Utilization (%)",
        "metrics": [
          ["EHL_Benchmark", "mem_used_percent", "InstanceId", "${INSTANCE_ID}", {"stat": "Average", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0, "max": 100}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 7, "width": 12, "height": 6,
      "properties": {
        "title": "Disk Read/Write IOPS",
        "metrics": [
          ["AWS/EBS", "VolumeReadOps", "VolumeId", "${VOLUME_ID}", {"stat": "Sum", "period": 60, "label": "Read IOPS"}],
          ["AWS/EBS", "VolumeWriteOps", "VolumeId", "${VOLUME_ID}", {"stat": "Sum", "period": 60, "label": "Write IOPS"}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 7, "width": 12, "height": 6,
      "properties": {
        "title": "Disk Read/Write Throughput (Bytes)",
        "metrics": [
          ["AWS/EBS", "VolumeReadBytes", "VolumeId", "${VOLUME_ID}", {"stat": "Sum", "period": 60, "label": "Read Bytes"}],
          ["AWS/EBS", "VolumeWriteBytes", "VolumeId", "${VOLUME_ID}", {"stat": "Sum", "period": 60, "label": "Write Bytes"}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 13, "width": 12, "height": 6,
      "properties": {
        "title": "Network In/Out (Bytes)",
        "metrics": [
          ["AWS/EC2", "NetworkIn", "InstanceId", "${INSTANCE_ID}", {"stat": "Sum", "period": 60, "label": "Network In"}],
          ["AWS/EC2", "NetworkOut", "InstanceId", "${INSTANCE_ID}", {"stat": "Sum", "period": 60, "label": "Network Out"}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 13, "width": 12, "height": 6,
      "properties": {
        "title": "Network Packets In/Out",
        "metrics": [
          ["AWS/EC2", "NetworkPacketsIn", "InstanceId", "${INSTANCE_ID}", {"stat": "Sum", "period": 60, "label": "Packets In"}],
          ["AWS/EC2", "NetworkPacketsOut", "InstanceId", "${INSTANCE_ID}", {"stat": "Sum", "period": 60, "label": "Packets Out"}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 19, "width": 8, "height": 6,
      "properties": {
        "title": "Memory Used (GB)",
        "metrics": [
          ["EHL_Benchmark", "mem_used", "InstanceId", "${INSTANCE_ID}", {"stat": "Average", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 8, "y": 19, "width": 8, "height": 6,
      "properties": {
        "title": "Disk Used (%)",
        "metrics": [
          ["EHL_Benchmark", "disk_used_percent", "InstanceId", "${INSTANCE_ID}", "path", "/", "device", "nvme0n1p1", "fstype", "xfs", {"stat": "Average", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0, "max": 100}},
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 16, "y": 19, "width": 8, "height": 6,
      "properties": {
        "title": "EBS Queue Length",
        "metrics": [
          ["AWS/EBS", "VolumeQueueLength", "VolumeId", "${VOLUME_ID}", {"stat": "Average", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "yAxis": {"left": {"min": 0}},
        "period": 60
      }
    }
  ]
}
EOF
)"

echo ""
echo "Dashboard created successfully!"
echo "View it at: https://${REGION}.console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards/dashboard/${DASHBOARD_NAME}"
