#!/usr/bin/env bash
set -euo pipefail

# Runs one OpenClaw turn on rb1 and applies a controlled Codex backstop
# when the local provider path returns transport-class failures.

usage() {
  cat <<'EOF'
Usage:
  scripts/openclaw_agent_safe_turn.sh --message "<text>" [options]

Options:
  --message <text>          Message to send (required)
  --host <alias>            SSH alias for rb1 (default: rb1-admin)
  --mode <gateway|local>    Use gateway or embedded local path (default: gateway)
  --agent <id>              Agent id (default: main)
  --thinking <level>        Thinking level (default: off)
  --fallback-model <id>     Backstop model (default: openai-codex/gpt-5.3-codex)
  --no-backstop             Disable automatic backstop and run single attempt only
  --no-precheck             Disable local-runtime precheck before first attempt
  --json                    Print wrapper JSON summary instead of plain response
  -h, --help                Show help

Examples:
  scripts/openclaw_agent_safe_turn.sh --message "Summarize status in one line."
  scripts/openclaw_agent_safe_turn.sh --mode local --message "Respond exactly: OK"
EOF
}

HOST_ALIAS="rb1-admin"
MODE="gateway"
AGENT_ID="main"
THINKING="off"
MESSAGE=""
FALLBACK_MODEL="openai-codex/gpt-5.3-codex"
ENABLE_BACKSTOP=1
ENABLE_PRECHECK=1
OUTPUT_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --message)
      MESSAGE="${2:-}"
      shift 2
      ;;
    --host)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --agent)
      AGENT_ID="${2:-}"
      shift 2
      ;;
    --thinking)
      THINKING="${2:-}"
      shift 2
      ;;
    --fallback-model)
      FALLBACK_MODEL="${2:-}"
      shift 2
      ;;
    --no-backstop)
      ENABLE_BACKSTOP=0
      shift
      ;;
    --no-precheck)
      ENABLE_PRECHECK=0
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

if [[ -z "$MESSAGE" ]]; then
  echo "--message is required" >&2
  usage >&2
  exit 2
fi

if [[ "$MODE" != "gateway" && "$MODE" != "local" ]]; then
  echo "--mode must be gateway or local" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"
mkdir -p "$ARTIFACTS_DIR"

TS_STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="${ARTIFACTS_DIR}/openclaw-safe-turn-${TS_STAMP}.log"
RUN_JSON="${ARTIFACTS_DIR}/openclaw-safe-turn-${TS_STAMP}.json"

ORIG_MODEL=""
RESTORE_MODEL=0
ATTEMPT1_JSON="$(mktemp)"
ATTEMPT2_JSON="$(mktemp)"
ATTEMPT1_RC=0
ATTEMPT2_RC=0
BACKSTOP_USED=0

log() {
  local msg
  msg="$(printf '%s %s' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*")"
  printf '%s\n' "$msg" | tee -a "$RUN_LOG" >&2
}

ssh_host() {
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$HOST_ALIAS" "$@"
}

cleanup() {
  local rc=$?
  if [[ "$RESTORE_MODEL" -eq 1 && -n "$ORIG_MODEL" ]]; then
    log "Cleanup: restoring model to ${ORIG_MODEL}"
    ssh_host "openclaw models set $(printf '%q' "$ORIG_MODEL") >/dev/null" >>"$RUN_LOG" 2>&1 || true
  fi
  rm -f "$ATTEMPT1_JSON" "$ATTEMPT2_JSON"
  exit "$rc"
}
trap cleanup EXIT

run_attempt() {
  local out_json="$1"
  local local_flag=""
  if [[ "$MODE" == "local" ]]; then
    local_flag="--local"
  fi
  if ssh_host "openclaw agent ${local_flag} --agent $(printf '%q' "$AGENT_ID") --thinking $(printf '%q' "$THINKING") --message $(printf '%q' "$MESSAGE") --json" >"$out_json" 2>>"$RUN_LOG"; then
    return 0
  fi
  return 1
}

extract_field() {
  local file="$1"
  local jq_expr="$2"
  local default="${3:-}"
  local value
  value="$(jq -r "(if has(\"result\") then .result else . end) | ${jq_expr}" "$file" 2>/dev/null || true)"
  if [[ -z "$value" ]]; then
    printf '%s' "$default"
  else
    printf '%s' "$value"
  fi
}

needs_backstop() {
  local rc="$1"
  local text="$2"
  local provider="$3"
  local total="$4"
  local text_lc
  text_lc="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"

  if [[ "$rc" -ne 0 ]]; then
    return 0
  fi
  if [[ "$text_lc" == "fetch failed" ]]; then
    return 0
  fi
  if [[ "$provider" == "ollama" && "${total:-0}" == "0" ]]; then
    if [[ "$text_lc" == *"fetch failed"* || "$text_lc" == *"connection"* || "$text_lc" == *"timeout"* || "$text_lc" == *"refused"* ]]; then
      return 0
    fi
  fi
  return 1
}

local_provider_unavailable() {
  # Fast path: only relevant when default model is local Ollama.
  if [[ "$ORIG_MODEL" != ollama/* ]]; then
    return 1
  fi

  if ! ssh_host "systemctl is-active --quiet ollama"; then
    return 0
  fi

  if ! ssh_host "curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null"; then
    return 0
  fi

  return 1
}

log "Host=${HOST_ALIAS} mode=${MODE} agent=${AGENT_ID}"
log "Artifacts: ${RUN_LOG} / ${RUN_JSON}"
ORIG_MODEL="$(ssh_host "openclaw models status --json | jq -r '.defaultModel'")"
log "Original model: ${ORIG_MODEL}"

if [[ "$ENABLE_BACKSTOP" -eq 1 && "$ENABLE_PRECHECK" -eq 1 ]] && local_provider_unavailable; then
  log "Precheck: local provider unavailable; skipping attempt 1 and using backstop"
  jq -n \
    --arg provider "ollama" \
    --arg model "$ORIG_MODEL" \
    --arg text "local_precheck_unavailable" \
    '{
      payloads: [{text: $text, mediaUrl: null}],
      meta: {
        durationMs: 0,
        agentMeta: {
          provider: $provider,
          model: $model,
          usage: { input: 0, output: 0, total: 0 }
        }
      }
    }' >"$ATTEMPT1_JSON"
  ATTEMPT1_RC=0
  BACKSTOP_USED=1
  if [[ "$ORIG_MODEL" != "$FALLBACK_MODEL" ]]; then
    log "Switching model to backstop ${FALLBACK_MODEL}"
    ssh_host "openclaw models set $(printf '%q' "$FALLBACK_MODEL") >/dev/null" >>"$RUN_LOG" 2>&1
    RESTORE_MODEL=1
  fi
  log "Attempt 2: backstop path"
  if run_attempt "$ATTEMPT2_JSON"; then
    ATTEMPT2_RC=0
  else
    ATTEMPT2_RC=$?
  fi
else
  log "Attempt 1: primary path"
  if run_attempt "$ATTEMPT1_JSON"; then
    ATTEMPT1_RC=0
  else
    ATTEMPT1_RC=$?
  fi
fi

ATTEMPT1_TEXT="$(extract_field "$ATTEMPT1_JSON" '.payloads[0].text // ""' "")"
ATTEMPT1_PROVIDER="$(extract_field "$ATTEMPT1_JSON" '.meta.agentMeta.provider // "unknown"' "unknown")"
ATTEMPT1_MODEL="$(extract_field "$ATTEMPT1_JSON" '.meta.agentMeta.model // "unknown"' "unknown")"
ATTEMPT1_TOTAL="$(extract_field "$ATTEMPT1_JSON" '.meta.agentMeta.usage.total // 0' "0")"

if [[ "$ENABLE_BACKSTOP" -eq 1 && "$BACKSTOP_USED" -eq 0 ]] && needs_backstop "$ATTEMPT1_RC" "$ATTEMPT1_TEXT" "$ATTEMPT1_PROVIDER" "$ATTEMPT1_TOTAL"; then
  BACKSTOP_USED=1
  log "Backstop condition met (rc=${ATTEMPT1_RC}, provider=${ATTEMPT1_PROVIDER}, text='${ATTEMPT1_TEXT}')"
  if [[ "$ORIG_MODEL" != "$FALLBACK_MODEL" ]]; then
    log "Switching model to backstop ${FALLBACK_MODEL}"
    ssh_host "openclaw models set $(printf '%q' "$FALLBACK_MODEL") >/dev/null" >>"$RUN_LOG" 2>&1
    RESTORE_MODEL=1
  fi
  log "Attempt 2: backstop path"
  if run_attempt "$ATTEMPT2_JSON"; then
    ATTEMPT2_RC=0
  else
    ATTEMPT2_RC=$?
  fi
fi

FINAL_FILE="$ATTEMPT1_JSON"
FINAL_RC="$ATTEMPT1_RC"
if [[ "$BACKSTOP_USED" -eq 1 ]]; then
  FINAL_FILE="$ATTEMPT2_JSON"
  FINAL_RC="$ATTEMPT2_RC"
fi

FINAL_TEXT="$(extract_field "$FINAL_FILE" '.payloads[0].text // ""' "")"
FINAL_PROVIDER="$(extract_field "$FINAL_FILE" '.meta.agentMeta.provider // "unknown"' "unknown")"
FINAL_MODEL="$(extract_field "$FINAL_FILE" '.meta.agentMeta.model // "unknown"' "unknown")"
FINAL_DURATION="$(extract_field "$FINAL_FILE" '.meta.durationMs // 0' "0")"
FINAL_TOTAL="$(extract_field "$FINAL_FILE" '.meta.agentMeta.usage.total // 0' "0")"

ATTEMPT1_DURATION="$(extract_field "$ATTEMPT1_JSON" '.meta.durationMs // 0' "0")"
ATTEMPT1_TEXT_SAFE="$(extract_field "$ATTEMPT1_JSON" '.payloads[0].text // ""' "")"
ATTEMPT2_PROVIDER="$(extract_field "$ATTEMPT2_JSON" '.meta.agentMeta.provider // "unknown"' "unknown")"
ATTEMPT2_MODEL="$(extract_field "$ATTEMPT2_JSON" '.meta.agentMeta.model // "unknown"' "unknown")"
ATTEMPT2_DURATION="$(extract_field "$ATTEMPT2_JSON" '.meta.durationMs // 0' "0")"
ATTEMPT2_TOTAL="$(extract_field "$ATTEMPT2_JSON" '.meta.agentMeta.usage.total // 0' "0")"
ATTEMPT2_TEXT_SAFE="$(extract_field "$ATTEMPT2_JSON" '.payloads[0].text // ""' "")"

jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg host "$HOST_ALIAS" \
  --arg mode "$MODE" \
  --arg agent "$AGENT_ID" \
  --argjson backstop_used "$BACKSTOP_USED" \
  --arg original_model "$ORIG_MODEL" \
  --arg fallback_model "$FALLBACK_MODEL" \
  --argjson attempt1_rc "$ATTEMPT1_RC" \
  --argjson attempt2_rc "$ATTEMPT2_RC" \
  --argjson final_rc "$FINAL_RC" \
  --arg attempt1_provider "$ATTEMPT1_PROVIDER" \
  --arg attempt1_model "$ATTEMPT1_MODEL" \
  --argjson attempt1_duration "$ATTEMPT1_DURATION" \
  --argjson attempt1_total "$ATTEMPT1_TOTAL" \
  --arg attempt1_text "$ATTEMPT1_TEXT_SAFE" \
  --arg attempt2_provider "$ATTEMPT2_PROVIDER" \
  --arg attempt2_model "$ATTEMPT2_MODEL" \
  --argjson attempt2_duration "$ATTEMPT2_DURATION" \
  --argjson attempt2_total "$ATTEMPT2_TOTAL" \
  --arg attempt2_text "$ATTEMPT2_TEXT_SAFE" \
  --arg final_provider "$FINAL_PROVIDER" \
  --arg final_model "$FINAL_MODEL" \
  --argjson final_duration "$FINAL_DURATION" \
  --argjson final_total "$FINAL_TOTAL" \
  --arg final_text "$FINAL_TEXT" \
  '{
    timestampUtc: $ts,
    host: $host,
    mode: $mode,
    agent: $agent,
    backstopUsed: $backstop_used,
    originalModel: $original_model,
    fallbackModel: $fallback_model,
    attempt1: {
      provider: $attempt1_provider,
      model: $attempt1_model,
      durationMs: $attempt1_duration,
      totalTokens: $attempt1_total,
      text: $attempt1_text,
      rc: $attempt1_rc
    },
    attempt2: {
      provider: $attempt2_provider,
      model: $attempt2_model,
      durationMs: $attempt2_duration,
      totalTokens: $attempt2_total,
      text: $attempt2_text,
      rc: $attempt2_rc
    },
    final: {
      provider: $final_provider,
      model: $final_model,
      durationMs: $final_duration,
      totalTokens: $final_total,
      text: $final_text,
      rc: $final_rc
    }
  }' >"$RUN_JSON"

if [[ "$OUTPUT_JSON" -eq 1 ]]; then
  cat "$RUN_JSON"
else
  printf '%s\n' "$FINAL_TEXT"
  log "Final provider=${FINAL_PROVIDER} model=${FINAL_MODEL} backstop_used=${BACKSTOP_USED} rc=${FINAL_RC} tokens=${FINAL_TOTAL} duration_ms=${FINAL_DURATION}"
  log "Run summary JSON: ${RUN_JSON}"
fi

if [[ "$FINAL_RC" -ne 0 ]]; then
  exit "$FINAL_RC"
fi
