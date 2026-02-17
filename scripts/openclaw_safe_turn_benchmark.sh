#!/usr/bin/env bash
set -euo pipefail

# Runs a short safe-turn benchmark set and writes resumable artifacts.

usage() {
  cat <<'EOF'
Usage:
  scripts/openclaw_safe_turn_benchmark.sh [options]

Options:
  --host <alias>             SSH alias for rb1 (default: rb1-admin)
  --mode <gateway|local>     Wrapper mode (default: gateway)
  --agent <id>               Agent id (default: main)
  --thinking <level>         Thinking level (default: off)
  --profile <control|real>   Prompt profile (default: control)
  --skip-outage              Skip forced-outage scenario
  -h, --help                 Show help

Outputs:
  - notes/openclaw-safe-turn-benchmark-<timestamp>.md
  - notes/openclaw-artifacts/openclaw-safe-turn-benchmark-<timestamp>.jsonl
  - notes/openclaw-artifacts/openclaw-safe-turn-benchmark-<timestamp>.log
EOF
}

HOST_ALIAS="rb1-admin"
MODE="gateway"
AGENT_ID="main"
THINKING="off"
INCLUDE_OUTAGE=1
PROFILE="control"

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
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --skip-outage)
      INCLUDE_OUTAGE=0
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

if [[ "$MODE" != "gateway" && "$MODE" != "local" ]]; then
  echo "--mode must be gateway or local" >&2
  exit 2
fi
if [[ "$PROFILE" != "control" && "$PROFILE" != "real" ]]; then
  echo "--profile must be control or real" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"
mkdir -p "$ARTIFACTS_DIR"

TS_STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_MD="${ROOT_DIR}/notes/openclaw-safe-turn-benchmark-${TS_STAMP}.md"
OUT_JSONL="${ARTIFACTS_DIR}/openclaw-safe-turn-benchmark-${TS_STAMP}.jsonl"
RUN_LOG="${ARTIFACTS_DIR}/openclaw-safe-turn-benchmark-${TS_STAMP}.log"

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
  if [[ "$INCLUDE_OUTAGE" -eq 1 ]]; then
    ssh_host "sudo -n systemctl start ollama" >>"$RUN_LOG" 2>&1 || true
  fi
  exit "$rc"
}
trap cleanup EXIT

cat >"$OUT_MD" <<EOF
# OpenClaw Safe-Turn Benchmark

timestamp_local: $(date '+%Y-%m-%d %H:%M:%S %Z')  
host_alias: ${HOST_ALIAS}  
mode: ${MODE}  
agent: ${AGENT_ID}  
thinking: ${THINKING}  
profile: ${PROFILE}

| case | forced_outage | backstop_used | final_provider | final_model | final_rc | tokens | duration_ms | wrapper_elapsed_ms | response_excerpt |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
EOF

run_case() {
  local case_id="$1"
  local prompt="$2"
  local forced_outage="$3"
  local ts_utc tmp_json row_json backstop provider model rc tokens duration text excerpt
  local wrapper_start_ms wrapper_end_ms wrapper_elapsed_ms

  ts_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp_json="$(mktemp)"
  wrapper_start_ms="$(date +%s%3N)"

  if [[ "$forced_outage" -eq 1 ]]; then
    log "Case ${case_id}: forcing ollama outage"
    ssh_host "sudo -n systemctl stop ollama" >>"$RUN_LOG" 2>&1
  fi

  log "Case ${case_id}: running safe turn"
  if "${ROOT_DIR}/scripts/openclaw_agent_safe_turn.sh" \
      --host "$HOST_ALIAS" \
      --mode "$MODE" \
      --agent "$AGENT_ID" \
      --thinking "$THINKING" \
      --message "$prompt" \
      --json >"$tmp_json"; then
    :
  else
    log "Case ${case_id}: wrapper command returned non-zero"
  fi
  wrapper_end_ms="$(date +%s%3N)"
  wrapper_elapsed_ms="$((wrapper_end_ms - wrapper_start_ms))"

  if [[ "$forced_outage" -eq 1 ]]; then
    log "Case ${case_id}: restoring ollama"
    ssh_host "sudo -n systemctl start ollama" >>"$RUN_LOG" 2>&1 || true
  fi

  row_json="$(jq -c \
    --arg case "$case_id" \
    --arg prompt "$prompt" \
    --arg ts "$ts_utc" \
    --argjson forcedOutage "$forced_outage" \
    --argjson wrapperElapsedMs "$wrapper_elapsed_ms" \
    '. + {case: $case, prompt: $prompt, timestampUtc: $ts, forcedOutage: $forcedOutage, wrapperElapsedMs: $wrapperElapsedMs}' \
    "$tmp_json" 2>/dev/null || echo '{}')"

  printf '%s\n' "$row_json" >>"$OUT_JSONL"

  backstop="$(jq -r '.backstopUsed // 0' "$tmp_json" 2>/dev/null || echo 0)"
  provider="$(jq -r '.final.provider // "unknown"' "$tmp_json" 2>/dev/null || echo unknown)"
  model="$(jq -r '.final.model // "unknown"' "$tmp_json" 2>/dev/null || echo unknown)"
  rc="$(jq -r '.final.rc // 1' "$tmp_json" 2>/dev/null || echo 1)"
  tokens="$(jq -r '.final.totalTokens // 0' "$tmp_json" 2>/dev/null || echo 0)"
  duration="$(jq -r '.final.durationMs // 0' "$tmp_json" 2>/dev/null || echo 0)"
  text="$(jq -r '.final.text // ""' "$tmp_json" 2>/dev/null || true)"
  excerpt="$(printf '%s' "$text" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/|/\\|/g' | cut -c1-90)"

  printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$case_id" "$forced_outage" "$backstop" "$provider" "$model" "$rc" "$tokens" "$duration" "$wrapper_elapsed_ms" "$excerpt" \
    >>"$OUT_MD"

  rm -f "$tmp_json"
}

run_profile_cases() {
  if [[ "$PROFILE" == "control" ]]; then
    run_case "bench_01_marker" "Respond with exactly: BENCH_OK_01" 0
    run_case "bench_02_math" "Compute 19*21. Respond with digits only." 0
    run_case "bench_03_extract" "Given JSON {\"host\":\"rb1\",\"ip\":\"192.168.5.107\"}, respond with only the ip value." 0
    run_case "bench_04_wol" "In one short sentence, define Wake-on-LAN." 0
    run_case "bench_05_cmd" "Output one bash command only: ping host 172.31.99.2 twice with timeout 1 second." 0
    run_case "bench_06_status" "Respond with exactly: BENCH_OK_06" 0
    if [[ "$INCLUDE_OUTAGE" -eq 1 ]]; then
      run_case "bench_07_forced_outage" "Respond with exactly: BENCH_OK_07" 1
    fi
    return
  fi

  # Real workload profile: homelab/operator-oriented prompts.
  run_case "real_01_risk_summary" "In one sentence, summarize the highest current operational risk on rb1/rb2 based on fallback and eGPU facts." 0
  run_case "real_02_checklist" "Provide a 3-item checklist to validate fallback VLAN99 after reboot. Keep each item under 10 words." 0
  run_case "real_03_command" "Output one bash command only to verify ollama service is active." 0
  run_case "real_04_transform" "Convert this YAML to compact JSON only: host: rb1-fedora, status: active, ip: 192.168.5.107" 0
  run_case "real_05_changelog" "Write one concise changelog line for enabling Wake-on-LAN on rb1-fedora." 0
  run_case "real_06_recovery" "Give one rollback step if eGPU disconnect causes instability. One sentence only." 0
  if [[ "$INCLUDE_OUTAGE" -eq 1 ]]; then
    run_case "real_07_forced_outage" "Respond with exactly: REAL_OUTAGE_RECOVERED" 1
  fi
}

log "Preflight checks"
ssh_host "openclaw --version; openclaw models status --json | jq -r '.defaultModel, (.fallbacks|join(\",\"))'; systemctl is-active ollama" >>"$RUN_LOG" 2>&1

run_profile_cases

{
  echo ""
  echo "## Summary"
  jq -s -r '
    (map(select(.final.provider=="openai-codex"))) as $cloud |
    "count=" + (length|tostring),
    "success_count=" + (map(select(.final.rc==0))|length|tostring),
    "backstop_count=" + (map(select(.backstopUsed==1))|length|tostring),
    "final_provider_ollama=" + (map(select(.final.provider=="ollama"))|length|tostring),
    "final_provider_openai_codex=" + (map(select(.final.provider=="openai-codex"))|length|tostring),
    "avg_tokens=" + ((map(.final.totalTokens // 0)|add/length|floor)|tostring),
    "avg_duration_ms=" + ((map(.final.durationMs // 0)|add/length|floor)|tostring),
    "avg_wrapper_elapsed_ms=" + ((map(.wrapperElapsedMs // 0)|add/length|floor)|tostring),
    "cloud_final_tokens_total=" + ((($cloud|map(.final.totalTokens // 0)|add) // 0)|tostring),
    "cloud_final_tokens_avg=" + ((if ($cloud|length) == 0 then 0 else ((($cloud|map(.final.totalTokens // 0)|add) // 0) / ($cloud|length) | floor) end)|tostring),
    "forced_outage_wrapper_elapsed_ms=" + ((map(select(.forcedOutage==1))|.[0].wrapperElapsedMs|tostring))
  ' "$OUT_JSONL"
  echo ""
  echo "Artifacts:"
  echo "- JSONL: $(realpath --relative-to="$ROOT_DIR" "$OUT_JSONL")"
  echo "- Log: $(realpath --relative-to="$ROOT_DIR" "$RUN_LOG")"
} >>"$OUT_MD"

log "Benchmark complete"
log "Markdown: ${OUT_MD}"
log "JSONL: ${OUT_JSONL}"
log "Log: ${RUN_LOG}"
