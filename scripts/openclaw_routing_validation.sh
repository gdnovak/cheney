#!/usr/bin/env bash
set -euo pipefail

# Runs OpenClaw routing acceptance checks against rb1 and writes resumable
# matrix + artifacts in notes/openclaw-artifacts.

usage() {
  cat <<'EOF'
Usage:
  scripts/openclaw_routing_validation.sh [options]

Options:
  --host <alias>          SSH alias for rb1 (default: rb1-admin)
  --out <path>            Matrix markdown path
                          (default: notes/openclaw-routing-validation-YYYYMMDD.md)
  --artifacts-dir <dir>   Artifact directory
                          (default: notes/openclaw-artifacts)
  -h, --help              Show help

What it does:
1. Runs 10 routine prompts (local-first + one gateway check)
2. Temporarily switches primary model to qwen2.5-coder for coder-path test
3. Stops Ollama once to force fallback to openai-codex, then restores service

Notes:
- Requires passwordless SSH to host alias and non-interactive sudo on host.
- Requires jq locally and on remote host.
EOF
}

HOST_ALIAS="rb1-admin"
TODAY="$(date +%Y%m%d)"
OUT_FILE="notes/openclaw-routing-validation-${TODAY}.md"
ARTIFACTS_DIR="notes/openclaw-artifacts"

LOCAL_MODEL="ollama/qwen2.5:7b"
CODER_MODEL="ollama/qwen2.5-coder:7b"
FALLBACK_MODEL="openai-codex/gpt-5.3-codex"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    --artifacts-dir)
      ARTIFACTS_DIR="${2:-}"
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

mkdir -p "$(dirname "$OUT_FILE")" "$ARTIFACTS_DIR"

TS_STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="${ARTIFACTS_DIR}/openclaw-routing-validation-${TS_STAMP}.log"
RUN_JSONL="${ARTIFACTS_DIR}/openclaw-routing-validation-${TS_STAMP}.jsonl"

ORIG_MODEL=""
OLLAMA_STOPPED=0

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
  if [[ "$OLLAMA_STOPPED" -eq 1 ]]; then
    log "Cleanup: restarting ollama"
    ssh_host "sudo -n systemctl start ollama" >>"$RUN_LOG" 2>&1 || true
  fi
  if [[ -n "$ORIG_MODEL" ]]; then
    log "Cleanup: restoring primary model to ${ORIG_MODEL}"
    ssh_host "openclaw models set $(printf '%q' "$ORIG_MODEL") >/dev/null" >>"$RUN_LOG" 2>&1 || true
  fi
  exit "$rc"
}
trap cleanup EXIT

append_row() {
  local ts_utc="$1"
  local case_id="$2"
  local mode="$3"
  local provider="$4"
  local model="$5"
  local duration="$6"
  local input_tokens="$7"
  local output_tokens="$8"
  local total_tokens="$9"
  local result="${10}"
  local notes="${11}"
  local response="${12}"

  printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$ts_utc" "$case_id" "$mode" "$provider" "$model" "$duration" \
    "$input_tokens" "$output_tokens" "$total_tokens" "$result" "$notes" "$response" \
    >>"$OUT_FILE"
}

if [[ ! -f "$OUT_FILE" ]]; then
  cat >"$OUT_FILE" <<'EOF'
| timestamp_utc | case | mode | provider | model | duration_ms | input_tokens | output_tokens | total_tokens | result | notes | response_excerpt |
|---|---|---|---|---|---:|---:|---:|---:|---|---|---|
EOF
fi

evaluate_case() {
  local case_id="$1"
  local text="$2"
  local provider="$3"
  local model="$4"
  local note=""

  case "$case_id" in
    route_01_marker)
      [[ "$text" == "ROUTE_OK_01" ]] || note="expected ROUTE_OK_01"
      ;;
    route_02_math)
      [[ "$text" == "391" ]] || note="expected 391"
      ;;
    route_03_json_extract)
      [[ "$text" == "192.168.5.107" ]] || note="expected 192.168.5.107"
      ;;
    route_04_sort_csv)
      [[ "$text" == "mba,rb1,rb2" ]] || note="expected mba,rb1,rb2"
      ;;
    route_05_transform)
      [[ "$text" == "aa:bb:cc:dd" ]] || note="expected aa:bb:cc:dd"
      ;;
    route_06_wol_short)
      [[ -n "$text" ]] || note="empty response"
      if [[ -z "$note" ]]; then
        local words
        words="$(awk '{print NF}' <<<"$text")"
        [[ "$words" -le 8 ]] || note="word_count>${words}"
      fi
      ;;
    route_07_ping_cmd)
      [[ "$text" == *"ping"* && "$text" == *"172.31.99.2"* ]] || note="missing ping/ip"
      ;;
    route_08_yaml)
      [[ "$text" == *"host: rb1-fedora"* && "$text" == *"status: ok"* ]] || note="missing yaml keys"
      ;;
    route_09_python)
      [[ "$text" == *"def add("* ]] || note="missing def add"
      ;;
    route_10_gateway_marker)
      [[ "$text" == "ROUTE_OK_10" ]] || note="expected ROUTE_OK_10"
      [[ "$provider" == "ollama" ]] || note="${note:+$note; }provider!=ollama"
      ;;
    coder_path_check)
      [[ "$text" == *"def add("* ]] || note="missing def add"
      [[ "$model" == "qwen2.5-coder:7b" ]] || note="${note:+$note; }model!=qwen2.5-coder:7b"
      ;;
    fallback_forced_check)
      [[ "$text" == "FALLBACK_PATH_OK" ]] || note="expected FALLBACK_PATH_OK"
      [[ "$provider" == "openai-codex" ]] || note="${note:+$note; }provider!=openai-codex"
      ;;
    *)
      [[ -n "$text" ]] || note="empty response"
      ;;
  esac

  if [[ -z "$note" ]]; then
    printf 'PASS|ok\n'
  else
    printf 'FAIL|%s\n' "$note"
  fi
}

run_case() {
  local case_id="$1"
  local mode="$2"
  local prompt="$3"

  local ts_utc session_id cmd tmp_json provider model duration input_tokens output_tokens total_tokens text
  local status result notes response_excerpt
  ts_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  session_id="routing-${case_id}-${TS_STAMP}-$RANDOM"
  tmp_json="$(mktemp)"

  if [[ "$mode" == "local" ]]; then
    cmd="openclaw agent --local --agent main --session-id $(printf '%q' "$session_id") --thinking off --message $(printf '%q' "$prompt") --json"
  else
    cmd="openclaw agent --agent main --session-id $(printf '%q' "$session_id") --thinking off --message $(printf '%q' "$prompt") --json"
  fi

  log "Running ${case_id} (${mode})"
  if ssh_host "$cmd" >"$tmp_json" 2>>"$RUN_LOG"; then
    provider="$(jq -r '(if has("result") then .result else . end) | .meta.agentMeta.provider // "unknown"' "$tmp_json")"
    model="$(jq -r '(if has("result") then .result else . end) | .meta.agentMeta.model // "unknown"' "$tmp_json")"
    duration="$(jq -r '(if has("result") then .result else . end) | .meta.durationMs // 0' "$tmp_json")"
    input_tokens="$(jq -r '(if has("result") then .result else . end) | .meta.agentMeta.usage.input // 0' "$tmp_json")"
    output_tokens="$(jq -r '(if has("result") then .result else . end) | .meta.agentMeta.usage.output // 0' "$tmp_json")"
    total_tokens="$(jq -r '(if has("result") then .result else . end) | .meta.agentMeta.usage.total // 0' "$tmp_json")"
    text="$(jq -r '(if has("result") then .result else . end) | .payloads[0].text // ""' "$tmp_json")"
    IFS='|' read -r result notes < <(evaluate_case "$case_id" "$text" "$provider" "$model")
  else
    provider="error"
    model="error"
    duration="0"
    input_tokens="0"
    output_tokens="0"
    total_tokens="0"
    text=""
    result="FAIL"
    notes="command_failed"
  fi

  response_excerpt="$(printf '%s' "$text" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/|/\\|/g' | cut -c1-120)"
  append_row "$ts_utc" "$case_id" "$mode" "$provider" "$model" "$duration" \
    "$input_tokens" "$output_tokens" "$total_tokens" "$result" "$notes" "$response_excerpt"

  jq -c --arg case "$case_id" --arg mode "$mode" --arg result "$result" --arg notes "$notes" \
    '{
      case: $case,
      mode: $mode,
      result: $result,
      notes: $notes,
      provider: ((if has("result") then .result else . end) | .meta.agentMeta.provider // "unknown"),
      model: ((if has("result") then .result else . end) | .meta.agentMeta.model // "unknown"),
      durationMs: ((if has("result") then .result else . end) | .meta.durationMs // 0),
      usage: ((if has("result") then .result else . end) | .meta.agentMeta.usage // {}),
      response: ((if has("result") then .result else . end) | .payloads[0].text // "")
    }' "$tmp_json" >>"$RUN_JSONL" 2>/dev/null || true

  rm -f "$tmp_json"
}

require_cmds() {
  command -v jq >/dev/null 2>&1 || { echo "jq is required locally" >&2; exit 1; }
  ssh_host "command -v openclaw >/dev/null && command -v jq >/dev/null" >/dev/null
}

preflight() {
  log "Host=${HOST_ALIAS}"
  log "Artifacts: ${RUN_LOG} / ${RUN_JSONL}"
  ssh_host "hostnamectl --static; whoami" >>"$RUN_LOG" 2>&1
  ssh_host "openclaw --version" >>"$RUN_LOG" 2>&1
  ssh_host "openclaw models status --json" >>"$RUN_LOG" 2>&1
  ORIG_MODEL="$(ssh_host "openclaw models status --json | jq -r '.defaultModel'")"
  log "Original model: ${ORIG_MODEL}"
}

main() {
  require_cmds
  preflight

  # 10 routine prompt checks.
  run_case "route_01_marker" "local" "Respond with exactly: ROUTE_OK_01"
  run_case "route_02_math" "local" "Compute 17*23. Respond with digits only."
  run_case "route_03_json_extract" "local" "Given JSON {\"host\":\"rb1\",\"ip\":\"192.168.5.107\"}, respond with only the ip value."
  run_case "route_04_sort_csv" "local" "Sort these ids alphabetically and respond as CSV only: rb2,mba,rb1"
  run_case "route_05_transform" "local" "Convert aa-bb-cc-dd to colon-separated lowercase and output only result."
  run_case "route_06_wol_short" "local" "In 8 words or fewer, define Wake-on-LAN. Output plain text only."
  run_case "route_07_ping_cmd" "local" "Output one bash command only to ping host 172.31.99.2 twice with timeout 1 second."
  run_case "route_08_yaml" "local" "Return valid YAML with keys host: rb1-fedora and status: ok. No code fences."
  run_case "route_09_python" "local" "Write only a Python function named add that returns a plus b."
  run_case "route_10_gateway_marker" "gateway" "Respond with exactly: ROUTE_OK_10"

  # Coder model path check.
  log "Switching primary model to ${CODER_MODEL} for coder-path check"
  ssh_host "openclaw models set $(printf '%q' "$CODER_MODEL") >/dev/null"
  run_case "coder_path_check" "local" "Write only a Python function named add that returns a plus b."
  log "Restoring primary model to ${LOCAL_MODEL}"
  ssh_host "openclaw models set $(printf '%q' "$LOCAL_MODEL") >/dev/null"
  ORIG_MODEL=""

  # Forced fallback check by stopping Ollama once.
  log "Stopping ollama to force fallback"
  ssh_host "sudo -n systemctl stop ollama"
  OLLAMA_STOPPED=1
  run_case "fallback_forced_check" "gateway" "Respond with exactly: FALLBACK_PATH_OK"
  log "Restarting ollama after fallback test"
  ssh_host "sudo -n systemctl start ollama"
  OLLAMA_STOPPED=0

  log "Completed routing validation"
  log "Matrix: ${OUT_FILE}"
  log "Artifacts: ${RUN_LOG}, ${RUN_JSONL}"
}

main "$@"
