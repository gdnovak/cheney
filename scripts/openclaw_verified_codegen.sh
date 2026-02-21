#!/usr/bin/env bash
set -euo pipefail

# Verified OpenClaw codegen/write wrapper.
# - Prevents "I saved it" style unverified side-effect claims.
# - Writes only to an allowlisted directory (default: /home/tdj).
# - Runs static safety checks and optional Codex safety review before write.
# - Logs every run and every confirmed fake claim.

usage() {
  cat <<'USAGE'
Usage:
  scripts/openclaw_verified_codegen.sh --message "<text>" [options]

Options:
  --message <text>              User task text (required)
  --target-file <path>          Explicit output file path (recommended)
  --allow-dir <path>            Allowed root directory for writes (default: /home/tdj)

  --host <alias|local>          SSH alias or local/self (default: rb1-admin)
  --mode <gateway|local>        OpenClaw mode passed through (default: gateway)
  --agent <id>                  OpenClaw agent id (default: main)
  --task-class <type>           Routing class for generation (default: coding_basic)
  --force-tier <tier>           Optional generation tier override local|low|high

  --no-codex-review             Skip Codex safety review for code-like files
  --strict-codex-review         Block write if Codex review cannot be parsed
  --no-correction               Do not send corrective feedback when fake output is detected

  --events-log <path>           Verified action JSONL log
  --incident-log <path>         Confirmed fake-output incident JSONL log
  --json                        Print machine-readable run result
  -h, --help                    Show help

Examples:
  scripts/openclaw_verified_codegen.sh \
    --message "Write a 3-option CLI menu in python" \
    --target-file /home/tdj/feb21-testMenu.py
USAGE
}

MESSAGE=""
TARGET_FILE=""
ALLOW_DIR="/home/tdj"

HOST_ALIAS="rb1-admin"
MODE="gateway"
AGENT_ID="main"
TASK_CLASS="coding_basic"
FORCE_TIER=""

ENABLE_CODEX_REVIEW=1
STRICT_CODEX_REVIEW=0
ENABLE_CORRECTION=1

EVENTS_LOG=""
INCIDENT_LOG=""
OUTPUT_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --message)
      MESSAGE="${2:-}"
      shift 2
      ;;
    --target-file)
      TARGET_FILE="${2:-}"
      shift 2
      ;;
    --allow-dir)
      ALLOW_DIR="${2:-}"
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
    --task-class)
      TASK_CLASS="${2:-}"
      shift 2
      ;;
    --force-tier)
      FORCE_TIER="${2:-}"
      shift 2
      ;;
    --no-codex-review)
      ENABLE_CODEX_REVIEW=0
      shift
      ;;
    --strict-codex-review)
      STRICT_CODEX_REVIEW=1
      shift
      ;;
    --no-correction)
      ENABLE_CORRECTION=0
      shift
      ;;
    --events-log)
      EVENTS_LOG="${2:-}"
      shift 2
      ;;
    --incident-log)
      INCIDENT_LOG="${2:-}"
      shift 2
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

if [[ -n "$FORCE_TIER" && "$FORCE_TIER" != "local" && "$FORCE_TIER" != "low" && "$FORCE_TIER" != "high" ]]; then
  echo "--force-tier must be local|low|high" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"
mkdir -p "$ARTIFACTS_DIR"

if [[ -z "$EVENTS_LOG" ]]; then
  EVENTS_LOG="${ARTIFACTS_DIR}/openclaw-verified-actions.jsonl"
fi
if [[ -z "$INCIDENT_LOG" ]]; then
  INCIDENT_LOG="${ARTIFACTS_DIR}/openclaw-fake-output-incidents.jsonl"
fi
mkdir -p "$(dirname "$EVENTS_LOG")" "$(dirname "$INCIDENT_LOG")"

TS_STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="${ARTIFACTS_DIR}/openclaw-verified-codegen-${TS_STAMP}.log"
RUN_JSON="${ARTIFACTS_DIR}/openclaw-verified-codegen-${TS_STAMP}.json"
SAFE_TURN_JSON="${ARTIFACTS_DIR}/openclaw-verified-codegen-turn-${TS_STAMP}.json"
CODEX_REVIEW_JSON="${ARTIFACTS_DIR}/openclaw-verified-codegen-codex-review-${TS_STAMP}.json"

RAW_TEXT_FILE="$(mktemp)"
ATTEMPTS_TEXT_FILE="$(mktemp)"
PARSED_JSON_FILE="$(mktemp)"
CONTENT_FILE="$(mktemp)"

ACTION="respond_only"
RESOLVED_PATH=""
LANGUAGE="text"
WRITE_ATTEMPTED=0
WRITE_VERIFIED=0
WRITE_BLOCKED=0
BLOCK_REASON=""
STATIC_SAFE=1
STATIC_REASON=""
CODEX_REVIEW_STATUS="not_run"
CODEX_ALLOW="unknown"
CODEX_REASON=""
CLAIM_WRITE=0
CLAIM_RUN=0
CLAIM_REASON=""
CLAIM_SOURCE=""
FAKE_DETECTED=0
FAKE_REASON=""
CORRECTION_SENT=0
PARSE_OK=0
FALLBACK_CODEBLOCK_USED=0
REMOTE_SHA256=""
LOCAL_SHA256=""
REMOTE_HOME=""
ALLOW_CANON=""
TARGET_CANON=""
FINAL_TEXT=""
PROVIDER=""
MODEL=""
SAFE_TURN_RC=0

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

ssh_put_file() {
  local src="$1"
  local dst="$2"
  local dst_quoted
  dst_quoted="$(printf '%q' "$dst")"
  if [[ "$HOST_ALIAS" == "local" || "$HOST_ALIAS" == "localhost" || "$HOST_ALIAS" == "self" ]]; then
    cat "$src" >"$dst"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=8 "$HOST_ALIAS" "cat > ${dst_quoted}" <"$src"
  fi
}

cleanup() {
  local rc=$?
  rm -f "$RAW_TEXT_FILE" "$ATTEMPTS_TEXT_FILE" "$PARSED_JSON_FILE" "$CONTENT_FILE"
  exit "$rc"
}
trap cleanup EXIT

extract_json_from_text_file() {
  local input_file="$1"
  local output_file="$2"
  python3 - "$input_file" "$output_file" <<'PY'
import json
import re
import sys

in_path, out_path = sys.argv[1], sys.argv[2]
text = open(in_path, "r", encoding="utf-8", errors="replace").read().strip()

candidates = []
if text:
    candidates.append(text)

for m in re.finditer(r"```(?:json)?\s*(\{.*?\})\s*```", text, flags=re.S | re.I):
    candidates.append(m.group(1))

# Balanced-brace extraction
starts = [i for i, ch in enumerate(text) if ch == "{"]
for s in starts:
    depth = 0
    in_str = False
    esc = False
    for i in range(s, len(text)):
        ch = text[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                candidates.append(text[s:i+1])
                break

for cand in candidates:
    try:
        obj = json.loads(cand)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(obj, f, ensure_ascii=False)
        sys.exit(0)
    except Exception:
        pass

sys.exit(1)
PY
}

extract_first_code_block() {
  local input_file="$1"
  local output_file="$2"
  python3 - "$input_file" "$output_file" <<'PY'
import re
import sys

in_path, out_path = sys.argv[1], sys.argv[2]
text = open(in_path, "r", encoding="utf-8", errors="replace").read()
m = re.search(r"```(?:[a-zA-Z0-9_+-]+)?\s*\n(.*?)```", text, flags=re.S)
if not m:
    sys.exit(1)
code = m.group(1)
with open(out_path, "w", encoding="utf-8") as f:
    f.write(code)
sys.exit(0)
PY
}

detect_claims() {
  local input_file="$1"
  python3 - "$input_file" <<'PY'
import re
import sys

text = open(sys.argv[1], "r", encoding="utf-8", errors="replace").read()
text_l = text.lower()

write_patterns = [
    r"\bi (?:have )?(?:saved|created|wrote|written)\b",
    r"\bfile (?:has been )?saved\b",
    r"\bi saved (?:this|that|the) (?:script|file)\b",
    r"\bi have saved\b",
]
run_patterns = [
    r"\bi (?:have )?(?:ran|run|executed)\b",
    r"\bcommand (?:was )?(?:run|executed)\b",
]

claim_write = any(re.search(p, text_l) for p in write_patterns)
claim_run = any(re.search(p, text_l) for p in run_patterns)

reasons = []
if claim_write:
    reasons.append("claimed_write")
if claim_run:
    reasons.append("claimed_run")

print(f"{int(claim_write)} {int(claim_run)} {','.join(reasons)}")
PY
}

is_code_like_path() {
  local p="$1"
  case "${p,,}" in
    *.py|*.sh|*.bash|*.zsh|*.js|*.ts|*.tsx|*.jsx|*.go|*.rs|*.c|*.cc|*.cpp|*.h|*.hpp|*.java|*.rb|*.php|*.pl)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

static_safety_check() {
  local file="$1"
  python3 - "$file" <<'PY'
import re
import sys

text = open(sys.argv[1], "r", encoding="utf-8", errors="replace").read().lower()
patterns = [
    (r"rm\s+-rf\s+/", "dangerous_delete_root"),
    (r"mkfs\.", "filesystem_format"),
    (r"\bdd\s+if=", "raw_disk_write"),
    (r"\b(?:shutdown|poweroff|reboot)\b", "system_power_action"),
    (r":\(\)\s*{\s*:\s*\|\s*:\s*;\s*}\s*;\s*:", "fork_bomb"),
    (r"(curl|wget)[^\\n|;]*\|\s*(sh|bash)", "remote_pipe_shell"),
    (r"\biptables\b|\bnft\b", "firewall_mutation"),
    (r"\bsystemctl\s+(?:stop|disable)\b", "service_disable"),
]
for pattern, reason in patterns:
    if re.search(pattern, text):
        print(reason)
        sys.exit(1)
print("ok")
sys.exit(0)
PY
}

resolve_remote_path() {
  local candidate="$1"
  if [[ -z "$candidate" ]]; then
    return 1
  fi
  if [[ "$candidate" != /* ]]; then
    candidate="${ALLOW_DIR%/}/${candidate}"
  fi
  ssh_host "readlink -m $(printf '%q' "$candidate")"
}

send_correction() {
  local reason="$1"
  local detail="$2"
  local local_flag=""
  local correction

  if [[ "$MODE" == "local" ]]; then
    local_flag="--local"
  fi

  correction="Behavior correction (truth guard): You made an unverified side-effect claim (${reason}). Evidence: ${detail}. Never claim a file was saved/created/run unless it is verified by tool output. When uncertain, state uncertainty and provide only proposed content."
  if ssh_host "openclaw agent ${local_flag} --agent $(printf '%q' "$AGENT_ID") --message $(printf '%q' "$correction") --json >/dev/null"; then
    CORRECTION_SENT=1
  fi
}

log "Host=${HOST_ALIAS} mode=${MODE} agent=${AGENT_ID} task_class=${TASK_CLASS}"

REMOTE_HOME="$(ssh_host "printf '%s' \"\$HOME\"")"
ALLOW_CANON="$(ssh_host "readlink -m $(printf '%q' "$ALLOW_DIR")")"
log "Remote home=${REMOTE_HOME} allow_dir=${ALLOW_CANON}"

prompt_contract="$(cat <<EOF
You are operating under a strict truth contract.
Important rules:
1) You do NOT execute commands and do NOT write files directly.
2) Never claim you already saved/created/ran anything.
3) Return ONLY valid JSON (no markdown fences).

Required JSON schema:
{
  "action": "create_file" | "respond_only",
  "path": "target path for file writes (string, optional for respond_only)",
  "language": "python|bash|text|...",
  "content": "full file content when action=create_file",
  "message": "brief operator note"
}

If the user request is to create/write a file, set action=create_file and include full content.
If a target path is explicitly provided below, use exactly that path.

Target path hint: ${TARGET_FILE:-"(none provided)"}
User request:
${MESSAGE}
EOF
)"

safe_turn_cmd=(scripts/openclaw_agent_safe_turn.sh
  --host "$HOST_ALIAS"
  --mode "$MODE"
  --agent "$AGENT_ID"
  --task-class "$TASK_CLASS"
  --json
  --message "$prompt_contract")

if [[ -n "$FORCE_TIER" ]]; then
  safe_turn_cmd+=(--force-tier "$FORCE_TIER")
fi

if ! (cd "$ROOT_DIR" && "${safe_turn_cmd[@]}") >"$SAFE_TURN_JSON"; then
  SAFE_TURN_RC=$?
fi

FINAL_TEXT="$(jq -r '.final.text // ""' "$SAFE_TURN_JSON" 2>/dev/null || true)"
PROVIDER="$(jq -r '.final.provider // "unknown"' "$SAFE_TURN_JSON" 2>/dev/null || echo "unknown")"
MODEL="$(jq -r '.final.model // "unknown"' "$SAFE_TURN_JSON" 2>/dev/null || echo "unknown")"
printf '%s' "$FINAL_TEXT" >"$RAW_TEXT_FILE"
jq -r '.attempts[]?.text // empty' "$SAFE_TURN_JSON" >"$ATTEMPTS_TEXT_FILE" 2>/dev/null || true

read -r CLAIM_WRITE_FINAL CLAIM_RUN_FINAL CLAIM_REASON_FINAL <<<"$(detect_claims "$RAW_TEXT_FILE")"
read -r CLAIM_WRITE_ATTEMPTS CLAIM_RUN_ATTEMPTS CLAIM_REASON_ATTEMPTS <<<"$(detect_claims "$ATTEMPTS_TEXT_FILE")"

if [[ "$CLAIM_WRITE_FINAL" -eq 1 || "$CLAIM_WRITE_ATTEMPTS" -eq 1 ]]; then
  CLAIM_WRITE=1
fi
if [[ "$CLAIM_RUN_FINAL" -eq 1 || "$CLAIM_RUN_ATTEMPTS" -eq 1 ]]; then
  CLAIM_RUN=1
fi

if [[ "$CLAIM_WRITE_FINAL" -eq 1 || "$CLAIM_RUN_FINAL" -eq 1 ]]; then
  CLAIM_SOURCE="final"
fi
if [[ "$CLAIM_WRITE_ATTEMPTS" -eq 1 || "$CLAIM_RUN_ATTEMPTS" -eq 1 ]]; then
  if [[ -n "$CLAIM_SOURCE" ]]; then
    CLAIM_SOURCE="both"
  else
    CLAIM_SOURCE="attempt"
  fi
fi

CLAIM_REASON=""
if [[ "$CLAIM_SOURCE" == "final" ]]; then
  CLAIM_REASON="$CLAIM_REASON_FINAL"
elif [[ "$CLAIM_SOURCE" == "attempt" ]]; then
  CLAIM_REASON="attempt_only:${CLAIM_REASON_ATTEMPTS}"
elif [[ "$CLAIM_SOURCE" == "both" ]]; then
  CLAIM_REASON="final:${CLAIM_REASON_FINAL},attempt:${CLAIM_REASON_ATTEMPTS}"
fi

if extract_json_from_text_file "$RAW_TEXT_FILE" "$PARSED_JSON_FILE"; then
  PARSE_OK=1
  ACTION="$(jq -r '.action // "respond_only"' "$PARSED_JSON_FILE")"
  LANGUAGE="$(jq -r '.language // "text"' "$PARSED_JSON_FILE")"
  json_path="$(jq -r '.path // ""' "$PARSED_JSON_FILE")"
  json_content="$(jq -r '.content // ""' "$PARSED_JSON_FILE")"
  if [[ -n "$json_content" ]]; then
    printf '%s' "$json_content" >"$CONTENT_FILE"
  fi
  if [[ -n "$TARGET_FILE" ]]; then
    RESOLVED_PATH="$TARGET_FILE"
  else
    RESOLVED_PATH="$json_path"
  fi
else
  ACTION="respond_only"
  LANGUAGE="text"
  if [[ -n "$TARGET_FILE" ]] && extract_first_code_block "$RAW_TEXT_FILE" "$CONTENT_FILE"; then
    ACTION="create_file"
    RESOLVED_PATH="$TARGET_FILE"
    FALLBACK_CODEBLOCK_USED=1
    PARSE_OK=0
  fi
fi

if [[ "$ACTION" == "create_file" ]]; then
  WRITE_ATTEMPTED=1
  if [[ -z "$RESOLVED_PATH" ]]; then
    WRITE_BLOCKED=1
    BLOCK_REASON="missing_target_path"
  else
    TARGET_CANON="$(resolve_remote_path "$RESOLVED_PATH")"
    if [[ -z "$TARGET_CANON" ]]; then
      WRITE_BLOCKED=1
      BLOCK_REASON="path_resolution_failed"
    elif [[ "$TARGET_CANON" != "$ALLOW_CANON" && "$TARGET_CANON" != "$ALLOW_CANON/"* ]]; then
      WRITE_BLOCKED=1
      BLOCK_REASON="path_outside_allow_dir"
    elif [[ ! -s "$CONTENT_FILE" ]]; then
      WRITE_BLOCKED=1
      BLOCK_REASON="missing_or_empty_content"
    else
      if static_reason="$(static_safety_check "$CONTENT_FILE" 2>/dev/null)"; then
        STATIC_SAFE=1
        STATIC_REASON="${static_reason:-ok}"
      else
        STATIC_SAFE=0
        STATIC_REASON="${static_reason:-static_check_failed}"
        WRITE_BLOCKED=1
        BLOCK_REASON="static_safety_block:${STATIC_REASON}"
      fi

      if [[ "$WRITE_BLOCKED" -eq 0 && "$ENABLE_CODEX_REVIEW" -eq 1 ]] && is_code_like_path "$TARGET_CANON"; then
        CODEX_REVIEW_STATUS="attempted"
        file_b64="$(base64 -w0 <"$CONTENT_FILE")"
        codex_prompt="$(cat <<EOF
Safety gate review. Return JSON only:
{"allow":true|false,"risk":"low|medium|high","reason":"..."}

Target path: ${TARGET_CANON}
Content base64:
${file_b64}
EOF
)"
        if (cd "$ROOT_DIR" && scripts/openclaw_agent_safe_turn.sh \
          --host "$HOST_ALIAS" \
          --mode "$MODE" \
          --agent "$AGENT_ID" \
          --task-class high_risk \
          --force-tier high \
          --json \
          --message "$codex_prompt") >"$CODEX_REVIEW_JSON"; then
          codex_text="$(jq -r '.final.text // ""' "$CODEX_REVIEW_JSON" 2>/dev/null || true)"
          printf '%s' "$codex_text" >"${CODEX_REVIEW_JSON}.txt"
          if extract_json_from_text_file "${CODEX_REVIEW_JSON}.txt" "${CODEX_REVIEW_JSON}.parsed"; then
            CODEX_REVIEW_STATUS="parsed"
            CODEX_ALLOW="$(jq -r '.allow // "false"' "${CODEX_REVIEW_JSON}.parsed")"
            CODEX_REASON="$(jq -r '.reason // ""' "${CODEX_REVIEW_JSON}.parsed")"
            if [[ "$CODEX_ALLOW" != "true" ]]; then
              WRITE_BLOCKED=1
              BLOCK_REASON="codex_safety_block:${CODEX_REASON:-denied}"
            fi
          else
            CODEX_REVIEW_STATUS="unparsed"
            CODEX_ALLOW="unknown"
            CODEX_REASON="unparseable_review_response"
            if [[ "$STRICT_CODEX_REVIEW" -eq 1 ]]; then
              WRITE_BLOCKED=1
              BLOCK_REASON="strict_codex_review_unparsed"
            fi
          fi
        else
          CODEX_REVIEW_STATUS="error"
          CODEX_ALLOW="unknown"
          CODEX_REASON="review_call_failed"
          if [[ "$STRICT_CODEX_REVIEW" -eq 1 ]]; then
            WRITE_BLOCKED=1
            BLOCK_REASON="strict_codex_review_error"
          fi
        fi
      fi

      if [[ "$WRITE_BLOCKED" -eq 0 ]]; then
        remote_dir="$(dirname "$TARGET_CANON")"
        ssh_host "mkdir -p $(printf '%q' "$remote_dir")"
        ssh_put_file "$CONTENT_FILE" "$TARGET_CANON"
        ssh_host "chmod 0644 $(printf '%q' "$TARGET_CANON")"

        LOCAL_SHA256="$(sha256sum "$CONTENT_FILE" | awk '{print $1}')"
        REMOTE_SHA256="$(ssh_host "sha256sum $(printf '%q' "$TARGET_CANON") | cut -d ' ' -f1")"
        if [[ -n "$LOCAL_SHA256" && "$LOCAL_SHA256" == "$REMOTE_SHA256" ]]; then
          WRITE_VERIFIED=1
        else
          WRITE_BLOCKED=1
          BLOCK_REASON="sha256_mismatch_or_missing"
        fi

        case "${TARGET_CANON,,}" in
          *.py)
            ssh_host "python3 -m py_compile $(printf '%q' "$TARGET_CANON")" >>"$RUN_LOG" 2>&1 || true
            ;;
          *.sh|*.bash|*.zsh)
            ssh_host "bash -n $(printf '%q' "$TARGET_CANON")" >>"$RUN_LOG" 2>&1 || true
            ;;
        esac
      fi
    fi
  fi
fi

# Fake-output classification:
# - Any side-effect claim without verified evidence.
if [[ "$CLAIM_WRITE" -eq 1 && "$WRITE_VERIFIED" -ne 1 ]]; then
  FAKE_DETECTED=1
  FAKE_REASON="claimed_write_without_verified_write"
fi
if [[ "$CLAIM_RUN" -eq 1 ]]; then
  FAKE_DETECTED=1
  if [[ -n "$FAKE_REASON" ]]; then
    FAKE_REASON="${FAKE_REASON},claimed_run_without_execution_evidence"
  else
    FAKE_REASON="claimed_run_without_execution_evidence"
  fi
fi
if [[ "$ACTION" == "create_file" && "$WRITE_VERIFIED" -ne 1 ]]; then
  FAKE_DETECTED=1
  if [[ -n "$FAKE_REASON" ]]; then
    FAKE_REASON="${FAKE_REASON},create_file_unverified"
  else
    FAKE_REASON="create_file_unverified"
  fi
fi

if [[ "$FAKE_DETECTED" -eq 1 ]]; then
  incident_row="$(jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg host "$HOST_ALIAS" \
    --arg mode "$MODE" \
    --arg agent "$AGENT_ID" \
    --arg provider "$PROVIDER" \
    --arg model "$MODEL" \
    --arg reason "$FAKE_REASON" \
    --arg claimReason "$CLAIM_REASON" \
    --arg path "$TARGET_CANON" \
    --arg runJson "$RUN_JSON" \
    --arg turnJson "$SAFE_TURN_JSON" \
    --arg text "$(printf '%s' "$FINAL_TEXT" | tr '\n' ' ' | cut -c1-320)" \
    '{
      timestampUtc: $ts,
      host: $host,
      mode: $mode,
      agent: $agent,
      provider: $provider,
      model: $model,
      reason: $reason,
      claimReason: (if $claimReason == "" then null else $claimReason end),
      targetPath: (if $path == "" then null else $path end),
      evidenceTextExcerpt: $text,
      runJson: $runJson,
      sourceTurnJson: $turnJson
    }')"
  printf '%s\n' "$incident_row" >>"$INCIDENT_LOG"

  if [[ "$ENABLE_CORRECTION" -eq 1 ]]; then
    send_correction "$FAKE_REASON" "incident_log=$(basename "$INCIDENT_LOG")"
  fi
fi

result_row="$(jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg host "$HOST_ALIAS" \
  --arg mode "$MODE" \
  --arg agent "$AGENT_ID" \
  --arg provider "$PROVIDER" \
  --arg model "$MODEL" \
  --arg message "$MESSAGE" \
  --arg action "$ACTION" \
  --arg language "$LANGUAGE" \
  --arg targetPath "$TARGET_CANON" \
  --arg blockReason "$BLOCK_REASON" \
  --arg staticReason "$STATIC_REASON" \
  --arg codexReviewStatus "$CODEX_REVIEW_STATUS" \
  --arg codexAllow "$CODEX_ALLOW" \
  --arg codexReason "$CODEX_REASON" \
  --arg claimReason "$CLAIM_REASON" \
  --arg claimSource "$CLAIM_SOURCE" \
  --arg localSha256 "$LOCAL_SHA256" \
  --arg remoteSha256 "$REMOTE_SHA256" \
  --arg turnJson "$SAFE_TURN_JSON" \
  --arg runLog "$RUN_LOG" \
  --arg incidentLog "$INCIDENT_LOG" \
  --arg eventsLog "$EVENTS_LOG" \
  --arg finalText "$(printf '%s' "$FINAL_TEXT" | tr '\n' ' ' | cut -c1-320)" \
  --argjson parseOk "$PARSE_OK" \
  --argjson fallbackCodeblockUsed "$FALLBACK_CODEBLOCK_USED" \
  --argjson writeAttempted "$WRITE_ATTEMPTED" \
  --argjson writeVerified "$WRITE_VERIFIED" \
  --argjson writeBlocked "$WRITE_BLOCKED" \
  --argjson staticSafe "$STATIC_SAFE" \
  --argjson claimWrite "$CLAIM_WRITE" \
  --argjson claimRun "$CLAIM_RUN" \
  --argjson fakeDetected "$FAKE_DETECTED" \
  --argjson correctionSent "$CORRECTION_SENT" \
  --argjson safeTurnRc "$SAFE_TURN_RC" \
  '{
    timestampUtc: $ts,
    host: $host,
    mode: $mode,
    agent: $agent,
    provider: $provider,
    model: $model,
    message: $message,
    action: $action,
    language: $language,
    targetPath: (if $targetPath == "" then null else $targetPath end),
    parseOk: $parseOk,
    fallbackCodeblockUsed: ($fallbackCodeblockUsed == 1),
    writeAttempted: ($writeAttempted == 1),
    writeVerified: ($writeVerified == 1),
    writeBlocked: ($writeBlocked == 1),
    blockReason: (if $blockReason == "" then null else $blockReason end),
    staticSafe: ($staticSafe == 1),
    staticReason: (if $staticReason == "" then null else $staticReason end),
    codexReviewStatus: $codexReviewStatus,
    codexAllow: $codexAllow,
    codexReason: (if $codexReason == "" then null else $codexReason end),
    claimWrite: ($claimWrite == 1),
    claimRun: ($claimRun == 1),
    claimSource: (if $claimSource == "" then null else $claimSource end),
    claimReason: (if $claimReason == "" then null else $claimReason end),
    fakeDetected: ($fakeDetected == 1),
    correctionSent: ($correctionSent == 1),
    safeTurnRc: $safeTurnRc,
    localSha256: (if $localSha256 == "" then null else $localSha256 end),
    remoteSha256: (if $remoteSha256 == "" then null else $remoteSha256 end),
    finalTextExcerpt: $finalText,
    sourceTurnJson: $turnJson,
    runLog: $runLog,
    eventsLog: $eventsLog,
    incidentLog: $incidentLog
  }')"

printf '%s\n' "$result_row" >"$RUN_JSON"
printf '%s\n' "$result_row" >>"$EVENTS_LOG"

if [[ "$OUTPUT_JSON" -eq 1 ]]; then
  cat "$RUN_JSON"
else
  jq -r '
    "action=\(.action)",
    "parse_ok=\(.parseOk)",
    "write_attempted=\(.writeAttempted)",
    "write_verified=\(.writeVerified)",
    "write_blocked=\(.writeBlocked)",
    "target_path=\(.targetPath // "n/a")",
    "fake_detected=\(.fakeDetected)",
    "correction_sent=\(.correctionSent)",
    "provider=\(.provider)",
    "model=\(.model)",
    "run_json='"$RUN_JSON"'"
  ' "$RUN_JSON"
fi
