#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-/home/tdj/cheney}"
OUT_PATH="${2:-$REPO_ROOT/notes/cognee/cognee-scope-manifest.txt}"

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Repo path not found: $REPO_ROOT" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_PATH")"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

(
  cd "$REPO_ROOT"
  [[ -f README.md ]] && echo "README.md"
  [[ -f log.md ]] && echo "log.md"
  for d in memory runbooks inventory notes; do
    [[ -d "$d" ]] || continue
    find "$d" -type f -name '*.md' -print
  done
) | sort -u >"$tmp"

awk '
/\/openclaw-artifacts\// {next}
/\/ollama-artifacts\// {next}
/\/archive\// {next}
/\/rb1-recovery-artifacts\// {next}
/\/egpu-acceptance-artifacts\// {next}
/\/rb1-nic-cutover-.*\/.*\.txt$/ {next}
/\/rb1-nic-cutover-.*\/.*\.log$/ {next}
/\/rb1-nic-cutover-.*\/.*\.csv$/ {next}
/\/.*\.jsonl$/ {next}
/\/.*\.log$/ {next}
/\/.*\.pid$/ {next}
/\/.*\.out$/ {next}
{print}
' "$tmp" >"$OUT_PATH"

count="$(wc -l <"$OUT_PATH" | tr -d ' ')"
echo "Manifest written: $OUT_PATH"
echo "Included markdown files: $count"
