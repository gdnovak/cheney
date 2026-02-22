#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/openclaw_router_repl.sh [options]

Interactive REPL that forces every turn through openclaw_agent_safe_turn.sh
so routing policy is always applied.

Options:
  --host <alias|local>        Wrapper host mode (default: local)
  --mode <gateway|local>      Wrapper mode (default: gateway)
  --agent <id>                Agent id (default: main)
  --task-class <type>         auto|basic|coding_basic|normal|high_risk (default: basic)
  --thinking <level>          off|minimal|low|medium|high (default: off)
  --route-profile <name>      Route profile tag (default: basic-local-v3)
  --force-tier <tier|off>     local|low|high|off (default: off)
  --jsonl-log <path>          Session JSONL log path (default: notes/openclaw-artifacts/router-repl-<ts>.jsonl)
  --show-meta                 Always print provider/model/latency metadata (default: on)

  --warmup <auto|off>         Startup warmup behavior (default: auto)
  --warm-scope <both|14b|7b|active>
                              Which local models to warm (default: 7b; 14b remapped to 7b)
  --keepwarm <on|off>         Keep target models warm while REPL is running (default: on)
  --keepwarm-interval-sec <n> Keepwarm poll interval seconds (default: 120)
  --warm-timeout-sec <n>      Max seconds to wait for a model to warm (default: 180)
  --warm-model-14b <name>     14B model id for warm tracking (default: qwen2.5:14b)
  --warm-model-7b <name>      7B model id for warm tracking (default: qwen2.5:7b)
  --warm-keepalive <dur>      Ollama keep_alive duration for warm calls (default: 30m)

  -h, --help                  Show help

Commands inside REPL:
  /help
  /exit
  /status
  /task <type>
  /thinking <level>
  /force <local|low|high|off>
  /warm-status
  /warm-now
  /keepwarm <on|off>
USAGE
}

HOST_ALIAS="local"
MODE="gateway"
AGENT_ID="main"
TASK_CLASS="basic"
THINKING="off"
ROUTE_PROFILE="basic-local-v3"
FORCE_TIER="off"
SHOW_META=1
JSONL_LOG=""

WARMUP_MODE="auto"
WARM_SCOPE="7b"
KEEPWARM="on"
KEEPWARM_INTERVAL_SEC=120
WARM_TIMEOUT_SEC=180
WARM_MODEL_14B="qwen2.5:14b"
WARM_MODEL_7B="qwen2.5:7b"
WARM_KEEPALIVE="30m"
KEEPWARM_PID=""
WARM_SCOPE_REQUESTED=""

declare -A WARM_STATE=()
declare -A WARM_TTL_SEC=()
declare -A WARM_EXPIRES_AT=()
declare -A WARM_LOADING=()
WARM_TRACKED_MODELS=()
WARM_TARGET_MODELS=()

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
    --task-class)
      TASK_CLASS="${2:-}"
      shift 2
      ;;
    --thinking)
      THINKING="${2:-}"
      shift 2
      ;;
    --route-profile)
      ROUTE_PROFILE="${2:-}"
      shift 2
      ;;
    --force-tier)
      FORCE_TIER="${2:-}"
      shift 2
      ;;
    --jsonl-log)
      JSONL_LOG="${2:-}"
      shift 2
      ;;
    --show-meta)
      SHOW_META=1
      shift
      ;;
    --warmup)
      WARMUP_MODE="${2:-}"
      shift 2
      ;;
    --warm-scope)
      WARM_SCOPE="${2:-}"
      shift 2
      ;;
    --keepwarm)
      KEEPWARM="${2:-}"
      shift 2
      ;;
    --keepwarm-interval-sec)
      KEEPWARM_INTERVAL_SEC="${2:-}"
      shift 2
      ;;
    --warm-timeout-sec)
      WARM_TIMEOUT_SEC="${2:-}"
      shift 2
      ;;
    --warm-model-14b)
      WARM_MODEL_14B="${2:-}"
      shift 2
      ;;
    --warm-model-7b)
      WARM_MODEL_7B="${2:-}"
      shift 2
      ;;
    --warm-keepalive)
      WARM_KEEPALIVE="${2:-}"
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

if [[ "$TASK_CLASS" != "auto" && "$TASK_CLASS" != "basic" && "$TASK_CLASS" != "coding_basic" && "$TASK_CLASS" != "normal" && "$TASK_CLASS" != "high_risk" ]]; then
  echo "--task-class must be auto|basic|coding_basic|normal|high_risk" >&2
  exit 2
fi

if [[ "$FORCE_TIER" != "off" && "$FORCE_TIER" != "local" && "$FORCE_TIER" != "low" && "$FORCE_TIER" != "high" ]]; then
  echo "--force-tier must be local|low|high|off" >&2
  exit 2
fi

if [[ "$WARMUP_MODE" != "auto" && "$WARMUP_MODE" != "off" ]]; then
  echo "--warmup must be auto|off" >&2
  exit 2
fi

if [[ "$WARM_SCOPE" != "both" && "$WARM_SCOPE" != "14b" && "$WARM_SCOPE" != "7b" && "$WARM_SCOPE" != "active" ]]; then
  echo "--warm-scope must be both|14b|7b|active" >&2
  exit 2
fi

WARM_SCOPE_REQUESTED="$WARM_SCOPE"
# 14B is excluded for this host profile; remap warm policy to 7B.
if [[ "$WARM_SCOPE" == "14b" || "$WARM_SCOPE" == "both" ]]; then
  WARM_SCOPE="7b"
fi

if [[ "$KEEPWARM" != "on" && "$KEEPWARM" != "off" ]]; then
  echo "--keepwarm must be on|off" >&2
  exit 2
fi

if ! [[ "$KEEPWARM_INTERVAL_SEC" =~ ^[0-9]+$ ]] || ! [[ "$WARM_TIMEOUT_SEC" =~ ^[0-9]+$ ]]; then
  echo "--keepwarm-interval-sec and --warm-timeout-sec must be non-negative integers" >&2
  exit 2
fi

if (( KEEPWARM_INTERVAL_SEC < 1 )); then
  KEEPWARM_INTERVAL_SEC=1
fi
if (( WARM_TIMEOUT_SEC < 1 )); then
  WARM_TIMEOUT_SEC=1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER="${ROOT_DIR}/scripts/openclaw_agent_safe_turn.sh"
INPUT_HELPER="${ROOT_DIR}/scripts/openclaw_router_repl_input.py"
if [[ ! -x "$WRAPPER" ]]; then
  echo "Wrapper not found/executable: $WRAPPER" >&2
  exit 1
fi

ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"
mkdir -p "$ARTIFACTS_DIR"

if [[ -z "$JSONL_LOG" ]]; then
  JSONL_LOG="${ARTIFACTS_DIR}/router-repl-$(date +%Y%m%d-%H%M%S).jsonl"
fi
mkdir -p "$(dirname "$JSONL_LOG")"
touch "$JSONL_LOG"

HISTORY_FILE="${ARTIFACTS_DIR}/router-repl.history"
USE_TOOLKIT_INPUT=0
COLOR_ENABLED=0
CLR_RESET=""
CLR_ASSIST=""
CLR_DIAG=""

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  COLOR_ENABLED=1
  CLR_RESET=$'\033[0m'
  CLR_ASSIST=$'\033[97m'
  CLR_DIAG=$'\033[90m'
fi

host_exec() {
  local cmd="$1"
  if [[ "$HOST_ALIAS" == "local" || "$HOST_ALIAS" == "localhost" || "$HOST_ALIAS" == "self" ]]; then
    bash -lc "$cmd"
    return $?
  fi
  ssh -n -o BatchMode=yes -o ConnectTimeout=8 "$HOST_ALIAS" "$cmd"
}

dedupe_array() {
  local -n arr="$1"
  local -A seen=()
  local item
  local out=()
  for item in "${arr[@]}"; do
    [[ -n "$item" ]] || continue
    if [[ -n "${seen[$item]:-}" ]]; then
      continue
    fi
    seen["$item"]=1
    out+=("$item")
  done
  arr=("${out[@]}")
}

resolve_warm_targets() {
  # Track only the active 7B lane for this profile.
  WARM_TRACKED_MODELS=("$WARM_MODEL_7B")
  dedupe_array WARM_TRACKED_MODELS

  case "$WARM_SCOPE" in
    both|14b|7b)
      WARM_TARGET_MODELS=("$WARM_MODEL_7B")
      ;;
    active)
      if [[ "$FORCE_TIER" == "high" ]]; then
        WARM_TARGET_MODELS=()
      else
        # Local/default path is 7B-first for this profile.
        WARM_TARGET_MODELS=("$WARM_MODEL_7B")
      fi
      ;;
  esac
  dedupe_array WARM_TARGET_MODELS
}

fetch_ollama_ps() {
  host_exec "curl -fsS --max-time 5 http://127.0.0.1:11434/api/ps"
}

refresh_warm_state_cache() {
  local ps_json
  local model
  local entry
  local expires_at
  local expires_epoch
  local now_epoch
  local ttl

  if ! ps_json="$(fetch_ollama_ps 2>/dev/null)"; then
    for model in "${WARM_TRACKED_MODELS[@]}"; do
      if [[ "${WARM_LOADING[$model]:-0}" -eq 1 ]]; then
        WARM_STATE["$model"]="warming"
      else
        WARM_STATE["$model"]="unknown"
      fi
      WARM_TTL_SEC["$model"]=0
      WARM_EXPIRES_AT["$model"]=""
    done
    return 1
  fi

  now_epoch="$(date +%s)"

  for model in "${WARM_TRACKED_MODELS[@]}"; do
    entry="$(jq -c --arg model "$model" '(.models // []) | map(select((.name // .model) == $model)) | .[0] // empty' <<<"$ps_json")"
    if [[ -n "$entry" ]]; then
      expires_at="$(jq -r '.expires_at // ""' <<<"$entry")"
      ttl=0
      if [[ -n "$expires_at" ]]; then
        if expires_epoch="$(date -d "$expires_at" +%s 2>/dev/null)"; then
          ttl=$((expires_epoch - now_epoch))
          if (( ttl < 0 )); then
            ttl=0
          fi
        fi
      fi
      WARM_STATE["$model"]="warmed"
      WARM_TTL_SEC["$model"]="$ttl"
      WARM_EXPIRES_AT["$model"]="$expires_at"
      WARM_LOADING["$model"]=0
    else
      if [[ "${WARM_LOADING[$model]:-0}" -eq 1 ]]; then
        WARM_STATE["$model"]="warming"
      else
        WARM_STATE["$model"]="cold"
      fi
      WARM_TTL_SEC["$model"]=0
      WARM_EXPIRES_AT["$model"]=""
    fi
  done

  return 0
}

warm_num_gpu_for_model() {
  local model="$1"
  : "$model"
  printf ''
}

issue_warm_request() {
  local model="$1"
  local num_gpu="$2"
  local payload

  if [[ -n "$num_gpu" ]]; then
    payload="$(jq -nc --arg model "$model" --arg keepalive "$WARM_KEEPALIVE" --argjson num_gpu "$num_gpu" '{model:$model,prompt:"warmup",stream:false,options:{num_predict:1,num_gpu:$num_gpu},keep_alive:$keepalive}')"
  else
    payload="$(jq -nc --arg model "$model" --arg keepalive "$WARM_KEEPALIVE" '{model:$model,prompt:"warmup",stream:false,options:{num_predict:1},keep_alive:$keepalive}')"
  fi

  host_exec "curl -fsS --max-time 120 http://127.0.0.1:11434/api/generate -H 'Content-Type: application/json' -d $(printf '%q' "$payload") >/dev/null"
}

print_diag_line() {
  local line="$1"
  if [[ "$COLOR_ENABLED" -eq 1 ]]; then
    printf '%s%s%s\n' "$CLR_DIAG" "$line" "$CLR_RESET"
  else
    printf '%s\n' "$line"
  fi
}

warm_model_blocking() {
  local model="$1"
  local reason="$2"
  local start_epoch
  local now_epoch
  local elapsed
  local last_emit=-1
  local current_state
  local ttl
  local num_gpu
  local placement_note

  num_gpu="$(warm_num_gpu_for_model "$model")"
  if [[ -n "$num_gpu" ]]; then
    placement_note="cpu"
  else
    placement_note="default"
  fi

  WARM_LOADING["$model"]=1
  WARM_STATE["$model"]="warming"
  print_diag_line "[warm] ${model} cold -> warming (reason=${reason}, placement=${placement_note})"

  if ! issue_warm_request "$model" "$num_gpu"; then
    WARM_LOADING["$model"]=0
    refresh_warm_state_cache >/dev/null 2>&1 || true
    print_diag_line "[warm] ${model} warm request failed"
    return 1
  fi

  start_epoch="$(date +%s)"
  while true; do
    refresh_warm_state_cache >/dev/null 2>&1 || true
    current_state="${WARM_STATE[$model]:-unknown}"
    ttl="${WARM_TTL_SEC[$model]:-0}"

    if [[ "$current_state" == "warmed" ]]; then
      WARM_LOADING["$model"]=0
      print_diag_line "[warm] ${model} warmed ttl=${ttl}s"
      return 0
    fi

    now_epoch="$(date +%s)"
    elapsed=$((now_epoch - start_epoch))

    if (( elapsed >= WARM_TIMEOUT_SEC )); then
      WARM_LOADING["$model"]=0
      refresh_warm_state_cache >/dev/null 2>&1 || true
      print_diag_line "[warm] ${model} still ${current_state} after ${elapsed}s (timeout=${WARM_TIMEOUT_SEC}s)"
      return 1
    fi

    if (( elapsed > 0 && elapsed % 5 == 0 && elapsed != last_emit )); then
      print_diag_line "[warm] ${model} warming elapsed=${elapsed}s"
      last_emit="$elapsed"
    fi

    sleep 1
  done
}

model_needs_warm() {
  local model="$1"
  local reason="$2"
  local state
  local ttl
  local keepwarm_min_ttl

  state="${WARM_STATE[$model]:-unknown}"
  ttl="${WARM_TTL_SEC[$model]:-0}"

  if [[ "$state" != "warmed" ]]; then
    return 0
  fi

  if [[ "$reason" == "keepalive" ]]; then
    keepwarm_min_ttl=$((KEEPWARM_INTERVAL_SEC + 30))
    if (( keepwarm_min_ttl < 30 )); then
      keepwarm_min_ttl=30
    fi
    if (( ttl <= keepwarm_min_ttl )); then
      return 0
    fi
  fi

  return 1
}

all_warm_targets_ready() {
  local model
  for model in "${WARM_TARGET_MODELS[@]}"; do
    if [[ "${WARM_STATE[$model]:-unknown}" != "warmed" ]]; then
      return 1
    fi
  done
  return 0
}

ensure_warm_targets() {
  local reason="$1"
  local model
  local pass

  resolve_warm_targets
  refresh_warm_state_cache >/dev/null 2>&1 || true

  if [[ "${#WARM_TARGET_MODELS[@]}" -eq 0 ]]; then
    return 0
  fi

  for model in "${WARM_TARGET_MODELS[@]}"; do
    if model_needs_warm "$model" "$reason"; then
      warm_model_blocking "$model" "$reason" || true
    fi
  done
}

format_warm_targets() {
  if [[ "${#WARM_TARGET_MODELS[@]}" -eq 0 ]]; then
    printf 'none'
  else
    printf '%s' "${WARM_TARGET_MODELS[*]}"
  fi
}

print_warm_status() {
  local model
  local state
  local ttl
  local expires
  local suffix

  resolve_warm_targets
  refresh_warm_state_cache >/dev/null 2>&1 || true

  print_diag_line "warm_state:"
  for model in "${WARM_TRACKED_MODELS[@]}"; do
    state="${WARM_STATE[$model]:-unknown}"
    ttl="${WARM_TTL_SEC[$model]:-0}"
    expires="${WARM_EXPIRES_AT[$model]:-}"
    suffix=""

    if [[ "$state" == "warmed" ]]; then
      suffix="ttl=${ttl}s"
    elif [[ "$state" == "warming" ]]; then
      suffix="loading"
    elif [[ "$state" == "unknown" ]]; then
      suffix="ollama_unreachable"
    fi

    if [[ -n "$expires" && "$state" == "warmed" ]]; then
      suffix="${suffix} expires_at=${expires}"
    fi

    if [[ -n "$suffix" ]]; then
      print_diag_line "  ${model}: ${state} (${suffix})"
    else
      print_diag_line "  ${model}: ${state}"
    fi
  done
  print_diag_line "warm_targets: $(format_warm_targets)"
}

start_keepwarm_loop() {
  if [[ "$KEEPWARM" != "on" ]]; then
    return 0
  fi

  if [[ -n "$KEEPWARM_PID" ]] && kill -0 "$KEEPWARM_PID" 2>/dev/null; then
    return 0
  fi

  (
    while true; do
      sleep "$KEEPWARM_INTERVAL_SEC"
      ensure_warm_targets "keepalive"
    done
  ) &
  KEEPWARM_PID="$!"
  print_diag_line "[warm] keepwarm enabled interval=${KEEPWARM_INTERVAL_SEC}s pid=${KEEPWARM_PID}"
}

stop_keepwarm_loop() {
  if [[ -z "$KEEPWARM_PID" ]]; then
    return 0
  fi
  if kill -0 "$KEEPWARM_PID" 2>/dev/null; then
    kill "$KEEPWARM_PID" 2>/dev/null || true
    wait "$KEEPWARM_PID" 2>/dev/null || true
  fi
  KEEPWARM_PID=""
}

print_status() {
  resolve_warm_targets
  cat <<STATUS
status:
  host=${HOST_ALIAS}
  mode=${MODE}
  agent=${AGENT_ID}
  task_class=${TASK_CLASS}
  thinking=${THINKING}
  route_profile=${ROUTE_PROFILE}
  force_tier=${FORCE_TIER}
  warmup=${WARMUP_MODE}
  warm_scope=${WARM_SCOPE}
  warm_scope_requested=${WARM_SCOPE_REQUESTED}
  warm_models=14b:${WARM_MODEL_14B},7b:${WARM_MODEL_7B}
  warm_14b_excluded=true
  warm_keepalive=${WARM_KEEPALIVE}
  keepwarm=${KEEPWARM}
  keepwarm_interval_sec=${KEEPWARM_INTERVAL_SEC}
  warm_timeout_sec=${WARM_TIMEOUT_SEC}
  warm_targets=$(format_warm_targets)
  keepwarm_pid=${KEEPWARM_PID:-none}
  log=${JSONL_LOG}
STATUS
}

print_help() {
  cat <<'HELP'
commands:
  /help                        show this help
  /status                      show current repl settings
  /task <type>                 set task class
  /thinking <level>            set thinking override
  /force <local|low|high|off>  set force tier
  /warm-status                 show warm/cold state for tracked models
  /warm-now                    trigger immediate warm pass for target models
  /keepwarm <on|off>           toggle background keepwarm loop
  /exit                        quit
HELP
}

print_assistant_reply() {
  local model="$1"
  local text="$2"
  if [[ "$COLOR_ENABLED" -eq 1 ]]; then
    printf '%s[%s] %s%s\n' "$CLR_ASSIST" "$model" "$text" "$CLR_RESET"
  else
    printf '[%s] %s\n' "$model" "$text"
  fi
}

print_diag_block() {
  local file="$1"
  local line=""
  [[ -s "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    print_diag_line "[diag] ${line}"
  done <"$file"
}

__router_repl_insert_literal_newline_token() {
  local left right
  left="${READLINE_LINE:0:READLINE_POINT}"
  right="${READLINE_LINE:READLINE_POINT}"
  READLINE_LINE="${left}\\n${right}"
  READLINE_POINT=$((READLINE_POINT + 2))
}

configure_readline_input() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    return
  fi
  if [[ -x "$INPUT_HELPER" ]] && python3 -c 'import prompt_toolkit' >/dev/null 2>&1; then
    USE_TOOLKIT_INPUT=1
    return
  fi
  if ! builtin bind -V >/dev/null 2>&1; then
    return
  fi

  # Fallback mode when prompt_toolkit is unavailable.
  # Ctrl+J inserts a visible "\\n" token so multiline intent is preserved.
  set -o emacs
  bind '"\C-m":accept-line'
  bind -x '"\C-j":__router_repl_insert_literal_newline_token'
}

read_repl_input() {
  if [[ "$USE_TOOLKIT_INPUT" -eq 1 ]]; then
    line="$(PROMPT_TOOLKIT_NO_CPR=1 "$INPUT_HELPER" --prompt "router> " --history-file "$HISTORY_FILE")"
    return $?
  fi
  if [[ -t 0 && -t 1 ]]; then
    IFS= read -e -r -p 'router> ' line
    line="${line//\\n/$'\n'}"
  else
    printf 'router> '
    IFS= read -r line
  fi
}

append_turn_log() {
  local user_msg="$1"
  local wrapper_json_file="$2"

  jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg user "$user_msg" \
    --arg host "$HOST_ALIAS" \
    --arg mode "$MODE" \
    --arg agent "$AGENT_ID" \
    --arg taskClass "$TASK_CLASS" \
    --arg thinking "$THINKING" \
    --arg routeProfile "$ROUTE_PROFILE" \
    --arg forceTier "$FORCE_TIER" \
    --arg warmup "$WARMUP_MODE" \
    --arg warmScope "$WARM_SCOPE" \
    --arg keepwarm "$KEEPWARM" \
    --argjson keepwarmIntervalSec "$KEEPWARM_INTERVAL_SEC" \
    --argjson warmTimeoutSec "$WARM_TIMEOUT_SEC" \
    --arg warmModel14b "$WARM_MODEL_14B" \
    --arg warmModel7b "$WARM_MODEL_7B" \
    --argjson result "$(cat "$wrapper_json_file")" \
    '{
      timestampUtc: $ts,
      userMessage: $user,
      settings: {
        host: $host,
        mode: $mode,
        agent: $agent,
        taskClass: $taskClass,
        thinking: $thinking,
        routeProfile: $routeProfile,
        forceTier: $forceTier,
        warmup: $warmup,
        warmScope: $warmScope,
        keepwarm: $keepwarm,
        keepwarmIntervalSec: $keepwarmIntervalSec,
        warmTimeoutSec: $warmTimeoutSec,
        warmModel14b: $warmModel14b,
        warmModel7b: $warmModel7b
      },
      result: $result
    }' >>"$JSONL_LOG"
}

cleanup_repl() {
  stop_keepwarm_loop
}
trap cleanup_repl EXIT INT TERM

echo "openclaw router repl"
print_status
print_warm_status

if [[ "$WARMUP_MODE" == "auto" ]]; then
  ensure_warm_targets "startup"
  print_warm_status
fi

if [[ "$KEEPWARM" == "on" ]]; then
  start_keepwarm_loop
fi

echo "type /help for commands"

configure_readline_input

while true; do
  read_repl_input || break

  [[ "$line" =~ [^[:space:]] ]] || continue

  if [[ "$line" != *$'\n'* ]]; then
    if [[ "$line" == "/exit" ]]; then
      break
    fi
    if [[ "$line" == "/help" ]]; then
      print_help
      continue
    fi
    if [[ "$line" == "/status" ]]; then
      print_status
      print_warm_status
      continue
    fi
    if [[ "$line" == "/warm-status" ]]; then
      print_warm_status
      continue
    fi
    if [[ "$line" == "/warm-now" ]]; then
      ensure_warm_targets "manual"
      print_warm_status
      continue
    fi
    if [[ "$line" == /keepwarm\ * ]]; then
      next="${line#"/keepwarm "}"
      if [[ "$next" == "on" ]]; then
        KEEPWARM="on"
        start_keepwarm_loop
        echo "keepwarm=${KEEPWARM}"
      elif [[ "$next" == "off" ]]; then
        KEEPWARM="off"
        stop_keepwarm_loop
        echo "keepwarm=${KEEPWARM}"
      else
        echo "invalid keepwarm value: ${next}"
      fi
      continue
    fi
    if [[ "$line" == /task\ * ]]; then
      next="${line#"/task "}"
      if [[ "$next" == "auto" || "$next" == "basic" || "$next" == "coding_basic" || "$next" == "normal" || "$next" == "high_risk" ]]; then
        TASK_CLASS="$next"
        echo "task_class=${TASK_CLASS}"
      else
        echo "invalid task class: ${next}"
      fi
      continue
    fi
    if [[ "$line" == /thinking\ * ]]; then
      next="${line#"/thinking "}"
      if [[ "$next" == "off" || "$next" == "minimal" || "$next" == "low" || "$next" == "medium" || "$next" == "high" ]]; then
        THINKING="$next"
        echo "thinking=${THINKING}"
      else
        echo "invalid thinking level: ${next}"
      fi
      continue
    fi
    if [[ "$line" == /force\ * ]]; then
      next="${line#"/force "}"
      if [[ "$next" == "off" || "$next" == "local" || "$next" == "low" || "$next" == "high" ]]; then
        FORCE_TIER="$next"
        resolve_warm_targets
        echo "force_tier=${FORCE_TIER}"
      else
        echo "invalid force tier: ${next}"
      fi
      continue
    fi
  fi

  tmp_json="$(mktemp)"
  tmp_diag="$(mktemp)"
  cmd=(
    "$WRAPPER"
    --host "$HOST_ALIAS"
    --mode "$MODE"
    --agent "$AGENT_ID"
    --task-class "$TASK_CLASS"
    --thinking "$THINKING"
    --route-profile "$ROUTE_PROFILE"
    --message "$line"
    --json
  )
  if [[ "$FORCE_TIER" != "off" ]]; then
    cmd+=(--force-tier "$FORCE_TIER")
  fi

  if "${cmd[@]}" >"$tmp_json" 2>"$tmp_diag"; then
    text="$(jq -r '.final.text // ""' "$tmp_json")"
    provider="$(jq -r '.final.provider // "unknown"' "$tmp_json")"
    model="$(jq -r '.final.model // "unknown"' "$tmp_json")"
    elapsed_ms="$(jq -r '.final.durationMs // 0' "$tmp_json")"
    backstop="$(jq -r '.backstopUsed // 0' "$tmp_json")"
    rc="$(jq -r '.final.rc // -1' "$tmp_json")"
    chain="$(jq -c '.attemptChain // []' "$tmp_json")"
    chosen_tier="$(jq -r '.chosenTier // "unknown"' "$tmp_json")"
    target_tier="$(jq -r '.targetTier // "unknown"' "$tmp_json")"
    attempt_summary="$(jq -r '[.attempts[]? | "\(.tier):\(.model):\(.durationMs)ms"] | join(",")' "$tmp_json")"
    if [[ -z "$attempt_summary" || "$attempt_summary" == "null" ]]; then
      attempt_summary="none"
    fi

    print_assistant_reply "$model" "$text"
    print_diag_block "$tmp_diag"
    if [[ "$SHOW_META" -eq 1 ]]; then
      print_diag_line "[meta] provider=${provider} model=${model} rc=${rc} elapsed_ms=${elapsed_ms} backstop=${backstop} tier=${chosen_tier}/${target_tier} chain=${chain} attempts=${attempt_summary}"
    fi
    append_turn_log "$line" "$tmp_json"
  else
    rc="$?"
    print_diag_block "$tmp_diag"
    print_diag_line "[error] wrapper failed rc=${rc}"
    if [[ -s "$tmp_json" ]]; then
      while IFS= read -r jline || [[ -n "$jline" ]]; do
        print_diag_line "$jline"
      done <"$tmp_json"
    fi
  fi
  rm -f "$tmp_json" "$tmp_diag"
done

echo "bye"
