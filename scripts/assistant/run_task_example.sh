#!/usr/bin/env bash
set -euo pipefail

# Example wrapper for executing one task with guardrails.
# This script intentionally keeps behavior minimal and auditable.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-$ROOT_DIR/coordination/tasks/TASK_TEMPLATE.yaml}"

"$ROOT_DIR/scripts/assistant/claim_task.sh" "$TASK_FILE"

TASK_ID="$(awk -F': ' '/^id:/{print $2; exit}' "$TASK_FILE")"
CMD_FILE="$(mktemp)"
cat > "$CMD_FILE" <<'EOF'
echo "replace with real task commands"
sleep 1
EOF

"$ROOT_DIR/scripts/assistant/watchdog_guard.sh" 45 "$TASK_ID" "$CMD_FILE"
rm -f "$CMD_FILE"
