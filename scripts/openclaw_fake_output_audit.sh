#!/usr/bin/env bash
set -euo pipefail

# Audits OpenClaw session history for side-effect claims that lack verification.
# This is a forensic helper; it marks suspicious claims and can append them to
# the fake-output incident log.

usage() {
  cat <<'USAGE'
Usage:
  scripts/openclaw_fake_output_audit.sh [options]

Options:
  --session-file <path>         Session JSONL file on host (default: latest in ~/.openclaw/agents/main/sessions)
  --host <alias|local>          SSH alias or local/self (default: rb1-admin)
  --append-log <path>           Append findings to incident JSONL log
                                (default: notes/openclaw-artifacts/openclaw-fake-output-incidents.jsonl)
  --no-append                   Do not append findings; print only
  --json                        Print JSON array instead of table
  -h, --help                    Show help
USAGE
}

SESSION_FILE=""
HOST_ALIAS="rb1-admin"
INCIDENT_LOG=""
APPEND_LOG=1
OUTPUT_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-file)
      SESSION_FILE="${2:-}"
      shift 2
      ;;
    --host)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --append-log)
      INCIDENT_LOG="${2:-}"
      shift 2
      ;;
    --no-append)
      APPEND_LOG=0
      shift
      ;;
    --json)
      OUTPUT_JSON=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"
mkdir -p "$ARTIFACTS_DIR"

if [[ -z "$INCIDENT_LOG" ]]; then
  INCIDENT_LOG="${ARTIFACTS_DIR}/openclaw-fake-output-incidents.jsonl"
fi
mkdir -p "$(dirname "$INCIDENT_LOG")"

ssh_host() {
  if [[ "$HOST_ALIAS" == "local" || "$HOST_ALIAS" == "localhost" || "$HOST_ALIAS" == "self" ]]; then
    bash -lc "$*"
    return $?
  fi
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$HOST_ALIAS" "$@"
}

if [[ -z "$SESSION_FILE" ]]; then
  SESSION_FILE="$(ssh_host "ls -1t ~/.openclaw/agents/main/sessions/*.jsonl 2>/dev/null | head -n1")"
fi

if [[ -z "$SESSION_FILE" ]]; then
  echo "No session files found" >&2
  exit 1
fi

if ! ssh_host "test -f $(printf '%q' "$SESSION_FILE")"; then
  echo "Session file not found: $SESSION_FILE" >&2
  exit 1
fi

RAW_JSON="$(ssh_host "cat $(printf '%q' "$SESSION_FILE")" | jq -cs '
  [
    .[]
    | select(.type == "message")
    | . as $row
    | ($row.message.content // [])
    | map(select(.type == "text") | .text)
    | join("\n") as $text
    | select(($row.message.role // "") == "assistant")
    | {
        timestamp: ($row.timestamp // null),
        provider: ($row.message.provider // "unknown"),
        model: ($row.message.model // "unknown"),
        text: $text
      }
    | . + {
        claimWrite: (.text | test("(?i)\\bi (have )?(saved|created|wrote|written)\\b|\\bfile (has been )?saved\\b")),
        claimRun: (.text | test("(?i)\\bi (have )?(ran|run|executed)\\b|\\bcommand (was )?(run|executed)\\b"))
      }
    | select(.claimWrite or .claimRun)
    | . + {
        reason: (
          (if .claimWrite then ["claimed_write_without_verification"] else [] end)
          + (if .claimRun then ["claimed_run_without_verification"] else [] end)
        ),
        excerpt: (.text | gsub("\\n"; " ") | .[0:240])
      }
  ]
')"

if [[ "$OUTPUT_JSON" -eq 1 ]]; then
  printf '%s\n' "$RAW_JSON"
else
  printf 'session_file=%s\n' "$SESSION_FILE"
  printf 'findings=%s\n' "$(jq 'length' <<<"$RAW_JSON")"
  jq -r '.[] | "\(.timestamp // "n/a") | \(.provider)/\(.model) | \(.reason | join(",")) | \(.excerpt)"' <<<"$RAW_JSON"
fi

if [[ "$APPEND_LOG" -eq 1 ]]; then
  jq -c --arg sessionFile "$SESSION_FILE" '
    .[]
    | {
        timestampUtc: (.timestamp // null),
        host: "'"$HOST_ALIAS"'",
        source: "session_audit",
        sourceSessionFile: $sessionFile,
        provider: .provider,
        model: .model,
        reason: (.reason | join(",")),
        evidenceTextExcerpt: .excerpt
      }
  ' <<<"$RAW_JSON" >>"$INCIDENT_LOG"
fi

