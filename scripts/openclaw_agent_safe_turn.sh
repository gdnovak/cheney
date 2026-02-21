#!/usr/bin/env bash
set -euo pipefail

# Runs one OpenClaw turn with router-aware tier selection and controlled escalation.
# Backward compatibility: preserves core fields used by existing tooling
# (backstopUsed, attempt1/attempt2/final).

usage() {
  cat <<'USAGE'
Usage:
  scripts/openclaw_agent_safe_turn.sh --message "<text>" [options]

Options:
  --message <text>              Message to send (required)
  --host <alias|local>          SSH alias, or local/self for on-host execution (default: rb1-admin)
  --mode <gateway|local>        Use gateway or embedded local path (default: gateway)
  --agent <id>                  Agent id (default: main)
  --thinking <level>            Thinking override for all tiers (default policy: local=off, low=medium, high=high)

  --route-profile <name>        Route profile label for telemetry (default: basic-local-v2)
  --task-class <type>           auto|basic|coding_basic|normal|high_risk (default: auto)
  --force-tier <tier>           local|low|high (start tier override)

  --cloud-low-model <id>        Cloud low tier model (default: auto-resolve)
  --cloud-high-model <id>       Cloud high tier model (default: openai-codex/gpt-5.3-codex)
  --fallback-model <id>         Backward-compatible alias for --cloud-high-model

  --max-local-elapsed-ms <ms>   Escalate local attempt above this latency (default: 10000)
  --max-low-elapsed-ms <ms>     Escalate low attempt above this latency (default: 20000)

  --router-log <path>           Unified router decisions JSONL (default: notes/openclaw-artifacts/openclaw-router-decisions.jsonl)
  --no-backstop                 Disable escalation and run single-tier attempt only
  --no-precheck                 Disable local-runtime precheck before local tier
  --json                        Print wrapper JSON summary instead of plain response
  -h, --help                    Show help

Examples:
  scripts/openclaw_agent_safe_turn.sh --message "Summarize status in one line."
  scripts/openclaw_agent_safe_turn.sh --task-class basic --message "Extract only the IP"
  scripts/openclaw_agent_safe_turn.sh --force-tier high --message "Migration risk assessment"
USAGE
}

HOST_ALIAS="rb1-admin"
MODE="gateway"
AGENT_ID="main"
THINKING_OVERRIDE=""
MESSAGE=""

ROUTE_PROFILE="basic-local-v2"
TASK_CLASS="auto"
FORCE_TIER=""

FALLBACK_MODEL="openai-codex/gpt-5.3-codex"
CLOUD_LOW_MODEL=""
CLOUD_HIGH_MODEL=""

MAX_LOCAL_ELAPSED_MS=10000
MAX_LOW_ELAPSED_MS=20000

ENABLE_BACKSTOP=1
ENABLE_PRECHECK=1
OUTPUT_JSON=0
ROUTER_LOG=""

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
      THINKING_OVERRIDE="${2:-}"
      shift 2
      ;;
    --route-profile)
      ROUTE_PROFILE="${2:-}"
      shift 2
      ;;
    --task-class)
      TASK_CLASS="${2:-}"
      shift 2
      ;;
    --force-tier)
      FORCE_TIER="${2:-}"
      shift 2
      ;;
    --cloud-low-model)
      CLOUD_LOW_MODEL="${2:-}"
      shift 2
      ;;
    --cloud-high-model)
      CLOUD_HIGH_MODEL="${2:-}"
      shift 2
      ;;
    --fallback-model)
      FALLBACK_MODEL="${2:-}"
      shift 2
      ;;
    --max-local-elapsed-ms)
      MAX_LOCAL_ELAPSED_MS="${2:-}"
      shift 2
      ;;
    --max-low-elapsed-ms)
      MAX_LOW_ELAPSED_MS="${2:-}"
      shift 2
      ;;
    --router-log)
      ROUTER_LOG="${2:-}"
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

if [[ "$TASK_CLASS" != "auto" && "$TASK_CLASS" != "basic" && "$TASK_CLASS" != "coding_basic" && "$TASK_CLASS" != "normal" && "$TASK_CLASS" != "high_risk" ]]; then
  echo "--task-class must be auto|basic|coding_basic|normal|high_risk" >&2
  exit 2
fi

if [[ -n "$FORCE_TIER" && "$FORCE_TIER" != "local" && "$FORCE_TIER" != "low" && "$FORCE_TIER" != "high" ]]; then
  echo "--force-tier must be local|low|high" >&2
  exit 2
fi

if ! [[ "$MAX_LOCAL_ELAPSED_MS" =~ ^[0-9]+$ ]] || ! [[ "$MAX_LOW_ELAPSED_MS" =~ ^[0-9]+$ ]]; then
  echo "--max-local-elapsed-ms and --max-low-elapsed-ms must be non-negative integers" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"
mkdir -p "$ARTIFACTS_DIR"

if [[ -z "$ROUTER_LOG" ]]; then
  ROUTER_LOG="${ARTIFACTS_DIR}/openclaw-router-decisions.jsonl"
fi
mkdir -p "$(dirname "$ROUTER_LOG")"

TS_STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="${ARTIFACTS_DIR}/openclaw-safe-turn-${TS_STAMP}.log"
RUN_JSON="${ARTIFACTS_DIR}/openclaw-safe-turn-${TS_STAMP}.json"

ORIG_MODEL=""
CURRENT_MODEL=""
RESTORE_MODEL=0

ATTEMPT_OUT="$(mktemp)"
ATTEMPTS_FILE="$(mktemp)"
MODEL_CATALOG_FILE="$(mktemp)"
BACKSTOP_USED=0
PRECHECK_STATE="not_applicable"
ESCALATION_REASON=""
ALIAS_NOTES=""

LOCAL_GENERAL_MODEL="ollama/qwen2.5:7b"
LOCAL_CODE_MODEL="ollama/qwen2.5-coder:7b"

log() {
  local msg
  msg="$(printf '%s %s' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*")"
  printf '%s\n' "$msg" | tee -a "$RUN_LOG" >&2
}

ssh_host() {
  if [[ "$HOST_ALIAS" == "local" || "$HOST_ALIAS" == "localhost" || "$HOST_ALIAS" == "self" ]]; then
    bash -lc "$*"
    return $?
  fi
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$HOST_ALIAS" "$@"
}

extract_field() {
  local file="$1"
  local jq_expr="$2"
  local default="${3:-}"
  local value

  if [[ ! -s "$file" ]]; then
    printf '%s' "$default"
    return 0
  fi

  value="$(jq -r "(if has(\"result\") then .result else . end) | ${jq_expr}" "$file" 2>/dev/null || true)"
  if [[ -z "$value" || "$value" == "null" ]]; then
    printf '%s' "$default"
  else
    printf '%s' "$value"
  fi
}

field_from_obj() {
  local obj="$1"
  local jq_expr="$2"
  local default="${3:-}"
  local value
  if [[ -z "$obj" ]]; then
    printf '%s' "$default"
    return 0
  fi
  value="$(jq -r "$jq_expr" <<<"$obj" 2>/dev/null || true)"
  if [[ -z "$value" || "$value" == "null" ]]; then
    printf '%s' "$default"
  else
    printf '%s' "$value"
  fi
}

transport_or_sanity_reason() {
  local rc="$1"
  local text="$2"
  local provider="$3"
  local total="$4"
  local text_lc

  if [[ "$rc" -ne 0 ]]; then
    printf '%s' "rc_nonzero"
    return 0
  fi

  if [[ -z "$text" ]]; then
    printf '%s' "empty_response"
    return 0
  fi

  text_lc="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"

  if [[ "$text_lc" == "fetch failed" ]]; then
    printf '%s' "transport_fetch_failed"
    return 0
  fi

  # Some provider/model incompatibilities return as JSON error text with rc=0.
  # Treat known detail/error payloads as escalation-worthy failures.
  if [[ "$text_lc" == *"\"detail\":"* ]]; then
    if [[ "$text_lc" == *"not supported"* || "$text_lc" == *"invalid"* || "$text_lc" == *"unauthorized"* || "$text_lc" == *"rate limit"* || "$text_lc" == *"error"* ]]; then
      printf '%s' "provider_detail_error"
      return 0
    fi
  fi

  if [[ "$provider" == "ollama" && "${total:-0}" == "0" ]]; then
    if [[ "$text_lc" == *"fetch failed"* || "$text_lc" == *"connection"* || "$text_lc" == *"timeout"* || "$text_lc" == *"refused"* ]]; then
      printf '%s' "transport_provider_error"
      return 0
    fi
  fi

  printf '%s' ""
}

classify_task() {
  local msg_lc
  local msg_len

  if [[ "$TASK_CLASS" != "auto" ]]; then
    printf '%s' "$TASK_CLASS"
    return 0
  fi

  msg_lc="$(printf '%s' "$MESSAGE" | tr '[:upper:]' '[:lower:]')"
  msg_len="${#MESSAGE}"

  if [[ "$msg_lc" =~ migration|security|auth|credential|backup|restore|network[[:space:]]cutover|incident|rollback|compliance|production|prod ]]; then
    printf '%s' "high_risk"
    return 0
  fi

  if [[ "$msg_lc" =~ code|function|script|refactor|bug|stack[[:space:]]trace|python|bash|javascript|typescript|rust|go[[:space:]]|sql|regex ]]; then
    printf '%s' "coding_basic"
    return 0
  fi

  if [[ "$msg_len" -le 500 && "$msg_lc" =~ summarize|summary|rewrite|rephrase|format|convert|extract|sort|list|one[[:space:]]line|haiku|transform|json|yaml|csv|ip|hostname|date ]]; then
    printf '%s' "basic"
    return 0
  fi

  printf '%s' "normal"
}

target_tier_for_class() {
  local c="$1"
  case "$c" in
    basic|coding_basic)
      printf '%s' "local"
      ;;
    normal)
      printf '%s' "low"
      ;;
    high_risk)
      printf '%s' "high"
      ;;
    *)
      printf '%s' "low"
      ;;
  esac
}

local_model_for_class() {
  local c="$1"
  if [[ "$c" == "coding_basic" ]]; then
    printf '%s' "$LOCAL_CODE_MODEL"
  else
    printf '%s' "$LOCAL_GENERAL_MODEL"
  fi
}

tier_to_model() {
  local tier="$1"
  local c="$2"
  case "$tier" in
    local)
      local_model_for_class "$c"
      ;;
    low)
      printf '%s' "$CLOUD_LOW_MODEL"
      ;;
    high)
      printf '%s' "$CLOUD_HIGH_MODEL"
      ;;
    *)
      printf '%s' "$CLOUD_HIGH_MODEL"
      ;;
  esac
}

tier_to_thinking() {
  local tier="$1"

  if [[ -n "$THINKING_OVERRIDE" ]]; then
    printf '%s' "$THINKING_OVERRIDE"
    return 0
  fi

  case "$tier" in
    local)
      printf '%s' "off"
      ;;
    low)
      printf '%s' "medium"
      ;;
    high)
      printf '%s' "high"
      ;;
    *)
      printf '%s' "medium"
      ;;
  esac
}

next_tier() {
  local tier="$1"
  case "$tier" in
    local)
      printf '%s' "low"
      ;;
    low)
      printf '%s' "high"
      ;;
    high)
      printf '%s' ""
      ;;
    *)
      printf '%s' ""
      ;;
  esac
}

local_provider_unavailable() {
  if ! ssh_host "systemctl is-active --quiet ollama"; then
    return 0
  fi

  if ! ssh_host "curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null"; then
    return 0
  fi

  return 1
}

append_alias_note() {
  local note="$1"
  if [[ -z "$ALIAS_NOTES" ]]; then
    ALIAS_NOTES="$note"
  else
    ALIAS_NOTES="${ALIAS_NOTES},${note}"
  fi
}

fetch_model_catalog() {
  if ssh_host "openclaw models list --all --json" >"$MODEL_CATALOG_FILE" 2>>"$RUN_LOG"; then
    return 0
  fi

  if ssh_host "openclaw models list --json" >"$MODEL_CATALOG_FILE" 2>>"$RUN_LOG"; then
    return 0
  fi

  if ssh_host "openclaw models status --json | jq '{models: ((.allowed // []) | map({key: .}))}'" >"$MODEL_CATALOG_FILE" 2>>"$RUN_LOG"; then
    return 0
  fi

  printf '%s\n' '{"models":[]}' >"$MODEL_CATALOG_FILE"
}

model_in_catalog() {
  local key="$1"
  jq -e --arg k "$key" '((.models // []) | map(.key) | index($k)) != null' "$MODEL_CATALOG_FILE" >/dev/null 2>&1
}

resolve_models() {
  local candidate

  if [[ -z "$CLOUD_HIGH_MODEL" ]]; then
    CLOUD_HIGH_MODEL="$FALLBACK_MODEL"
  fi

  if [[ -z "$CLOUD_LOW_MODEL" ]]; then
    CLOUD_LOW_MODEL="openai-codex/gpt-5.3-codex"
  fi

  # Resolve high tier first.
  if ! model_in_catalog "$CLOUD_HIGH_MODEL"; then
    append_alias_note "high_model_missing:${CLOUD_HIGH_MODEL}"
    for candidate in \
      "openai-codex/gpt-5.3-codex" \
      "openai-codex/gpt-5.2-codex" \
      "$ORIG_MODEL"; do
      if model_in_catalog "$candidate"; then
        CLOUD_HIGH_MODEL="$candidate"
        append_alias_note "high_model_resolved:${candidate}"
        break
      fi
    done
  fi

  # Resolve low tier; if missing, collapse low->high.
  if ! model_in_catalog "$CLOUD_LOW_MODEL"; then
    append_alias_note "low_model_missing:${CLOUD_LOW_MODEL}"
    CLOUD_LOW_MODEL="$CLOUD_HIGH_MODEL"
    append_alias_note "low_model_collapsed_to_high"
  fi

  # Resolve local general.
  if ! model_in_catalog "$LOCAL_GENERAL_MODEL"; then
    if [[ "$ORIG_MODEL" == ollama/* ]]; then
      append_alias_note "local_general_missing:${LOCAL_GENERAL_MODEL}"
      LOCAL_GENERAL_MODEL="$ORIG_MODEL"
      append_alias_note "local_general_resolved:${LOCAL_GENERAL_MODEL}"
    fi
  fi

  # Resolve local code.
  if ! model_in_catalog "$LOCAL_CODE_MODEL"; then
    append_alias_note "local_code_missing:${LOCAL_CODE_MODEL}"
    LOCAL_CODE_MODEL="$LOCAL_GENERAL_MODEL"
    append_alias_note "local_code_collapsed_to_general"
  fi
}

set_model() {
  local model="$1"

  if [[ -z "$model" ]]; then
    return 1
  fi

  if [[ "$CURRENT_MODEL" == "$model" ]]; then
    return 0
  fi

  if ssh_host "openclaw models set $(printf '%q' "$model") >/dev/null" >>"$RUN_LOG" 2>&1; then
    CURRENT_MODEL="$model"
    if [[ "$CURRENT_MODEL" != "$ORIG_MODEL" ]]; then
      RESTORE_MODEL=1
    fi
    return 0
  fi

  return 1
}

run_attempt() {
  local out_json="$1"
  local thinking="$2"
  local local_flag=""

  if [[ "$MODE" == "local" ]]; then
    local_flag="--local"
  fi

  if ssh_host "openclaw agent ${local_flag} --agent $(printf '%q' "$AGENT_ID") --thinking $(printf '%q' "$thinking") --message $(printf '%q' "$MESSAGE") --json" >"$out_json" 2>>"$RUN_LOG"; then
    return 0
  fi

  return 1
}

record_attempt() {
  local tier="$1"
  local route_model="$2"
  local thinking="$3"
  local rc="$4"
  local reason="$5"
  local skip="$6"
  local file="$7"

  local attempt_idx
  local provider
  local model
  local text
  local duration
  local tokens_total
  local tokens_in
  local tokens_out
  local sanity_ok
  local excerpt

  attempt_idx="$(( $(wc -l < "$ATTEMPTS_FILE") + 1 ))"

  if [[ "$skip" -eq 1 ]]; then
    provider="${route_model%%/*}"
    model="$route_model"
    text="$reason"
    duration=0
    tokens_total=0
    tokens_in=0
    tokens_out=0
    sanity_ok=0
  else
    provider="$(extract_field "$file" '.meta.agentMeta.provider // "unknown"' "unknown")"
    model="$(extract_field "$file" '.meta.agentMeta.model // "unknown"' "$route_model")"
    text="$(extract_field "$file" '.payloads[0].text // ""' "")"
    duration="$(extract_field "$file" '.meta.durationMs // 0' "0")"
    tokens_total="$(extract_field "$file" '.meta.agentMeta.usage.total // 0' "0")"
    tokens_in="$(extract_field "$file" '.meta.agentMeta.usage.input // 0' "0")"
    tokens_out="$(extract_field "$file" '.meta.agentMeta.usage.output // 0' "0")"
    sanity_ok=0
    if [[ "$rc" -eq 0 && -n "$text" && -z "$reason" ]]; then
      sanity_ok=1
    fi
  fi

  excerpt="$(printf '%s' "$text" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-160)"

  jq -nc \
    --argjson index "$attempt_idx" \
    --arg tier "$tier" \
    --arg provider "$provider" \
    --arg model "$model" \
    --arg thinking "$thinking" \
    --argjson rc "$rc" \
    --argjson durationMs "${duration:-0}" \
    --argjson totalTokens "${tokens_total:-0}" \
    --argjson inputTokens "${tokens_in:-0}" \
    --argjson outputTokens "${tokens_out:-0}" \
    --arg text "$text" \
    --arg excerpt "$excerpt" \
    --arg reason "$reason" \
    --argjson sanityOk "$sanity_ok" \
    --argjson skipped "$skip" \
    '{
      index: $index,
      tier: $tier,
      provider: $provider,
      model: $model,
      thinking: $thinking,
      rc: $rc,
      durationMs: $durationMs,
      totalTokens: $totalTokens,
      inputTokens: $inputTokens,
      outputTokens: $outputTokens,
      sanityOk: $sanityOk,
      skipped: ($skipped == 1),
      reason: (if $reason == "" then null else $reason end),
      text: $text,
      excerpt: $excerpt
    }' >>"$ATTEMPTS_FILE"
}

cleanup() {
  local rc=$?

  if [[ "$RESTORE_MODEL" -eq 1 && -n "$ORIG_MODEL" ]]; then
    log "Cleanup: restoring model to ${ORIG_MODEL}"
    ssh_host "openclaw models set $(printf '%q' "$ORIG_MODEL") >/dev/null" >>"$RUN_LOG" 2>&1 || true
  fi

  rm -f "$ATTEMPT_OUT" "$ATTEMPTS_FILE" "$MODEL_CATALOG_FILE"
  exit "$rc"
}
trap cleanup EXIT

log "Host=${HOST_ALIAS} mode=${MODE} agent=${AGENT_ID}"
log "Artifacts: ${RUN_LOG} / ${RUN_JSON}"

ORIG_MODEL="$(ssh_host "openclaw models status --json | jq -r '.defaultModel'")"
CURRENT_MODEL="$ORIG_MODEL"
log "Original model: ${ORIG_MODEL}"

fetch_model_catalog
resolve_models

DERIVED_TASK_CLASS="$(classify_task)"
TARGET_TIER="$(target_tier_for_class "$DERIVED_TASK_CLASS")"
START_TIER="$TARGET_TIER"
if [[ -n "$FORCE_TIER" ]]; then
  START_TIER="$FORCE_TIER"
fi

log "Resolved task_class=${DERIVED_TASK_CLASS} target_tier=${TARGET_TIER} start_tier=${START_TIER}"
log "Resolved models: local_general=${LOCAL_GENERAL_MODEL} local_code=${LOCAL_CODE_MODEL} cloud_low=${CLOUD_LOW_MODEL} cloud_high=${CLOUD_HIGH_MODEL}"
log "Resolved thinking policy: override=${THINKING_OVERRIDE:-none} local=off low=medium high=high"
if [[ -n "$ALIAS_NOTES" ]]; then
  log "Alias notes: ${ALIAS_NOTES}"
fi

CURRENT_TIER="$START_TIER"

if [[ "$CURRENT_TIER" == "local" ]]; then
  PRECHECK_STATE="skipped"
  if [[ "$ENABLE_PRECHECK" -eq 1 ]]; then
    if local_provider_unavailable; then
      PRECHECK_STATE="unavailable"
      log "Precheck: local provider unavailable"
      if [[ "$ENABLE_BACKSTOP" -eq 1 ]]; then
        LOCAL_SKIP_MODEL="$(tier_to_model "local" "$DERIVED_TASK_CLASS")"
        LOCAL_SKIP_THINKING="$(tier_to_thinking "local")"
        record_attempt "local" "$LOCAL_SKIP_MODEL" "$LOCAL_SKIP_THINKING" 0 "local_precheck_unavailable" 1 "$ATTEMPT_OUT"
        ESCALATION_REASON="local_precheck_unavailable"
        CURRENT_TIER="low"
        BACKSTOP_USED=1
      fi
    else
      PRECHECK_STATE="ok"
    fi
  fi
fi

FINAL_RC=0
FINAL_TEXT=""

while :; do
  ATTEMPT_REASON=""
  ATTEMPT_MODEL="$(tier_to_model "$CURRENT_TIER" "$DERIVED_TASK_CLASS")"
  ATTEMPT_THINKING="$(tier_to_thinking "$CURRENT_TIER")"

  if ! set_model "$ATTEMPT_MODEL"; then
    ATTEMPT_REASON="model_set_failed"
    ATTEMPT_RC=90
    record_attempt "$CURRENT_TIER" "$ATTEMPT_MODEL" "$ATTEMPT_THINKING" "$ATTEMPT_RC" "$ATTEMPT_REASON" 1 "$ATTEMPT_OUT"
  else
    if run_attempt "$ATTEMPT_OUT" "$ATTEMPT_THINKING"; then
      ATTEMPT_RC=0
    else
      ATTEMPT_RC=$?
    fi

    ATTEMPT_TEXT="$(extract_field "$ATTEMPT_OUT" '.payloads[0].text // ""' "")"
    ATTEMPT_PROVIDER="$(extract_field "$ATTEMPT_OUT" '.meta.agentMeta.provider // "unknown"' "unknown")"
    ATTEMPT_TOTAL="$(extract_field "$ATTEMPT_OUT" '.meta.agentMeta.usage.total // 0' "0")"
    ATTEMPT_DURATION="$(extract_field "$ATTEMPT_OUT" '.meta.durationMs // 0' "0")"

    ATTEMPT_REASON="$(transport_or_sanity_reason "$ATTEMPT_RC" "$ATTEMPT_TEXT" "$ATTEMPT_PROVIDER" "$ATTEMPT_TOTAL")"

    if [[ -z "$ATTEMPT_REASON" && "$CURRENT_TIER" == "local" && "$ATTEMPT_DURATION" -gt "$MAX_LOCAL_ELAPSED_MS" ]]; then
      ATTEMPT_REASON="local_latency_threshold"
    fi
    if [[ -z "$ATTEMPT_REASON" && "$CURRENT_TIER" == "low" && "$ATTEMPT_DURATION" -gt "$MAX_LOW_ELAPSED_MS" ]]; then
      ATTEMPT_REASON="low_latency_threshold"
    fi

    record_attempt "$CURRENT_TIER" "$ATTEMPT_MODEL" "$ATTEMPT_THINKING" "$ATTEMPT_RC" "$ATTEMPT_REASON" 0 "$ATTEMPT_OUT"
  fi

  if [[ -z "$ATTEMPT_REASON" ]]; then
    break
  fi

  if [[ "$ENABLE_BACKSTOP" -eq 0 ]]; then
    break
  fi

  NEXT_TIER="$(next_tier "$CURRENT_TIER")"
  if [[ -z "$NEXT_TIER" ]]; then
    break
  fi

  BACKSTOP_USED=1
  if [[ -z "$ESCALATION_REASON" ]]; then
    ESCALATION_REASON="$ATTEMPT_REASON"
  fi

  log "Escalating tier ${CURRENT_TIER} -> ${NEXT_TIER} (reason=${ATTEMPT_REASON})"
  CURRENT_TIER="$NEXT_TIER"
done

ATTEMPTS_JSON="$(jq -s '.' "$ATTEMPTS_FILE")"
FINAL_OBJ="$(tail -n 1 "$ATTEMPTS_FILE")"
ATTEMPT1_OBJ="$(sed -n '1p' "$ATTEMPTS_FILE" || true)"
ATTEMPT2_OBJ="$(sed -n '2p' "$ATTEMPTS_FILE" || true)"

FINAL_RC="$(field_from_obj "$FINAL_OBJ" '.rc // 1' '1')"
FINAL_TEXT="$(field_from_obj "$FINAL_OBJ" '.text // ""' '')"
FINAL_PROVIDER="$(field_from_obj "$FINAL_OBJ" '.provider // "unknown"' 'unknown')"
FINAL_MODEL="$(field_from_obj "$FINAL_OBJ" '.model // "unknown"' 'unknown')"
FINAL_THINKING="$(field_from_obj "$FINAL_OBJ" '.thinking // "off"' 'off')"
FINAL_DURATION="$(field_from_obj "$FINAL_OBJ" '.durationMs // 0' '0')"
FINAL_TOTAL="$(field_from_obj "$FINAL_OBJ" '.totalTokens // 0' '0')"
FINAL_SANITY="$(field_from_obj "$FINAL_OBJ" '.sanityOk // 0' '0')"
FINAL_TIER="$(field_from_obj "$FINAL_OBJ" '.tier // "unknown"' 'unknown')"

ATTEMPT1_PROVIDER="$(field_from_obj "$ATTEMPT1_OBJ" '.provider // "unknown"' 'unknown')"
ATTEMPT1_MODEL="$(field_from_obj "$ATTEMPT1_OBJ" '.model // "unknown"' 'unknown')"
ATTEMPT1_THINKING="$(field_from_obj "$ATTEMPT1_OBJ" '.thinking // "off"' 'off')"
ATTEMPT1_DURATION="$(field_from_obj "$ATTEMPT1_OBJ" '.durationMs // 0' '0')"
ATTEMPT1_TOTAL="$(field_from_obj "$ATTEMPT1_OBJ" '.totalTokens // 0' '0')"
ATTEMPT1_TEXT="$(field_from_obj "$ATTEMPT1_OBJ" '.text // ""' '')"
ATTEMPT1_RC="$(field_from_obj "$ATTEMPT1_OBJ" '.rc // 0' '0')"

ATTEMPT2_PROVIDER="$(field_from_obj "$ATTEMPT2_OBJ" '.provider // "unknown"' 'unknown')"
ATTEMPT2_MODEL="$(field_from_obj "$ATTEMPT2_OBJ" '.model // "unknown"' 'unknown')"
ATTEMPT2_THINKING="$(field_from_obj "$ATTEMPT2_OBJ" '.thinking // "off"' 'off')"
ATTEMPT2_DURATION="$(field_from_obj "$ATTEMPT2_OBJ" '.durationMs // 0' '0')"
ATTEMPT2_TOTAL="$(field_from_obj "$ATTEMPT2_OBJ" '.totalTokens // 0' '0')"
ATTEMPT2_TEXT="$(field_from_obj "$ATTEMPT2_OBJ" '.text // ""' '')"
ATTEMPT2_RC="$(field_from_obj "$ATTEMPT2_OBJ" '.rc // 0' '0')"

ATTEMPT_CHAIN_JSON="$(jq -c '[.[].tier]' <<<"$ATTEMPTS_JSON")"

jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg host "$HOST_ALIAS" \
  --arg mode "$MODE" \
  --arg agent "$AGENT_ID" \
  --arg routeProfile "$ROUTE_PROFILE" \
  --arg taskClass "$DERIVED_TASK_CLASS" \
  --arg targetTier "$TARGET_TIER" \
  --arg chosenTier "$FINAL_TIER" \
  --arg forceTier "$FORCE_TIER" \
  --arg thinkingOverride "$THINKING_OVERRIDE" \
  --arg precheckState "$PRECHECK_STATE" \
  --arg escalationReason "$ESCALATION_REASON" \
  --arg aliasNotes "$ALIAS_NOTES" \
  --arg originalModel "$ORIG_MODEL" \
  --arg localGeneralModel "$LOCAL_GENERAL_MODEL" \
  --arg localCodeModel "$LOCAL_CODE_MODEL" \
  --arg cloudLowModel "$CLOUD_LOW_MODEL" \
  --arg cloudHighModel "$CLOUD_HIGH_MODEL" \
  --arg fallbackModel "$CLOUD_HIGH_MODEL" \
  --argjson maxLocalElapsedMs "$MAX_LOCAL_ELAPSED_MS" \
  --argjson maxLowElapsedMs "$MAX_LOW_ELAPSED_MS" \
  --argjson backstopUsed "$BACKSTOP_USED" \
  --argjson attempts "$ATTEMPTS_JSON" \
  --argjson attemptChain "$ATTEMPT_CHAIN_JSON" \
  --argjson attempt1_rc "$ATTEMPT1_RC" \
  --arg attempt1_provider "$ATTEMPT1_PROVIDER" \
  --arg attempt1_model "$ATTEMPT1_MODEL" \
  --arg attempt1_thinking "$ATTEMPT1_THINKING" \
  --argjson attempt1_duration "$ATTEMPT1_DURATION" \
  --argjson attempt1_total "$ATTEMPT1_TOTAL" \
  --arg attempt1_text "$ATTEMPT1_TEXT" \
  --argjson attempt2_rc "$ATTEMPT2_RC" \
  --arg attempt2_provider "$ATTEMPT2_PROVIDER" \
  --arg attempt2_model "$ATTEMPT2_MODEL" \
  --arg attempt2_thinking "$ATTEMPT2_THINKING" \
  --argjson attempt2_duration "$ATTEMPT2_DURATION" \
  --argjson attempt2_total "$ATTEMPT2_TOTAL" \
  --arg attempt2_text "$ATTEMPT2_TEXT" \
  --argjson final_rc "$FINAL_RC" \
  --arg final_provider "$FINAL_PROVIDER" \
  --arg final_model "$FINAL_MODEL" \
  --arg final_thinking "$FINAL_THINKING" \
  --argjson final_duration "$FINAL_DURATION" \
  --argjson final_total "$FINAL_TOTAL" \
  --arg final_text "$FINAL_TEXT" \
  --argjson final_sanity "$FINAL_SANITY" \
  '{
    timestampUtc: $ts,
    host: $host,
    mode: $mode,
    agent: $agent,
    routeProfile: $routeProfile,
    taskClass: $taskClass,
    targetTier: $targetTier,
    chosenTier: $chosenTier,
    forceTier: (if $forceTier == "" then null else $forceTier end),
    thinkingOverride: (if $thinkingOverride == "" then null else $thinkingOverride end),
    precheckState: $precheckState,
    escalationReason: (if $escalationReason == "" then null else $escalationReason end),
    aliasNotes: (if $aliasNotes == "" then [] else ($aliasNotes | split(",")) end),
    backstopUsed: $backstopUsed,
    originalModel: $originalModel,
    localGeneralModel: $localGeneralModel,
    localCodeModel: $localCodeModel,
    cloudLowModel: $cloudLowModel,
    cloudHighModel: $cloudHighModel,
    fallbackModel: $fallbackModel,
    maxLocalElapsedMs: $maxLocalElapsedMs,
    maxLowElapsedMs: $maxLowElapsedMs,
    attemptChain: $attemptChain,
    attempts: $attempts,
    attempt1: {
      provider: $attempt1_provider,
      model: $attempt1_model,
      thinking: $attempt1_thinking,
      durationMs: $attempt1_duration,
      totalTokens: $attempt1_total,
      text: $attempt1_text,
      rc: $attempt1_rc
    },
    attempt2: {
      provider: $attempt2_provider,
      model: $attempt2_model,
      thinking: $attempt2_thinking,
      durationMs: $attempt2_duration,
      totalTokens: $attempt2_total,
      text: $attempt2_text,
      rc: $attempt2_rc
    },
    final: {
      provider: $final_provider,
      model: $final_model,
      thinking: $final_thinking,
      durationMs: $final_duration,
      totalTokens: $final_total,
      text: $final_text,
      sanityOk: $final_sanity,
      rc: $final_rc
    }
  }' >"$RUN_JSON"

# Unified per-turn router telemetry row.
jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg routeProfile "$ROUTE_PROFILE" \
  --arg taskClass "$DERIVED_TASK_CLASS" \
  --arg chosenTier "$FINAL_TIER" \
  --arg targetTier "$TARGET_TIER" \
  --arg forceTier "$FORCE_TIER" \
  --arg mode "$MODE" \
  --arg host "$HOST_ALIAS" \
  --arg finalProvider "$FINAL_PROVIDER" \
  --arg finalModel "$FINAL_MODEL" \
  --arg finalThinking "$FINAL_THINKING" \
  --arg escalationReason "$ESCALATION_REASON" \
  --arg precheckState "$PRECHECK_STATE" \
  --arg runJson "$RUN_JSON" \
  --argjson rc "$FINAL_RC" \
  --argjson elapsedMs "$FINAL_DURATION" \
  --argjson sanityOk "$FINAL_SANITY" \
  --argjson tokensTotal "$FINAL_TOTAL" \
  --argjson backstopUsed "$BACKSTOP_USED" \
  --argjson attemptChain "$ATTEMPT_CHAIN_JSON" \
  '{
    timestampUtc: $ts,
    routeProfile: $routeProfile,
    taskClass: $taskClass,
    targetTier: $targetTier,
    chosenTier: $chosenTier,
    forceTier: (if $forceTier == "" then null else $forceTier end),
    mode: $mode,
    host: $host,
    finalProvider: $finalProvider,
    finalModel: $finalModel,
    finalThinking: $finalThinking,
    rc: $rc,
    elapsedMs: $elapsedMs,
    sanityOk: $sanityOk,
    tokensTotal: $tokensTotal,
    backstopUsed: $backstopUsed,
    attemptChain: $attemptChain,
    escalationReason: (if $escalationReason == "" then null else $escalationReason end),
    precheckState: $precheckState,
    runJson: $runJson
  }' >>"$ROUTER_LOG"

if [[ "$OUTPUT_JSON" -eq 1 ]]; then
  cat "$RUN_JSON"
else
  printf '%s\n' "$FINAL_TEXT"
  log "Final tier=${FINAL_TIER} provider=${FINAL_PROVIDER} model=${FINAL_MODEL} backstop_used=${BACKSTOP_USED} rc=${FINAL_RC} tokens=${FINAL_TOTAL} duration_ms=${FINAL_DURATION}"
  log "Run summary JSON: ${RUN_JSON}"
  log "Router log appended: ${ROUTER_LOG}"
fi

if [[ "$FINAL_RC" -ne 0 ]]; then
  exit "$FINAL_RC"
fi
