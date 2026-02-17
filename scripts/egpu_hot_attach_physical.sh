#!/usr/bin/env bash
set -euo pipefail

# User-attended physical hot-attach watcher for rb1 eGPU.
# This script waits for a real detach + reattach event and captures evidence.

usage() {
  cat <<'EOF'
Usage:
  scripts/egpu_hot_attach_physical.sh [options]

Options:
  --host <alias>          SSH alias for rb1 host (default: rb1-admin)
  --peer <alias>          SSH alias for rb2 peer (default: rb2)
  --pci-id <id>           External GPU PCI id to watch (default: 10de:1c03)
  --host-fallback <ip>    rb1 fallback IP for peer ping check (default: 172.31.99.1)
  --out <path>            Artifact log path
                          (default: notes/egpu-acceptance-artifacts/egpu-hot_attach_idle-physical-<timestamp>.log)
  --detach-timeout <sec>  Wait time for detach event (default: 300)
  --attach-timeout <sec>  Wait time for attach event (default: 300)
  -h, --help              Show help
EOF
}

HOST_ALIAS="rb1-admin"
PEER_ALIAS="rb2"
PCI_ID="10de:1c03"
HOST_FALLBACK_IP="172.31.99.1"
DETACH_TIMEOUT=300
ATTACH_TIMEOUT=300
TS_STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_FILE="notes/egpu-acceptance-artifacts/egpu-hot_attach_idle-physical-${TS_STAMP}.log"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --peer)
      PEER_ALIAS="${2:-}"
      shift 2
      ;;
    --pci-id)
      PCI_ID="${2:-}"
      shift 2
      ;;
    --host-fallback)
      HOST_FALLBACK_IP="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    --detach-timeout)
      DETACH_TIMEOUT="${2:-}"
      shift 2
      ;;
    --attach-timeout)
      ATTACH_TIMEOUT="${2:-}"
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

mkdir -p "$(dirname "$OUT_FILE")"

log() {
  local msg
  msg="$(printf '%s %s' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*")"
  printf '%s\n' "$msg" | tee -a "$OUT_FILE" >&2
}

ssh_host() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST_ALIAS" "$@"
}

ssh_peer() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$PEER_ALIAS" "$@"
}

egpu_present() {
  ssh_host "lspci -nn | grep -qi '$PCI_ID'"
}

wait_for_state() {
  local target_state="$1"
  local timeout="$2"
  local start now elapsed
  start="$(date +%s)"
  while true; do
    now="$(date +%s)"
    elapsed=$((now - start))
    if (( elapsed > timeout )); then
      return 1
    fi

    if egpu_present; then
      if [[ "$target_state" == "present" ]]; then
        return 0
      fi
    else
      if [[ "$target_state" == "absent" ]]; then
        return 0
      fi
    fi
    sleep 1
  done
}

START_ISO="$(date -Iseconds)"
log "Scenario=hot_attach_idle_physical host=${HOST_ALIAS} peer=${PEER_ALIAS} pci_id=${PCI_ID}"
log "Start marker for kernel log capture: ${START_ISO}"

if ! egpu_present; then
  log "ERROR: eGPU not present at start; connect enclosure first."
  exit 1
fi

log "WAITING_FOR_DETACH timeout=${DETACH_TIMEOUT}s"
if ! wait_for_state absent "$DETACH_TIMEOUT"; then
  log "ERROR: detach event not observed before timeout."
  exit 1
fi
log "DETACH_DETECTED"

log "WAITING_FOR_ATTACH timeout=${ATTACH_TIMEOUT}s"
if ! wait_for_state present "$ATTACH_TIMEOUT"; then
  log "ERROR: reattach event not observed before timeout."
  exit 1
fi
log "ATTACH_DETECTED"

sleep 3
log "POST_ATTACH_CAPTURE_BEGIN"
{
  echo "## boltctl list"
  ssh_host "boltctl list"
  echo
  echo "## lspci display devices"
  ssh_host "lspci -nnk | grep -EA3 'VGA|3D|Display'"
  echo
  echo "## nvidia-smi summary"
  ssh_host "nvidia-smi --query-gpu=index,pci.bus_id,name,display_active,utilization.gpu,pstate,pcie.link.gen.current,pcie.link.width.current --format=csv"
  echo
  echo "## fallback checks"
  ssh_host "ping -c 2 -W 1 172.31.99.2 >/dev/null && echo host_to_peer_fallback=ok"
  ssh_peer "ping -c 2 -W 1 ${HOST_FALLBACK_IP} >/dev/null && echo peer_to_host_fallback=ok"
  echo
  echo "## kernel log since start"
  ssh_host "journalctl -k --since '${START_ISO}' --no-pager"
} >>"$OUT_FILE"
log "POST_ATTACH_CAPTURE_END"
log "Artifact log saved at ${OUT_FILE}"
