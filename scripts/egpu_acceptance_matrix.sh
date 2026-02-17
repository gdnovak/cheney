#!/usr/bin/env bash
set -euo pipefail

# Runs one eGPU acceptance scenario on rb1-fedora and appends a row to a
# markdown matrix file in notes/. Designed for resumable, repeatable evidence.

usage() {
  cat <<'EOF'
Usage:
  scripts/egpu_acceptance_matrix.sh --scenario <name> [options]

Options:
  --scenario <name>       Scenario label (required)
  --host <alias>          SSH alias for rb1 host (default: rb1-admin)
  --peer <alias>          SSH alias for rb2/peer host (default: rb2)
  --fallback-peer <ip>    Peer fallback IP (default: 172.31.99.2)
  --out <path>            Matrix markdown file path
                          (default: notes/egpu-acceptance-matrix-YYYYMMDD.md)
  --artifacts-dir <dir>   Artifact directory
                          (default: notes/egpu-acceptance-artifacts)
  --reboot                Reboot host as part of this scenario
  --timeout <seconds>     Reboot wait timeout (default: 240)
  -h, --help              Show this help

Example:
  scripts/egpu_acceptance_matrix.sh \
    --scenario reboot_attached \
    --reboot
EOF
}

HOST_ALIAS="rb1-admin"
PEER_ALIAS="rb2"
FALLBACK_PEER_IP="172.31.99.2"
REBOOT_SCENARIO=0
REBOOT_TIMEOUT=240
SCENARIO=""
TODAY="$(date +%Y%m%d)"
OUT_FILE="notes/egpu-acceptance-matrix-${TODAY}.md"
ARTIFACTS_DIR="notes/egpu-acceptance-artifacts"
EXPECTED_BDF="00000000:0F:00.0"
EXPECTED_PCI_ID="10de:1c03"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scenario)
      SCENARIO="${2:-}"
      shift 2
      ;;
    --host)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --peer)
      PEER_ALIAS="${2:-}"
      shift 2
      ;;
    --fallback-peer)
      FALLBACK_PEER_IP="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    --artifacts-dir)
      ARTIFACTS_DIR="${2:-}"
      shift 2
      ;;
    --reboot)
      REBOOT_SCENARIO=1
      shift
      ;;
    --timeout)
      REBOOT_TIMEOUT="${2:-}"
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

if [[ -z "$SCENARIO" ]]; then
  echo "--scenario is required" >&2
  usage >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT_FILE")" "$ARTIFACTS_DIR"

TS_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TS_STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_FILE="${ARTIFACTS_DIR}/egpu-${SCENARIO}-${TS_STAMP}.log"

log() {
  local msg
  msg="$(printf '%s %s' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*")"
  printf '%s\n' "$msg" >>"$ARTIFACT_FILE"
  printf '%s\n' "$msg" >&2
}

ssh_host() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST_ALIAS" "$@"
}

ssh_peer() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$PEER_ALIAS" "$@"
}

check_boot_id() {
  ssh_host "cat /proc/sys/kernel/random/boot_id"
}

check_lspci_external() {
  if ssh_host "lspci -nn | grep -q '${EXPECTED_PCI_ID}'"; then
    echo 1
  else
    echo 0
  fi
}

check_nvsmi_external() {
  if ssh_host "nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader 2>/dev/null | grep -qi '${EXPECTED_BDF}'"; then
    echo 1
  else
    echo 0
  fi
}

check_fallback_ping() {
  if ssh_host "ping -c 2 -W 1 ${FALLBACK_PEER_IP} >/dev/null"; then
    echo 0
  else
    echo 1
  fi
}

check_fallback_iface() {
  if ssh_host "ip -4 -br addr show enp0s20f0u6.99 | grep -q '172.31.99.1/30'"; then
    echo 1
  else
    echo 0
  fi
}

check_services() {
  ssh_host "systemctl is-active sshd firewalld chronyd cockpit.socket" | tr '\n' ',' | sed 's/,$//'
}

collect_snapshot() {
  local phase="$1"
  log "Collecting ${phase} snapshot"
  local boot_id lspci_ext nvsmi_ext fallback_ping_rc fallback_iface services
  boot_id="$(check_boot_id)"
  lspci_ext="$(check_lspci_external)"
  nvsmi_ext="$(check_nvsmi_external)"
  fallback_ping_rc="$(check_fallback_ping)"
  fallback_iface="$(check_fallback_iface)"
  services="$(check_services)"
  printf '%s|%s|%s|%s|%s|%s\n' \
    "$boot_id" "$lspci_ext" "$nvsmi_ext" "$fallback_ping_rc" "$fallback_iface" "$services"
}

reboot_and_wait() {
  local pre_boot_id="$1"
  log "Triggering reboot on ${HOST_ALIAS}"
  ssh_host "sudo systemctl reboot" || true

  local start now elapsed current_boot_id
  start="$(date +%s)"
  while true; do
    now="$(date +%s)"
    elapsed=$((now - start))
    if (( elapsed > REBOOT_TIMEOUT )); then
      log "Reboot timeout after ${elapsed}s"
      echo "timeout|${elapsed}"
      return 1
    fi

    if current_boot_id="$(ssh_host "cat /proc/sys/kernel/random/boot_id" 2>/dev/null)"; then
      if [[ "$current_boot_id" != "$pre_boot_id" ]]; then
        log "Reboot confirmed after ${elapsed}s (boot_id=${current_boot_id})"
        echo "${current_boot_id}|${elapsed}"
        return 0
      fi
    fi
    sleep 2
  done
}

if [[ ! -f "$OUT_FILE" ]]; then
  cat >"$OUT_FILE" <<'EOF'
| timestamp_utc | scenario | reboot | result | boot_before | boot_after | reboot_elapsed_s | lspci_ext_pre | lspci_ext_post | nvsmi_ext_pre | nvsmi_ext_post | fallback_ping_pre_rc | fallback_ping_post_rc | fallback_iface_pre | fallback_iface_post | services_post |
|---|---|---:|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
EOF
fi

log "Scenario=${SCENARIO} reboot=${REBOOT_SCENARIO} host=${HOST_ALIAS} peer=${PEER_ALIAS}"
log "Expected external PCI ID=${EXPECTED_PCI_ID} BDF=${EXPECTED_BDF}"

IFS='|' read -r pre_boot pre_lspci pre_nvsmi pre_ping_rc pre_fallback_iface pre_services < <(collect_snapshot "pre")

post_boot="$pre_boot"
reboot_elapsed="0"
if [[ "$REBOOT_SCENARIO" -eq 1 ]]; then
  IFS='|' read -r post_boot reboot_elapsed < <(reboot_and_wait "$pre_boot")
fi

IFS='|' read -r post_boot_check post_lspci post_nvsmi post_ping_rc post_fallback_iface post_services < <(collect_snapshot "post")
post_boot="$post_boot_check"

result="PASS"
notes=()

if [[ "$pre_lspci" != "1" || "$pre_nvsmi" != "1" ]]; then
  result="FAIL"
  notes+=("external_gpu_missing_pre")
fi
if [[ "$post_lspci" != "1" || "$post_nvsmi" != "1" ]]; then
  result="FAIL"
  notes+=("external_gpu_missing_post")
fi
if [[ "$pre_ping_rc" != "0" || "$post_ping_rc" != "0" ]]; then
  result="FAIL"
  notes+=("fallback_ping_failed")
fi
if [[ "$pre_fallback_iface" != "1" || "$post_fallback_iface" != "1" ]]; then
  result="FAIL"
  notes+=("fallback_iface_missing")
fi
if [[ "$REBOOT_SCENARIO" -eq 1 && "$pre_boot" == "$post_boot" ]]; then
  result="FAIL"
  notes+=("boot_id_unchanged")
fi

if ! ssh_peer "ping -c 2 -W 1 172.31.99.1 >/dev/null"; then
  result="FAIL"
  notes+=("peer_to_fallback_failed")
fi

if [[ "${#notes[@]}" -eq 0 ]]; then
  notes=("ok")
fi

printf '| %s | %s | %s | %s | `%s` | `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s | `%s` |\n' \
  "$TS_UTC" "$SCENARIO" "$REBOOT_SCENARIO" "$result" \
  "$pre_boot" "$post_boot" "$reboot_elapsed" \
  "$pre_lspci" "$post_lspci" "$pre_nvsmi" "$post_nvsmi" \
  "$pre_ping_rc" "$post_ping_rc" "$pre_fallback_iface" "$post_fallback_iface" "$post_services" >>"$OUT_FILE"

log "Result=${result} notes=$(IFS=,; echo "${notes[*]}")"
log "Matrix row appended to ${OUT_FILE}"
log "Artifact log saved at ${ARTIFACT_FILE}"

if [[ "$result" != "PASS" ]]; then
  exit 1
fi
