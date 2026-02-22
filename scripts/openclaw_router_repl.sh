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
  -h, --help                  Show help

Commands inside REPL:
  /help
  /exit
  /status
  /task <type>
  /thinking <level>
  /force <local|low|high|off>
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

print_status() {
  cat <<EOF
status:
  host=${HOST_ALIAS}
  mode=${MODE}
  agent=${AGENT_ID}
  task_class=${TASK_CLASS}
  thinking=${THINKING}
  route_profile=${ROUTE_PROFILE}
  force_tier=${FORCE_TIER}
  log=${JSONL_LOG}
EOF
}

print_help() {
  cat <<'EOF'
commands:
  /help                        show this help
  /status                      show current repl settings
  /task <type>                 set task class
  /thinking <level>            set thinking override
  /force <local|low|high|off>  set force tier
  /exit                        quit
EOF
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

print_diag_line() {
  local line="$1"
  if [[ "$COLOR_ENABLED" -eq 1 ]]; then
    printf '%s%s%s\n' "$CLR_DIAG" "$line" "$CLR_RESET"
  else
    printf '%s\n' "$line"
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
  # Ctrl+J inserts a visible "\n" token so multiline intent is preserved.
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
        forceTier: $forceTier
      },
      result: $result
    }' >>"$JSONL_LOG"
}

echo "openclaw router repl"
print_status
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
