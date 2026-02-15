#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HEARTBEAT_FILE="$ROOT_DIR/coordination/state/heartbeat.json"

STATUS="${1:-idle}"
ACTIVE_TASK_ID="${2:-}"
EGPU_READY="${3:-false}"
NOTES="${4:-heartbeat}"

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOST="$(hostname)"
AGENT_ID="${AGENT_ID:-vm-codex-rb1}"
SAFETY_MODE="${SAFETY_MODE:-enforced}"

cat > "$HEARTBEAT_FILE" <<EOF
{
  "agent_id": "$AGENT_ID",
  "host": "$HOST",
  "status": "$STATUS",
  "active_task_id": "$ACTIVE_TASK_ID",
  "last_update_utc": "$TS",
  "egpu_ready": $EGPU_READY,
  "safety_mode": "$SAFETY_MODE",
  "notes": "$NOTES"
}
EOF
