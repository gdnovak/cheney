#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"

if [[ -z "$TASK_FILE" ]]; then
  echo "usage: $0 <task-file-path>" >&2
  exit 1
fi

if [[ ! -f "$TASK_FILE" ]]; then
  echo "task file not found: $TASK_FILE" >&2
  exit 1
fi

TASK_ID="$(awk -F': ' '/^id:/{print $2; exit}' "$TASK_FILE")"
STATUS="$(awk -F': ' '/^status:/{print $2; exit}' "$TASK_FILE")"

if [[ "$STATUS" != "queued" ]]; then
  echo "cannot claim task status=$STATUS id=$TASK_ID" >&2
  exit 1
fi

LOCK_DIR="$ROOT_DIR/coordination/claims/${TASK_ID}.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "task already claimed id=$TASK_ID" >&2
  exit 1
fi

cleanup() { rmdir "$LOCK_DIR" 2>/dev/null || true; }
trap cleanup EXIT

TMP="$(mktemp)"
awk '
  /^status:/ { print "status: claimed"; next }
  { print }
' "$TASK_FILE" > "$TMP"
mv "$TMP" "$TASK_FILE"

"$ROOT_DIR/scripts/assistant/emit_event.sh" "task_claimed" "$TASK_ID" "info" "task claimed"
echo "claimed $TASK_ID"
