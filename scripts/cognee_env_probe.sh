#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-rb1-admin}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_PATH="${2:-/home/tdj/cheney/notes/cognee/cognee-env-probe-${STAMP}.md}"

mkdir -p "$(dirname "$OUT_PATH")"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

ssh "$HOST" 'bash -s' <<'EOF' >"$tmp"
set -euo pipefail
echo "timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "hostname=$(hostnamectl --static 2>/dev/null || hostname)"
echo "user=$(whoami)"
echo "python3=$(python3 --version 2>/dev/null || echo missing)"
echo "pip3=$(python3 -m pip --version 2>/dev/null || echo missing)"
echo "node=$(node --version 2>/dev/null || echo missing)"
echo "npm=$(npm --version 2>/dev/null || echo missing)"
echo "podman=$(podman --version 2>/dev/null || echo missing)"
echo "docker=$(docker --version 2>/dev/null || echo missing)"
echo "ollama_service=$(systemctl is-active ollama 2>/dev/null || echo unknown)"
echo "openclaw_gateway_user_service=$(systemctl --user is-active openclaw-gateway 2>/dev/null || echo unknown)"
ram_total_mib="$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)"
root_df="$(df -h / | awk 'NR==2 {print $2 " total, " $3 " used, " $4 " avail (" $5 ")"}')"
home_df="$(df -h /home | awk 'NR==2 {print $2 " total, " $3 " used, " $4 " avail (" $5 ")"}')"
echo "ram_total_mib=$ram_total_mib"
echo "root_df=$root_df"
echo "home_df=$home_df"
EOF

{
  echo "# Cognee Environment Probe"
  echo
  echo "- Host alias: \`$HOST\`"
  echo "- Captured: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  echo "## Raw Probe Output"
  echo
  echo '```'
  cat "$tmp"
  echo '```'
} >"$OUT_PATH"

echo "Probe report written: $OUT_PATH"
