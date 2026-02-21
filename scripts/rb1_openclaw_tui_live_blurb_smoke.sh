#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-rb1-admin}"
MARKER="CHENEY_TUI_LIVE_BLURB_V1"
FILES=(
  "/usr/local/lib/node_modules/openclaw/dist/tui-DW-D2_SI.js"
  "/usr/local/lib/node_modules/openclaw/dist/tui-CRTpgJsf.js"
)

echo "Target host: $HOST"

for file in "${FILES[@]}"; do
  echo
  echo "==> $file"
  ssh "$HOST" "sudo -n grep -q '$MARKER' '$file'"
  ssh "$HOST" "sudo -n grep -q 'action \${activityStatus}' '$file'"
  ssh "$HOST" "sudo -n grep -q 'inferFooterTier' '$file'"
  ssh "$HOST" "sudo -n node --check '$file' >/dev/null"
  echo "Marker/syntax checks: PASS"
done

echo
echo "OpenClaw CLI sanity:"
ssh "$HOST" "openclaw --version"
ssh "$HOST" "openclaw status --json >/dev/null"
ssh "$HOST" "openclaw health --json >/dev/null"
echo "Status/health checks: PASS"
