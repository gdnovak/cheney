#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVENTS_FILE="$ROOT_DIR/coordination/state/events.log"

EVENT_TYPE="${1:-}"
TASK_ID="${2:--}"
SEVERITY="${3:-info}"
MESSAGE="${4:-}"

if [[ -z "$EVENT_TYPE" || -z "$MESSAGE" ]]; then
  echo "usage: $0 <event_type> [task_id|-] [severity] <message>" >&2
  exit 1
fi

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOST="$(hostname)"
AGENT_ID="${AGENT_ID:-vm-codex-rb1}"

printf '%s|%s|%s|%s|%s|%s|%s\n' \
  "$TS" "$HOST" "$AGENT_ID" "$EVENT_TYPE" "$TASK_ID" "$SEVERITY" "$MESSAGE" \
  >> "$EVENTS_FILE"
