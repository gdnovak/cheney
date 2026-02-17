#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/openclaw_overnight_probe_summary.sh [options]

Options:
  --jsonl <path>         Path to probe JSONL file (default: newest overnight-probe-*.jsonl)
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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/notes/openclaw-artifacts"

if [[ -z "$JSONL_PATH" ]]; then
  JSONL_PATH="$(ls -1t "${ARTIFACTS_DIR}"/overnight-probe-*.jsonl 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$JSONL_PATH" || ! -f "$JSONL_PATH" ]]; then
  echo "No overnight probe JSONL found. Use --jsonl <path>." >&2
  exit 1
fi

if [[ -z "$OUT_MD" ]]; then
  OUT_MD="${ROOT_DIR}/notes/openclaw-overnight-probe-summary-$(date +%Y%m%d-%H%M%S).md"
fi

SUMMARY_JSON="$(jq -s '
  def p95(arr):
    (arr | length) as $n |
    if $n == 0 then 0
    else
      (arr | sort) as $s |
      (($n * 0.95 | ceil) - 1) as $idx |
      $s[if $idx < 0 then 0 else $idx end]
    end;
  (map(.wrapperElapsedMs // 0)) as $lat |
  (map(select(.provider == "openai-codex") | (.tokens // 0))) as $cloud |
  {
    count: length,
    success_count: (map(select((.ok // 0) == 1)) | length),
    failure_count: (map(select((.ok // 0) != 1)) | length),
    backstop_count: (map(select((.backstopUsed // 0) == 1)) | length),
    provider_ollama: (map(select(.provider == "ollama")) | length),
    provider_openai_codex: (map(select(.provider == "openai-codex")) | length),
    avg_wrapper_elapsed_ms: (if ($lat | length) == 0 then 0 else (($lat | add) / ($lat | length) | floor) end),
    p95_wrapper_elapsed_ms: p95($lat),
    cloud_tokens_total: (if ($cloud | length) == 0 then 0 else ($cloud | add) end),
    cloud_tokens_avg: (if ($cloud | length) == 0 then 0 else (($cloud | add) / ($cloud | length) | floor) end),
    first_timestamp: (if length == 0 then null else (map(.timestampUtc) | min) end),
    last_timestamp: (if length == 0 then null else (map(.timestampUtc) | max) end)
  }
' "$JSONL_PATH")"

count="$(jq -r '.count' <<<"$SUMMARY_JSON")"
success_count="$(jq -r '.success_count' <<<"$SUMMARY_JSON")"
failure_count="$(jq -r '.failure_count' <<<"$SUMMARY_JSON")"
backstop_count="$(jq -r '.backstop_count' <<<"$SUMMARY_JSON")"
provider_ollama="$(jq -r '.provider_ollama' <<<"$SUMMARY_JSON")"
provider_openai_codex="$(jq -r '.provider_openai_codex' <<<"$SUMMARY_JSON")"
avg_wrapper_elapsed_ms="$(jq -r '.avg_wrapper_elapsed_ms' <<<"$SUMMARY_JSON")"
p95_wrapper_elapsed_ms="$(jq -r '.p95_wrapper_elapsed_ms' <<<"$SUMMARY_JSON")"
cloud_tokens_total="$(jq -r '.cloud_tokens_total' <<<"$SUMMARY_JSON")"
cloud_tokens_avg="$(jq -r '.cloud_tokens_avg' <<<"$SUMMARY_JSON")"
first_timestamp="$(jq -r '.first_timestamp // "n/a"' <<<"$SUMMARY_JSON")"
last_timestamp="$(jq -r '.last_timestamp // "n/a"' <<<"$SUMMARY_JSON")"

error_lines="$(jq -r '
  select((.error // "") != "" or (.ok // 0) != 1) |
  "- [\(.timestampUtc)] cycle=\(.cycle) rc=\(.rc // -1) provider=\(.provider // "unknown") error=\(.error // "n/a")"
' "$JSONL_PATH" | tail -n 5)"

if [[ -z "$error_lines" ]]; then
  error_lines="- none"
fi

printf '%s\n' "jsonl=${JSONL_PATH}"
printf '%s\n' "count=${count}"
printf '%s\n' "success_count=${success_count}"
printf '%s\n' "failure_count=${failure_count}"
printf '%s\n' "backstop_count=${backstop_count}"
printf '%s\n' "provider_ollama=${provider_ollama}"
printf '%s\n' "provider_openai_codex=${provider_openai_codex}"
printf '%s\n' "avg_wrapper_elapsed_ms=${avg_wrapper_elapsed_ms}"
printf '%s\n' "p95_wrapper_elapsed_ms=${p95_wrapper_elapsed_ms}"
printf '%s\n' "cloud_tokens_total=${cloud_tokens_total}"
printf '%s\n' "cloud_tokens_avg=${cloud_tokens_avg}"
printf '%s\n' "first_timestamp=${first_timestamp}"
printf '%s\n' "last_timestamp=${last_timestamp}"
printf '%s\n' "recent_errors:"
printf '%s\n' "$error_lines"

if [[ "$WRITE_MD" -eq 1 ]]; then
  cat >"$OUT_MD" <<EOF_MD
# OpenClaw Overnight Probe Summary

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')

Source JSONL: \`${JSONL_PATH}\`

date range: ${first_timestamp} -> ${last_timestamp}

## Metrics

- count: ${count}
- success_count: ${success_count}
- failure_count: ${failure_count}
- backstop_count: ${backstop_count}
- provider_ollama: ${provider_ollama}
- provider_openai_codex: ${provider_openai_codex}
- avg_wrapper_elapsed_ms: ${avg_wrapper_elapsed_ms}
- p95_wrapper_elapsed_ms: ${p95_wrapper_elapsed_ms}
- cloud_tokens_total: ${cloud_tokens_total}
- cloud_tokens_avg: ${cloud_tokens_avg}

## Recent Errors (last 5)

${error_lines}
EOF_MD

  printf '%s\n' "markdown=${OUT_MD}"
fi
