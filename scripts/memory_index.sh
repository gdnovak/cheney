#!/usr/bin/env bash
set -euo pipefail

# Build a lightweight lexical index snapshot for memory notes.

ROOT_DIR="${1:-memory}"

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "Directory not found: $ROOT_DIR" >&2
  exit 1
fi

printf 'id\tpath\ttype\ttags\tout_links\n'

while IFS= read -r file; do
  id="$(awk -F': ' '/^id:/{print $2; exit}' "$file")"
  type="$(awk -F': ' '/^type:/{print $2; exit}' "$file")"
  tags="$(awk -F': ' '/^tags:/{print $2; exit}' "$file")"
  out_links="$(grep -o '\[\[[^]]\+\]\]' "$file" 2>/dev/null | wc -l | tr -d ' ')"
  printf '%s\t%s\t%s\t%s\t%s\n' "${id:-}" "$file" "${type:-}" "${tags:-}" "${out_links:-0}"
done < <(find "$ROOT_DIR" -type f -name '*.md' | sort)
