#!/usr/bin/env bash
set -euo pipefail

# Check whether a display sink is physically connected to the external GPU.
# Returns 0 if at least one connector on the target GPU reports "connected".

usage() {
  cat <<'EOF'
Usage:
  scripts/egpu_display_sink_check.sh [options]

Options:
  --host <alias>        SSH alias for rb1 host (default: rb1-admin)
  --bdf <bdf>           GPU PCI BDF (default: 0000:0f:00.0)
  --out <path>          Optional artifact log path
  -h, --help            Show help
EOF
}

HOST_ALIAS="rb1-admin"
GPU_BDF="0000:0f:00.0"
OUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --bdf)
      GPU_BDF="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$OUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUT_FILE")"
fi

log_line() {
  local msg
  msg="$(printf '%s %s' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*")"
  echo "$msg"
  if [[ -n "$OUT_FILE" ]]; then
    echo "$msg" >>"$OUT_FILE"
  fi
}

set +e
output="$(
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST_ALIAS" "bash -s -- '$GPU_BDF'" <<'EOS'
set -euo pipefail
bdf="$1"
base="/sys/bus/pci/devices/${bdf}/drm"

if [[ ! -d "$base" ]]; then
  echo "ERROR: missing drm path for ${bdf}" >&2
  exit 2
fi

connected=0
for card_path in "$base"/card*; do
  [[ -e "$card_path" ]] || continue
  card_name="$(basename "$card_path")"
  for status_file in /sys/class/drm/"${card_name}"-*/status; do
    [[ -f "$status_file" ]] || continue
    status="$(cat "$status_file")"
    connector="$(basename "${status_file%/status}")"
    echo "${connector}=${status}"
    if [[ "$status" == "connected" ]]; then
      connected=1
    fi
  done
done
exit "$(( connected ? 0 : 1 ))"
EOS
)"
rc=$?
set -e

log_line "host=${HOST_ALIAS} bdf=${GPU_BDF}"
if [[ -n "$output" ]]; then
  while IFS= read -r line; do
    log_line "$line"
  done <<<"$output"
fi

if [[ "$rc" -eq 0 ]]; then
  log_line "result=connected"
else
  log_line "result=not_connected"
fi

exit "$rc"
