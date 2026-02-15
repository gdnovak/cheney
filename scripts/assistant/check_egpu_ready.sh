#!/usr/bin/env bash
set -euo pipefail

# Passes when external GTX 1060 endpoint is visible on rb1 host.
# Current known device ID for Razer Core card: 10de:1c03

HOST_ALIAS="${1:-rb1-pve}"

if ssh "$HOST_ALIAS" "lspci -nn | grep -q '10de:1c03'"; then
  echo "egpu_ready=true host=$HOST_ALIAS"
  exit 0
fi

echo "egpu_ready=false host=$HOST_ALIAS"
exit 1
