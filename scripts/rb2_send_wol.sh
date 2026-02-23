#!/usr/bin/env bash
set -euo pipefail

RB2_ALIAS="${RB2_ALIAS:-rb2}"
BROADCAST="${BROADCAST:-255.255.255.255}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/rb2_send_wol.sh [options] [target ...]

Targets:
  rb1       90:20:3a:1b:e8:d6
  rb2       00:05:1b:de:7e:6e
  mba       00:24:32:16:8e:d3
  fedora    3c:cd:36:67:e2:45

Options:
  --all                  Send to all known targets.
  --list                 Print known targets and exit.
  --dry-run              Print what would be sent without sending.
  --broadcast <ip>       Broadcast IP (default: 255.255.255.255).
  --rb2-alias <alias>    SSH alias/host for rb2 sender (default: rb2).
  -h, --help             Show this help.

Examples:
  scripts/rb2_send_wol.sh --list
  scripts/rb2_send_wol.sh rb1 mba
  scripts/rb2_send_wol.sh --all
  scripts/rb2_send_wol.sh --broadcast 192.168.7.255 rb1
USAGE
}

declare -A MACS=(
  [rb1]="90:20:3a:1b:e8:d6"
  [rb2]="00:05:1b:de:7e:6e"
  [mba]="00:24:32:16:8e:d3"
  [fedora]="3c:cd:36:67:e2:45"
)

print_list() {
  local name
  for name in rb1 rb2 mba fedora; do
    printf '%-8s %s\n' "$name" "${MACS[$name]}"
  done
}

require_cmd() {
  if ! command -v ssh >/dev/null 2>&1; then
    echo "missing required command: ssh" >&2
    exit 2
  fi
}

DRY_RUN=0
USE_ALL=0
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      USE_ALL=1
      shift
      ;;
    --list)
      print_list
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --broadcast)
      BROADCAST="${2:-}"
      shift 2
      ;;
    --rb2-alias)
      RB2_ALIAS="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done

if [[ $USE_ALL -eq 1 ]]; then
  TARGETS=(rb1 rb2 mba fedora)
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(rb1 mba fedora)
fi

require_cmd

for name in "${TARGETS[@]}"; do
  if [[ -z "${MACS[$name]:-}" ]]; then
    echo "unknown target: $name" >&2
    echo "known targets:" >&2
    print_list >&2
    exit 2
  fi

done

for name in "${TARGETS[@]}"; do
  mac="${MACS[$name]}"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "dry-run: ssh $RB2_ALIAS wakeonlan -i $BROADCAST $mac   # $name"
  else
    echo "send: $name ($mac) via $RB2_ALIAS broadcast=$BROADCAST"
    ssh -o BatchMode=yes "$RB2_ALIAS" "wakeonlan -i '$BROADCAST' '$mac'"
  fi
done
