#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-rb1-admin}"
BACKUP_SUFFIX=".cheney-live-blurb-v1.bak"
FILES=(
  "/usr/local/lib/node_modules/openclaw/dist/tui-DW-D2_SI.js"
  "/usr/local/lib/node_modules/openclaw/dist/tui-CRTpgJsf.js"
)

echo "Target host: $HOST"

for file in "${FILES[@]}"; do
  backup="${file}${BACKUP_SUFFIX}"
  echo
  echo "==> $file"
  if ssh "$HOST" "sudo -n test -f '$backup'"; then
    ssh "$HOST" "sudo -n cp -a '$backup' '$file'"
    ssh "$HOST" "sudo -n node --check '$file' >/dev/null"
    echo "Restored from $backup"
  else
    echo "Backup not found: $backup"
  fi
done

echo
echo "Restore complete."
