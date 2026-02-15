#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT_MINUTES="${1:-45}"
TASK_ID="${2:--}"
COMMAND_FILE="${3:-}"

if [[ -z "$COMMAND_FILE" || ! -f "$COMMAND_FILE" ]]; then
  echo "usage: $0 <timeout-minutes> <task-id> <command-file>" >&2
  exit 1
fi

if ! "$ROOT_DIR/scripts/assistant/check_egpu_ready.sh" rb1-pve >/dev/null; then
  "$ROOT_DIR/scripts/assistant/emit_event.sh" "task_blocked" "$TASK_ID" "warn" "blocked: egpu not ready"
  "$ROOT_DIR/scripts/assistant/heartbeat.sh" "blocked" "$TASK_ID" "false" "egpu gate failed"
  exit 2
fi

"$ROOT_DIR/scripts/assistant/heartbeat.sh" "running" "$TASK_ID" "true" "watchdog started"
"$ROOT_DIR/scripts/assistant/emit_event.sh" "task_started" "$TASK_ID" "info" "watchdog started"

if timeout "$(( TIMEOUT_MINUTES * 60 ))" bash "$COMMAND_FILE"; then
  "$ROOT_DIR/scripts/assistant/emit_event.sh" "task_done" "$TASK_ID" "info" "command file finished"
  "$ROOT_DIR/scripts/assistant/heartbeat.sh" "idle" "" "true" "task done"
  exit 0
fi

code=$?
if [[ "$code" -eq 124 ]]; then
  "$ROOT_DIR/scripts/assistant/emit_event.sh" "watchdog_kill" "$TASK_ID" "error" "timeout exceeded"
else
  "$ROOT_DIR/scripts/assistant/emit_event.sh" "task_failed" "$TASK_ID" "error" "command failed with code $code"
fi
"$ROOT_DIR/scripts/assistant/heartbeat.sh" "blocked" "$TASK_ID" "true" "watchdog halt"
exit "$code"
