#!/usr/bin/env bash
set -euo pipefail

INTERVAL_SEC="${1:-60}"
OUTFILE="${2:-/home/tdj/cheney/notes/netwatch-$(date +%Y%m%d-%H%M%S).log}"

# Management targets to ping from this controller.
TARGETS=(
  "192.168.4.1:gateway"
  "192.168.5.98:rb1"
  "192.168.5.108:rb2"
  "192.168.5.66:mba"
  "192.168.5.102:tsdeb"
)

# host_alias:physical_interface_name
HOST_IFACES=(
  "rb1-pve:enx90203a1be8d6"
  "rb2:enx00051bde7e6e"
  "mba:nic0"
)

mkdir -p "$(dirname "$OUTFILE")"
touch "$OUTFILE"

log() {
  printf '%s\n' "$*" | tee -a "$OUTFILE"
}

ping_summary() {
  local ip="$1"
  local label="$2"
  local line

  if line="$(ping -n -q -c 4 -W 1 "$ip" 2>/dev/null | tail -n 2 | tr '\n' ' ' )"; then
    log "PING label=$label ip=$ip summary=\"$line\""
  else
    log "PING label=$label ip=$ip summary=\"unreachable\""
  fi
}

host_iface_snapshot() {
  local host="$1"
  local iface="$2"
  local data

  data="$(ssh -o BatchMode=yes -o ConnectTimeout=4 "$host" \
    "bash -lc '
      if [ ! -e /sys/class/net/$iface ]; then
        echo \"iface_missing\"
        exit 0
      fi
      oper=\$(cat /sys/class/net/$iface/operstate 2>/dev/null || echo unknown)
      speed=\$(cat /sys/class/net/$iface/speed 2>/dev/null || echo unknown)
      duplex=\$(cat /sys/class/net/$iface/duplex 2>/dev/null || echo unknown)
      rx_err=\$(cat /sys/class/net/$iface/statistics/rx_errors 2>/dev/null || echo -1)
      tx_err=\$(cat /sys/class/net/$iface/statistics/tx_errors 2>/dev/null || echo -1)
      rx_drop=\$(cat /sys/class/net/$iface/statistics/rx_dropped 2>/dev/null || echo -1)
      tx_drop=\$(cat /sys/class/net/$iface/statistics/tx_dropped 2>/dev/null || echo -1)
      rx_pkt=\$(cat /sys/class/net/$iface/statistics/rx_packets 2>/dev/null || echo -1)
      tx_pkt=\$(cat /sys/class/net/$iface/statistics/tx_packets 2>/dev/null || echo -1)
      rx_b=\$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo -1)
      tx_b=\$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo -1)
      echo \"oper=\$oper speed=\$speed duplex=\$duplex rx_err=\$rx_err tx_err=\$tx_err rx_drop=\$rx_drop tx_drop=\$tx_drop rx_pkt=\$rx_pkt tx_pkt=\$tx_pkt rx_b=\$rx_b tx_b=\$tx_b\"
    '" 2>/dev/null)" || true

  if [ -z "${data:-}" ]; then
    log "IFACE host=$host iface=$iface status=ssh_unreachable"
  else
    log "IFACE host=$host iface=$iface $data"
  fi
}

log "START interval_sec=$INTERVAL_SEC outfile=$OUTFILE"
while true; do
  log "TS $(date '+%Y-%m-%d %H:%M:%S %Z')"

  for item in "${TARGETS[@]}"; do
    ip="${item%%:*}"
    label="${item##*:}"
    ping_summary "$ip" "$label"
  done

  for item in "${HOST_IFACES[@]}"; do
    host="${item%%:*}"
    iface="${item##*:}"
    host_iface_snapshot "$host" "$iface"
  done

  sleep "$INTERVAL_SEC"
done
