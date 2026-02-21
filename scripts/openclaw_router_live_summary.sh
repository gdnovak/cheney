#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/openclaw_router_live_summary.sh [options]

Options:
  --jsonl <path>         Router decisions JSONL path
                         (default: notes/openclaw-artifacts/openclaw-router-decisions.jsonl)
  --no-md                Do not write markdown summary file
  --output-md <path>     Explicit markdown output path
  -h, --help             Show help
USAGE
}

JSONL_PATH=""
WRITE_MD=1
OUT_MD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jsonl)
      JSONL_PATH="${2:-}"
      shift 2
      ;;
    --no-md)
      WRITE_MD=0
      shift
      ;;
    --output-md)
      OUT_MD="${2:-}"
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

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"

if [[ -z "$JSONL_PATH" ]]; then
  JSONL_PATH="${ARTIFACTS_DIR}/openclaw-router-decisions.jsonl"
fi

if [[ ! -f "$JSONL_PATH" ]]; then
  echo "Router JSONL not found: $JSONL_PATH" >&2
  exit 1
fi

if [[ -z "$OUT_MD" ]]; then
  OUT_MD="${ROOT_DIR}/notes/openclaw-router-live-summary-$(date +%Y%m%d-%H%M%S).md"
fi

SUMMARY_JSON="$(jq -s '
  def pctl(a; q):
    (a|length) as $n |
    if $n == 0 then 0
    else
      (a|sort) as $s |
      (($n * q | ceil) - 1) as $i |
      $s[(if $i < 0 then 0 else $i end)]
    end;

  . as $rows |
  ($rows|map(.elapsedMs // 0)) as $lat |
  ($rows|map(.tokensTotal // 0)) as $tok |
  {
    count: ($rows|length),
    success_count: ($rows|map(select((.rc // 1) == 0 and (.sanityOk // 0) == 1))|length),
    failure_count: ($rows|map(select((.rc // 1) != 0 or (.sanityOk // 0) != 1))|length),
    backstop_count: ($rows|map(select((.backstopUsed // 0) == 1))|length),
    avg_elapsed_ms: (if ($lat|length)==0 then 0 else (($lat|add)/($lat|length)|floor) end),
    p50_elapsed_ms: pctl($lat; 0.50),
    p90_elapsed_ms: pctl($lat; 0.90),
    p95_elapsed_ms: pctl($lat; 0.95),
    avg_tokens: (if ($tok|length)==0 then 0 else (($tok|add)/($tok|length)|floor) end),
    total_tokens: (if ($tok|length)==0 then 0 else ($tok|add) end),
    first_timestamp: (if ($rows|length)==0 then null else ($rows|map(.timestampUtc)|min) end),
    last_timestamp: (if ($rows|length)==0 then null else ($rows|map(.timestampUtc)|max) end),
    by_tier: (
      $rows
      | group_by(.chosenTier)
      | map({tier:(.[0].chosenTier // "unknown"), count:length})
    ),
    by_task_class: (
      $rows
      | group_by(.taskClass)
      | map({taskClass:(.[0].taskClass // "unknown"), count:length})
    ),
    by_final_model: (
      $rows
      | group_by(.finalModel)
      | map({model:(.[0].finalModel // "unknown"), count:length, avg_elapsed_ms:((map(.elapsedMs // 0)|add)/length|floor)})
    ),
    escalation_reasons: (
      $rows
      | map(.escalationReason)
      | map(select(. != null and . != ""))
      | group_by(.)
      | map({reason: .[0], count: length})
    )
  }
' "$JSONL_PATH")"

count="$(jq -r '.count' <<<"$SUMMARY_JSON")"
success_count="$(jq -r '.success_count' <<<"$SUMMARY_JSON")"
failure_count="$(jq -r '.failure_count' <<<"$SUMMARY_JSON")"
backstop_count="$(jq -r '.backstop_count' <<<"$SUMMARY_JSON")"
avg_elapsed_ms="$(jq -r '.avg_elapsed_ms' <<<"$SUMMARY_JSON")"
p50_elapsed_ms="$(jq -r '.p50_elapsed_ms' <<<"$SUMMARY_JSON")"
p90_elapsed_ms="$(jq -r '.p90_elapsed_ms' <<<"$SUMMARY_JSON")"
p95_elapsed_ms="$(jq -r '.p95_elapsed_ms' <<<"$SUMMARY_JSON")"
avg_tokens="$(jq -r '.avg_tokens' <<<"$SUMMARY_JSON")"
total_tokens="$(jq -r '.total_tokens' <<<"$SUMMARY_JSON")"
first_timestamp="$(jq -r '.first_timestamp // "n/a"' <<<"$SUMMARY_JSON")"
last_timestamp="$(jq -r '.last_timestamp // "n/a"' <<<"$SUMMARY_JSON")"

by_tier_lines="$(jq -r '.by_tier[]? | "- \(.tier): \(.count)"' <<<"$SUMMARY_JSON")"
by_task_lines="$(jq -r '.by_task_class[]? | "- \(.taskClass): \(.count)"' <<<"$SUMMARY_JSON")"
by_model_lines="$(jq -r '.by_final_model[]? | "- \(.model): count=\(.count), avg_elapsed_ms=\(.avg_elapsed_ms)"' <<<"$SUMMARY_JSON")"
escalation_lines="$(jq -r '.escalation_reasons[]? | "- \(.reason): \(.count)"' <<<"$SUMMARY_JSON")"

[[ -n "${by_tier_lines:-}" ]] || by_tier_lines="- none"
[[ -n "${by_task_lines:-}" ]] || by_task_lines="- none"
[[ -n "${by_model_lines:-}" ]] || by_model_lines="- none"
[[ -n "${escalation_lines:-}" ]] || escalation_lines="- none"

printf '%s\n' "jsonl=${JSONL_PATH}"
printf '%s\n' "count=${count}"
printf '%s\n' "success_count=${success_count}"
printf '%s\n' "failure_count=${failure_count}"
printf '%s\n' "backstop_count=${backstop_count}"
printf '%s\n' "avg_elapsed_ms=${avg_elapsed_ms}"
printf '%s\n' "p50_elapsed_ms=${p50_elapsed_ms}"
printf '%s\n' "p90_elapsed_ms=${p90_elapsed_ms}"
printf '%s\n' "p95_elapsed_ms=${p95_elapsed_ms}"
printf '%s\n' "avg_tokens=${avg_tokens}"
printf '%s\n' "total_tokens=${total_tokens}"
printf '%s\n' "first_timestamp=${first_timestamp}"
printf '%s\n' "last_timestamp=${last_timestamp}"
printf '%s\n' "by_tier:"
printf '%s\n' "$by_tier_lines"
printf '%s\n' "by_task_class:"
printf '%s\n' "$by_task_lines"
printf '%s\n' "by_final_model:"
printf '%s\n' "$by_model_lines"
printf '%s\n' "escalation_reasons:"
printf '%s\n' "$escalation_lines"

if [[ "$WRITE_MD" -eq 1 ]]; then
  cat >"$OUT_MD" <<EOF_MD
# OpenClaw Router Live Summary

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')

Source JSONL: ${JSONL_PATH}

Date range: ${first_timestamp} -> ${last_timestamp}

## Core Metrics

- count: ${count}
- success_count: ${success_count}
- failure_count: ${failure_count}
- backstop_count: ${backstop_count}
- avg_elapsed_ms: ${avg_elapsed_ms}
- p50_elapsed_ms: ${p50_elapsed_ms}
- p90_elapsed_ms: ${p90_elapsed_ms}
- p95_elapsed_ms: ${p95_elapsed_ms}
- avg_tokens: ${avg_tokens}
- total_tokens: ${total_tokens}

## By Tier

${by_tier_lines}

## By Task Class

${by_task_lines}

## By Final Model

${by_model_lines}

## Escalation Reasons

${escalation_lines}
EOF_MD

  printf '%s\n' "markdown=${OUT_MD}"
fi
