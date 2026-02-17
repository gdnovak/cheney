#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/openclaw_overnight_probe.sh [options]

Options:
  --host <alias|local>          Target host mode for safe-turn wrapper (default: local)
  --mode <gateway|local>        OpenClaw path mode passed to wrapper (default: gateway)
  --agent <id>                  Agent id (default: main)
  --thinking <level>            Thinking level (default: off)
  --interval-sec <seconds>      Interval between cycles (default: 1800)
  --cycles <n>                  Number of cycles; 0 means run until stopped (default: 0)
  --wrapper-timeout-sec <sec>   Timeout per safe-turn wrapper call (default: 240)
  --output-prefix <prefix>      Artifact prefix (default: overnight-probe)
  -h, --help                    Show help

Outputs:
  - notes/openclaw-artifacts/<prefix>-<timestamp>.jsonl
  - notes/openclaw-artifacts/<prefix>-<timestamp>.log
  - notes/openclaw-artifacts/<prefix>-<timestamp>.pid
USAGE
}

HOST_ALIAS="local"
MODE="gateway"
AGENT_ID="main"
THINKING="off"
INTERVAL_SEC=1800
CYCLES=0
WRAPPER_TIMEOUT_SEC=240
OUTPUT_PREFIX="overnight-probe"

while [[ $# -gt 0 ]]; do
  case "$1" in
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
    --interval-sec)
      INTERVAL_SEC="${2:-}"
      shift 2
      ;;
    --cycles)
      CYCLES="${2:-}"
      shift 2
      ;;
    --wrapper-timeout-sec)
      WRAPPER_TIMEOUT_SEC="${2:-}"
      shift 2
      ;;
    --output-prefix)
      OUTPUT_PREFIX="${2:-}"
      shift 2
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

if [[ "$MODE" != "gateway" && "$MODE" != "local" ]]; then
  echo "--mode must be gateway or local" >&2
  exit 2
fi
if ! [[ "$INTERVAL_SEC" =~ ^[0-9]+$ ]] || [[ "$INTERVAL_SEC" -lt 1 ]]; then
  echo "--interval-sec must be a positive integer" >&2
  exit 2
fi
if ! [[ "$CYCLES" =~ ^[0-9]+$ ]]; then
  echo "--cycles must be a non-negative integer" >&2
  exit 2
fi
if ! [[ "$WRAPPER_TIMEOUT_SEC" =~ ^[0-9]+$ ]] || [[ "$WRAPPER_TIMEOUT_SEC" -lt 1 ]]; then
  echo "--wrapper-timeout-sec must be a positive integer" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"
mkdir -p "$ARTIFACTS_DIR"

TS_STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_JSONL="${ARTIFACTS_DIR}/${OUTPUT_PREFIX}-${TS_STAMP}.jsonl"
RUN_LOG="${ARTIFACTS_DIR}/${OUTPUT_PREFIX}-${TS_STAMP}.log"
PID_FILE="${ARTIFACTS_DIR}/${OUTPUT_PREFIX}-${TS_STAMP}.pid"
LATEST_PID_FILE="${ARTIFACTS_DIR}/${OUTPUT_PREFIX}.pid"
LATEST_JSONL_POINTER="${ARTIFACTS_DIR}/${OUTPUT_PREFIX}.latest_jsonl"

log() {
  local msg
  msg="$(printf '%s %s' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*")"
  printf '%s\n' "$msg" | tee -a "$RUN_LOG" >&2
}

run_wrapper() {
  local out_json="$1"
  if command -v timeout >/dev/null 2>&1; then
    timeout "${WRAPPER_TIMEOUT_SEC}s" "${ROOT_DIR}/scripts/openclaw_agent_safe_turn.sh" \
      --host "$HOST_ALIAS" \
      --mode "$MODE" \
      --agent "$AGENT_ID" \
      --thinking "$THINKING" \
      --message "$2" \
      --json >"$out_json"
    return $?
  fi

  "${ROOT_DIR}/scripts/openclaw_agent_safe_turn.sh" \
    --host "$HOST_ALIAS" \
    --mode "$MODE" \
    --agent "$AGENT_ID" \
    --thinking "$THINKING" \
    --message "$2" \
    --json >"$out_json"
}

cleanup() {
  local rc=$?
  log "Exiting overnight probe (rc=${rc})"
  exit "$rc"
}
trap cleanup EXIT INT TERM

echo "$$" >"$PID_FILE"
echo "$$" >"$LATEST_PID_FILE"
printf '%s\n' "$OUT_JSONL" >"$LATEST_JSONL_POINTER"

log "Starting overnight probe"
log "Artifacts: jsonl=${OUT_JSONL} log=${RUN_LOG} pid=${PID_FILE}"
log "Settings: host=${HOST_ALIAS} mode=${MODE} agent=${AGENT_ID} thinking=${THINKING} interval_sec=${INTERVAL_SEC} cycles=${CYCLES} timeout_sec=${WRAPPER_TIMEOUT_SEC}"

cycle=0
while :; do
  cycle=$((cycle + 1))
  ts_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  marker="PROBE_$(date -u +%Y%m%dT%H%M%SZ)"
  prompt="Write a 3-line haiku about system uptime. End with token: ${marker}"

  tmp_json="$(mktemp)"
  wrapper_start_ms="$(date +%s%3N)"
  if run_wrapper "$tmp_json" "$prompt" >>"$RUN_LOG" 2>&1; then
    wrapper_rc=0
  else
    wrapper_rc=$?
  fi
  wrapper_end_ms="$(date +%s%3N)"
  wrapper_elapsed_ms="$((wrapper_end_ms - wrapper_start_ms))"

  backstop="$(jq -r '.backstopUsed // 0' "$tmp_json" 2>/dev/null || echo 0)"
  provider="$(jq -r '.final.provider // "unknown"' "$tmp_json" 2>/dev/null || echo unknown)"
  model="$(jq -r '.final.model // "unknown"' "$tmp_json" 2>/dev/null || echo unknown)"
  final_rc="$(jq -r '.final.rc // -1' "$tmp_json" 2>/dev/null || echo -1)"
  tokens="$(jq -r '.final.totalTokens // 0' "$tmp_json" 2>/dev/null || echo 0)"
  duration_ms="$(jq -r '.final.durationMs // 0' "$tmp_json" 2>/dev/null || echo 0)"
  text="$(jq -r '.final.text // ""' "$tmp_json" 2>/dev/null || true)"

  [[ "$backstop" =~ ^[0-9]+$ ]] || backstop=0
  [[ "$final_rc" =~ ^-?[0-9]+$ ]] || final_rc=-1
  [[ "$tokens" =~ ^-?[0-9]+$ ]] || tokens=0
  [[ "$duration_ms" =~ ^-?[0-9]+$ ]] || duration_ms=0

  if [[ "$final_rc" -eq -1 ]]; then
    final_rc="$wrapper_rc"
  fi

  ok=0
  if [[ "$final_rc" -eq 0 ]]; then
    ok=1
  fi

  error=""
  if [[ "$wrapper_rc" -ne 0 ]]; then
    if [[ "$wrapper_rc" -eq 124 ]]; then
      error="wrapper_timeout"
    else
      error="wrapper_rc_${wrapper_rc}"
    fi
  elif [[ "$final_rc" -ne 0 ]]; then
    error="final_rc_${final_rc}"
  fi

  excerpt="$(printf '%s' "$text" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-120)"

  row_json="$(jq -n \
    --arg cycle "$cycle" \
    --arg ts "$ts_utc" \
    --arg marker "$marker" \
    --argjson wrapperElapsedMs "$wrapper_elapsed_ms" \
    --argjson ok "$ok" \
    --argjson backstopUsed "$backstop" \
    --arg provider "$provider" \
    --arg model "$model" \
    --argjson tokens "$tokens" \
    --argjson durationMs "$duration_ms" \
    --argjson rc "$final_rc" \
    --arg excerpt "$excerpt" \
    --arg error "$error" \
    '{
      cycle: ($cycle|tonumber),
      timestampUtc: $ts,
      marker: $marker,
      wrapperElapsedMs: $wrapperElapsedMs,
      ok: $ok,
      backstopUsed: $backstopUsed,
      provider: $provider,
      model: $model,
      tokens: $tokens,
      durationMs: $durationMs,
      rc: $rc,
      excerpt: $excerpt,
      error: (if $error == "" then null else $error end)
    }')"

  printf '%s\n' "$row_json" >>"$OUT_JSONL"
  log "cycle=${cycle} ok=${ok} backstop=${backstop} provider=${provider} model=${model} rc=${final_rc} tokens=${tokens} duration_ms=${duration_ms} wrapper_elapsed_ms=${wrapper_elapsed_ms}"

  rm -f "$tmp_json"

  if [[ "$CYCLES" -gt 0 && "$cycle" -ge "$CYCLES" ]]; then
    log "Completed requested cycles (${CYCLES})"
    break
  fi

  sleep "$INTERVAL_SEC"
done
