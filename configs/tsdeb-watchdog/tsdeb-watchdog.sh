#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="tsdeb-watchdog"
BCAST="192.168.7.255"

check_and_wake() {
  local node="$1" ip="$2" mac="$3"
  if ping -c1 -W1 "$ip" >/dev/null 2>&1; then
    logger -t "$LOG_TAG" "$node up ($ip)"
  else
    logger -t "$LOG_TAG" "$node down ($ip); sending WoL to $mac"
    if ! wakeonlan -i "$BCAST" "$mac" >/dev/null 2>&1; then
      logger -t "$LOG_TAG" "WoL send failed for $node ($mac)"
    fi
  fi
}

check_and_wake rb1 192.168.5.98 00:05:1b:de:7e:6e
check_and_wake rb2 192.168.5.108 a0:ce:c8:04:fe:d7
check_and_wake mba 192.168.5.66 00:24:32:16:8e:d3
