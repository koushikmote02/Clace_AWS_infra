#!/bin/bash
# =============================================================================
# Clace API Dashboard — Real-time metrics from CloudWatch Logs
# Usage: ./scripts/api-dashboard.sh [hours_back]  (default: 1)
# =============================================================================

set -euo pipefail

REGION="us-east-2"
LOG_GROUP="/ecs/clace-dev-api"
HOURS_BACK="${1:-1}"

END_TIME=$(python3 -c "import time; print(int(time.time()))")
START_TIME=$(python3 -c "import time; print(int(time.time() - 3600 * $HOURS_BACK))")

# Regex to parse "Request completed" lines (handles ANSI escape codes in logs)
# status uses \d\d\d (exactly 3 digits + space) to avoid matching ANSI code digits
# duration uses \d+$ (anchored to EOL) since it's the last field
PARSE_REQUEST='/method.*=.*?(?<method>GET|POST|PUT|DELETE|PATCH).*path.*=.*?(?<path>\/\S+).*status.*=.*?(?<status>\d\d\d) .*duration_ms.*=.*?(?<duration>\d+)$/'

run_query() {
  local query="$1"
  local query_id
  query_id=$(aws logs start-query \
    --log-group-name "$LOG_GROUP" \
    --start-time "$START_TIME" \
    --end-time "$END_TIME" \
    --query-string "$query" \
    --region "$REGION" \
    --output text --query 'queryId')

  sleep 3
  aws logs get-query-results --query-id "$query_id" --region "$REGION" 2>/dev/null
}

parse_rows() {
  python3 -c "
import json, sys
data = json.load(sys.stdin)
results = data.get('results', [])
$1
"
}

echo "=============================================="
echo "  CLACE API DASHBOARD — Last ${HOURS_BACK}h"
echo "  $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "=============================================="
echo ""

# --- 1. Endpoint breakdown (excluding health checks) ---
echo "📊 ENDPOINT REQUEST COUNTS"
echo "----------------------------------------------"
RESULT=$(run_query "fields @message
| filter @message like /Request completed/
| parse @message ${PARSE_REQUEST}
| filter path != \"/health\"
| stats count(*) as requests by concat(method, \" \", path) as endpoint
| sort requests desc
| limit 20")

echo "$RESULT" | parse_rows "
for row in results:
    fields = {f['field']: f['value'] for f in row}
    endpoint = fields.get('endpoint', '?')
    count = fields.get('requests', '0')
    print(f'  {count:>6}  {endpoint}')
if not results:
    print('  (no data)')
"
echo ""

# --- 2. Status code distribution ---
echo "📈 STATUS CODE DISTRIBUTION"
echo "----------------------------------------------"
RESULT=$(run_query "fields @message
| filter @message like /Request completed/
| parse @message ${PARSE_REQUEST}
| filter path != \"/health\"
| filter ispresent(status)
| stats count(*) as requests by status
| sort status asc")

echo "$RESULT" | parse_rows "
for row in results:
    fields = {f['field']: f['value'] for f in row}
    status = fields.get('status', '?').strip()
    count = fields.get('requests', '0')
    emoji = '✅' if status.startswith('2') else '⚠️' if status.startswith('4') else '❌' if status.startswith('5') else '❓'
    print(f'  {emoji} {status}: {count} requests')
if not results:
    print('  (no data)')
"
echo ""

# --- 3. Unique active users ---
echo "👥 UNIQUE ACTIVE USERS"
echo "----------------------------------------------"
RESULT=$(run_query 'fields @message
| filter @message like /user_id/
| parse @message /user_id.*=.*?(?<user_id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
| stats count(*) as actions by user_id
| sort actions desc
| limit 30')

echo "$RESULT" | parse_rows "
total = len(results)
print(f'  Total unique users: {total}')
print()
for i, row in enumerate(results[:15]):
    fields = {f['field']: f['value'] for f in row}
    uid = fields.get('user_id', '?')[:36]
    actions = fields.get('actions', '0')
    print(f'  {uid}  ({actions} actions)')
if total > 15:
    print(f'  ... and {total - 15} more')
if not results:
    print('  (no data)')
"
echo ""

# --- 4. Auth events ---
echo "🔐 AUTH EVENTS"
echo "----------------------------------------------"
RESULT=$(run_query "fields @message
| filter @message like /Request completed/
| parse @message ${PARSE_REQUEST}
| filter path like /auth/
| filter ispresent(status)
| stats count(*) as requests by concat(method, \" \", path) as endpoint, status
| sort requests desc")

echo "$RESULT" | parse_rows "
if not results:
    print('  No auth events')
for row in results:
    fields = {f['field']: f['value'] for f in row}
    endpoint = fields.get('endpoint', '?')
    status = fields.get('status', '?')
    count = fields.get('requests', '0')
    emoji = '✅' if status.startswith('2') else '⚠️' if status.startswith('4') else '❌'
    print(f'  {emoji} {count:>4}  {endpoint}  → {status}')
"
echo ""

# --- 5. Billing activity ---
echo "💳 BILLING ACTIVITY"
echo "----------------------------------------------"
RESULT=$(run_query "fields @message
| filter @message like /Request completed/
| parse @message ${PARSE_REQUEST}
| filter path like /billing/
| stats count(*) as requests by concat(method, \" \", path) as endpoint
| sort requests desc")

echo "$RESULT" | parse_rows "
if not results:
    print('  No billing activity')
for row in results:
    fields = {f['field']: f['value'] for f in row}
    endpoint = fields.get('endpoint', '?')
    count = fields.get('requests', '0')
    print(f'  {count:>6}  {endpoint}')
"
echo ""

# --- 6. Canvas/AI usage ---
echo "🎨 CANVAS / AI USAGE"
echo "----------------------------------------------"
RESULT=$(run_query "fields @message
| filter @message like /Request completed/
| parse @message ${PARSE_REQUEST}
| filter path like /canvas/
| stats count(*) as requests by concat(method, \" \", path) as endpoint
| sort requests desc")

echo "$RESULT" | parse_rows "
if not results:
    print('  No canvas activity')
for row in results:
    fields = {f['field']: f['value'] for f in row}
    endpoint = fields.get('endpoint', '?')
    count = fields.get('requests', '0')
    print(f'  {count:>6}  {endpoint}')
"
echo ""

# --- 7. Slowest endpoints (avg response time) ---
echo "🐢 SLOWEST ENDPOINTS (avg ms)"
echo "----------------------------------------------"
RESULT=$(run_query "fields @message
| filter @message like /Request completed/
| parse @message ${PARSE_REQUEST}
| filter path != \"/health\"
| filter ispresent(duration)
| stats avg(duration) as avg_ms, max(duration) as max_ms, count(*) as reqs by path
| sort avg_ms desc
| limit 10")

echo "$RESULT" | parse_rows "
for row in results:
    fields = {f['field']: f['value'] for f in row}
    path = fields.get('path', '?')
    avg_ms = fields.get('avg_ms', '?')
    max_ms = fields.get('max_ms', '?')
    reqs = fields.get('reqs', '0')
    try:
        avg_f = float(avg_ms)
        max_f = float(max_ms)
        print(f'  {path:<40} avg={avg_f:>7.0f}ms  max={max_f:>7.0f}ms  ({reqs} reqs)')
    except:
        print(f'  {path:<40} avg={avg_ms}ms  max={max_ms}ms  ({reqs} reqs)')
if not results:
    print('  (no data)')
"
echo ""

# --- 8. Error summary ---
echo "❌ ERRORS & WARNINGS"
echo "----------------------------------------------"
RESULT=$(run_query 'fields @message
| filter @message like /Request error|WARN|ERROR/
| filter @message not like /health/
| parse @message /error.*=.*?(?<error_msg>[A-Z][a-z][\w\s]+)/
| stats count(*) as total by error_msg
| sort total desc
| limit 10')

echo "$RESULT" | parse_rows "
if not results:
    print('  No errors or warnings 🎉')
else:
    total = sum(int({f['field']: f['value'] for f in row}.get('total', '0')) for row in results)
    print(f'  Total: {total}')
    print()
    for row in results:
        fields = {f['field']: f['value'] for f in row}
        msg = fields.get('error_msg', '(unknown)')
        count = fields.get('total', '0')
        print(f'  {count:>6}  {msg}')
"
echo ""

# --- 9. Requests per 10-minute bucket (traffic pattern) ---
echo "📉 TRAFFIC PATTERN (per 10min)"
echo "----------------------------------------------"
RESULT=$(run_query "fields @message
| filter @message like /Request completed/
| parse @message /path.*=.*?(?<path>\/\S+)/
| filter path != \"/health\"
| stats count(*) as requests by bin(10m) as time_bucket
| sort time_bucket asc")

echo "$RESULT" | parse_rows "
if not results:
    print('  (no data)')
else:
    max_req = max(int({f['field']: f['value'] for f in row}.get('requests', '0')) for row in results)
    for row in results:
        fields = {f['field']: f['value'] for f in row}
        ts = fields.get('time_bucket', '?')
        reqs = int(fields.get('requests', '0'))
        bar_len = int(reqs / max(max_req, 1) * 30)
        bar = '█' * bar_len
        short_ts = ts[11:16] if len(ts) > 16 else ts
        print(f'  {short_ts}  {bar} {reqs}')
"
echo ""

echo "=============================================="
echo "  Run: ./scripts/api-dashboard.sh 6   (last 6h)"
echo "  Run: ./scripts/api-dashboard.sh 24  (last 24h)"
echo "=============================================="
