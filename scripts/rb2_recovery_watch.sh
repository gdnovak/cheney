#!/usr/bin/env bash
set -euo pipefail

TARGET_IP="${1:-192.168.5.108}"
TARGET_SSH="${2:-rb2}"
DURATION_SEC="${3:-600}"
INTERVAL_SEC="${4:-10}"
OUTDIR="${OUTDIR:-/home/tdj/cheney/notes}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTFILE="$OUTDIR/rb2-recovery-watch-$STAMP.log"

mkdir -p "$OUTDIR"

log() {
  printf '%s\n' "$*" | tee -a "$OUTFILE"
}

if ! command -v ping >/dev/null 2>&1; then
  echo "ping not found"
  exit 2
fi

start_epoch="$(date +%s)"
end_epoch=$((start_epoch + DURATION_SEC))

log "START ts=$(date '+%Y-%m-%d %H:%M:%S %Z') target_ip=$TARGET_IP target_ssh=$TARGET_SSH duration_sec=$DURATION_SEC interval_sec=$INTERVAL_SEC"

while [ "$(date +%s)" -lt "$end_epoch" ]; do
  ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"

  if ping -n -c 1 -W 1 "$TARGET_IP" >/dev/null 2>&1; then
    ping_state="up"
  else
    ping_state="down"
  fi

  if ssh -o BatchMode=yes -o ConnectTimeout=3 "$TARGET_SSH" "systemctl is-active pveproxy pvedaemon pve-cluster 2>/dev/null | tr '\n' ','" >/tmp/rb2_recovery_watch.$$ 2>/dev/null; then
    svc_state="$(cat /tmp/rb2_recovery_watch.$$ | sed 's/,$//')"
    ssh_state="up"
  else
    svc_state="unavailable"
    ssh_state="down"
  fi

  log "TS=\"$ts\" ping=$ping_state ssh=$ssh_state services=$svc_state"
  sleep "$INTERVAL_SEC"
done

rm -f /tmp/rb2_recovery_watch.$$ || true
log "END ts=$(date '+%Y-%m-%d %H:%M:%S %Z') outfile=$OUTFILE"
