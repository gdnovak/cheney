#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "usage: $0 <server_ip_or_host> [duration_sec] [udp_rate]"
  echo "example: $0 192.168.5.108 30 500M"
  exit 1
fi

SERVER="$1"
DURATION="${2:-30}"
UDP_RATE="${3:-500M}"
OUTDIR="${OUTDIR:-/home/tdj/cheney/notes}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTFILE="$OUTDIR/iperf3-client-suite-${SERVER//[^a-zA-Z0-9_.-]/_}-$STAMP.log"

mkdir -p "$OUTDIR"

if ! command -v iperf3 >/dev/null 2>&1; then
  echo "iperf3 not found on client host. install it first."
  exit 2
fi

run() {
  echo "============================================================" | tee -a "$OUTFILE"
  echo "CMD: $*" | tee -a "$OUTFILE"
  "$@" 2>&1 | tee -a "$OUTFILE"
}

echo "start_time=$(date '+%Y-%m-%d %H:%M:%S %Z')" | tee -a "$OUTFILE"
echo "server=$SERVER duration=$DURATION udp_rate=$UDP_RATE" | tee -a "$OUTFILE"
echo "note=ensure remote iperf3 server is running: iperf3 -s" | tee -a "$OUTFILE"

run iperf3 -c "$SERVER" -t "$DURATION" -P 1
run iperf3 -c "$SERVER" -t "$DURATION" -P 4
run iperf3 -c "$SERVER" -t "$DURATION" -P 8
run iperf3 -c "$SERVER" -t "$DURATION" -P 4 -R
run iperf3 -c "$SERVER" -t "$DURATION" -u -b "$UDP_RATE"

echo "end_time=$(date '+%Y-%m-%d %H:%M:%S %Z')" | tee -a "$OUTFILE"
echo "outfile=$OUTFILE"
