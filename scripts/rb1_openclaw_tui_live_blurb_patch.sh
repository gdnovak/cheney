#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-rb1-admin}"
MARKER="CHENEY_TUI_LIVE_BLURB_V1"
BACKUP_SUFFIX=".cheney-live-blurb-v1.bak"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSFORM_SCRIPT="$SCRIPT_DIR/openclaw_tui_live_blurb_transform.mjs"

FILES=(
  "/usr/local/lib/node_modules/openclaw/dist/tui-DW-D2_SI.js"
  "/usr/local/lib/node_modules/openclaw/dist/tui-CRTpgJsf.js"
)

if [[ ! -f "$TRANSFORM_SCRIPT" ]]; then
  echo "Missing transformer: $TRANSFORM_SCRIPT" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Target host: $HOST"
echo "Patch marker: $MARKER"

for file in "${FILES[@]}"; do
  base="$(basename "$file")"
  src="$tmpdir/$base.orig.js"
  dst="$tmpdir/$base.patched.js"
  meta="$tmpdir/$base.transform.json"

  echo
  echo "==> $file"
  ssh "$HOST" "sudo -n test -f '$file' && sudo -n cat '$file'" >"$src"
  orig_sha="$(sha256sum "$src" | awk '{print $1}')"

  node "$TRANSFORM_SCRIPT" "$src" "$dst" >"$meta"
  new_sha="$(sha256sum "$dst" | awk '{print $1}')"
  node --check "$dst" >/dev/null

  if cmp -s "$src" "$dst"; then
    if grep -q "$MARKER" "$src"; then
      echo "Already patched (sha256=$orig_sha)"
      continue
    fi
    echo "No change produced and marker missing; transform failed." >&2
    cat "$meta" >&2
    exit 1
  fi

  remote_tmp="/tmp/${base}.cheney-live-blurb.$$"
  scp -q "$dst" "$HOST:$remote_tmp"

  ssh "$HOST" "sudo -n test -f '${file}${BACKUP_SUFFIX}' || sudo -n cp -a '$file' '${file}${BACKUP_SUFFIX}'"
  ssh "$HOST" "sudo -n install -m 0644 '$remote_tmp' '$file'"
  ssh "$HOST" "rm -f '$remote_tmp'"
  ssh "$HOST" "sudo -n node --check '$file' >/dev/null && sudo -n grep -q '$MARKER' '$file'"

  echo "Patched (sha256 $orig_sha -> $new_sha)"
done

echo
echo "Patch complete."
