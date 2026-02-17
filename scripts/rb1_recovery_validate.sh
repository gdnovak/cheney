#!/usr/bin/env bash
set -euo pipefail

# Validate rb1 recovery posture and append a result row to a markdown matrix.
# Intended for post-incident and post-maintenance verification.

usage() {
  cat <<'EOF'
Usage:
  scripts/rb1_recovery_validate.sh --scenario <name> [options]

Options:
  --scenario <name>       Scenario label (required)
  --host <alias>          SSH alias for rb1 host (default: rb1-admin)
  --peer <alias>          SSH alias for rb2 peer (default: rb2)
  --host-fallback <ip>    rb1 fallback IP (default: 172.31.99.1)
  --peer-fallback <ip>    rb2 fallback IP (default: 172.31.99.2)
  --out <path>            Matrix markdown path
                          (default: notes/rb1-recovery-matrix-YYYYMMDD.md)
  --artifacts-dir <dir>   Artifact log directory
                          (default: notes/rb1-recovery-artifacts)
  --reboot                Reboot rb1 as part of this validation
  --timeout <seconds>     Reboot wait timeout (default: 300)
  -h, --help              Show help

Examples:
  scripts/rb1_recovery_validate.sh --scenario post_incident_check
  scripts/rb1_recovery_validate.sh --scenario post_kernel_update --reboot
EOF
}

HOST_ALIAS="rb1-admin"
PEER_ALIAS="rb2"
HOST_FALLBACK_IP="172.31.99.1"
PEER_FALLBACK_IP="172.31.99.2"
REBOOT_SCENARIO=0
REBOOT_TIMEOUT=300
SCENARIO=""
TODAY="$(date +%Y%m%d)"
OUT_FILE="notes/rb1-recovery-matrix-${TODAY}.md"
ARTIFACTS_DIR="notes/rb1-recovery-artifacts"
EXPECTED_EXTERNAL_BDF="00000000:0F:00.0"

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
    --host-fallback)
      HOST_FALLBACK_IP="${2:-}"
      shift 2
      ;;
    --peer-fallback)
      PEER_FALLBACK_IP="${2:-}"
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
ARTIFACT_FILE="${ARTIFACTS_DIR}/rb1-recovery-${SCENARIO}-${TS_STAMP}.log"

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

check_policy() {
  local permit password policy_ok
  permit="$(ssh_host "sudo -n sshd -T | awk '/^permitrootlogin /{print \$2}'")"
  password="$(ssh_host "sudo -n sshd -T | awk '/^passwordauthentication /{print \$2}'")"
  if [[ ("$permit" == "without-password" || "$permit" == "prohibit-password") && "$password" == "no" ]]; then
    policy_ok=1
  else
    policy_ok=0
  fi
  printf '%s|%s|%s\n' "$policy_ok" "$permit" "$password"
}

check_services() {
  local required_states nvidia_powerd_state services svc_ok
  IFS='|' read -r required_states nvidia_powerd_state < <(
    ssh_host "bash -lc '
      required_states=\"\$(systemctl is-active sshd firewalld chronyd cockpit.socket NetworkManager | tr \"\n\" \",\" | sed \"s/,\$//\")\"
      nvidia_powerd_state=\"\$(systemctl is-active nvidia-powerd || true)\"
      printf \"%s|%s\n\" \"\$required_states\" \"\$nvidia_powerd_state\"
    '"
  )
  services="${required_states},${nvidia_powerd_state}"
  if [[ "$required_states" == "active,active,active,active,active" && ( "$nvidia_powerd_state" == "active" || "$nvidia_powerd_state" == "inactive" ) ]]; then
    svc_ok=1
  else
    svc_ok=0
  fi
  printf '%s|%s\n' "$svc_ok" "$services"
}

check_gpu_snapshot() {
  local gpu_count ext_present
  gpu_count="$(ssh_host "nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader 2>/dev/null | wc -l | tr -d ' '")"
  if ssh_host "nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader 2>/dev/null | grep -qi '${EXPECTED_EXTERNAL_BDF}'"; then
    ext_present=1
  else
    ext_present=0
  fi
  printf '%s|%s\n' "$gpu_count" "$ext_present"
}

check_fallback_iface() {
  if ssh_host "ip -4 -br addr show enp0s20f0u6.99 | grep -q '${HOST_FALLBACK_IP}/30'"; then
    echo 1
  else
    echo 0
  fi
}

check_ping_host_to_peer() {
  if ssh_host "ping -c 2 -W 1 ${PEER_FALLBACK_IP} >/dev/null"; then
    echo 0
  else
    echo 1
  fi
}

check_ping_peer_to_host() {
  if ssh_peer "ping -c 2 -W 1 ${HOST_FALLBACK_IP} >/dev/null"; then
    echo 0
  else
    echo 1
  fi
}

collect_snapshot() {
  local phase
  phase="$1"
  log "Collecting ${phase} snapshot"
  local boot_id policy_ok permit password svc_ok services gpu_count ext_present fallback_iface ping_h2p ping_p2h
  boot_id="$(check_boot_id)"
  IFS='|' read -r policy_ok permit password < <(check_policy)
  IFS='|' read -r svc_ok services < <(check_services)
  IFS='|' read -r gpu_count ext_present < <(check_gpu_snapshot)
  fallback_iface="$(check_fallback_iface)"
  ping_h2p="$(check_ping_host_to_peer)"
  ping_p2h="$(check_ping_peer_to_host)"
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$boot_id" "$policy_ok" "$permit" "$password" "$svc_ok" "$services" "$gpu_count" "$ext_present" "$fallback_iface" "${ping_h2p},${ping_p2h}"
}

reboot_and_wait() {
  local pre_boot_id="$1"
  log "Triggering reboot on ${HOST_ALIAS}"
  ssh_host "sudo -n systemctl reboot" || true

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
| timestamp_utc | scenario | reboot | result | boot_before | boot_after | reboot_elapsed_s | policy_ok_pre | policy_ok_post | permit_pre | permit_post | passwordauth_pre | passwordauth_post | services_ok_pre | services_ok_post | gpu_count_pre | gpu_count_post | external_gpu_pre | external_gpu_post | fallback_iface_pre | fallback_iface_post | ping_h2p_pre_rc | ping_h2p_post_rc | ping_p2h_pre_rc | ping_p2h_post_rc | services_post |
|---|---|---:|---|---|---|---:|---:|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
EOF
fi

log "Scenario=${SCENARIO} reboot=${REBOOT_SCENARIO} host=${HOST_ALIAS} peer=${PEER_ALIAS}"

IFS='|' read -r pre_boot pre_policy_ok pre_permit pre_password pre_svc_ok pre_services pre_gpu_count pre_ext pre_fb_iface pre_ping_pair < <(collect_snapshot "pre")
pre_ping_h2p="${pre_ping_pair%,*}"
pre_ping_p2h="${pre_ping_pair#*,}"

post_boot="$pre_boot"
reboot_elapsed="0"
if [[ "$REBOOT_SCENARIO" -eq 1 ]]; then
  IFS='|' read -r post_boot reboot_elapsed < <(reboot_and_wait "$pre_boot")
fi

IFS='|' read -r post_boot_check post_policy_ok post_permit post_password post_svc_ok post_services post_gpu_count post_ext post_fb_iface post_ping_pair < <(collect_snapshot "post")
post_boot="$post_boot_check"
post_ping_h2p="${post_ping_pair%,*}"
post_ping_p2h="${post_ping_pair#*,}"

result="PASS"
notes=()

if [[ "$pre_policy_ok" != "1" || "$post_policy_ok" != "1" ]]; then
  result="FAIL"
  notes+=("ssh_policy_not_hardened")
fi
if [[ "$pre_svc_ok" != "1" || "$post_svc_ok" != "1" ]]; then
  result="FAIL"
  notes+=("services_not_healthy")
fi
if [[ "$pre_gpu_count" -lt 2 || "$post_gpu_count" -lt 2 ]]; then
  result="FAIL"
  notes+=("gpu_count_lt_2")
fi
if [[ "$pre_ext" != "1" || "$post_ext" != "1" ]]; then
  result="FAIL"
  notes+=("external_gpu_missing")
fi
if [[ "$pre_fb_iface" != "1" || "$post_fb_iface" != "1" ]]; then
  result="FAIL"
  notes+=("fallback_iface_missing")
fi
if [[ "$pre_ping_h2p" != "0" || "$post_ping_h2p" != "0" ]]; then
  result="FAIL"
  notes+=("host_to_peer_ping_fail")
fi
if [[ "$pre_ping_p2h" != "0" || "$post_ping_p2h" != "0" ]]; then
  result="FAIL"
  notes+=("peer_to_host_ping_fail")
fi
if [[ "$REBOOT_SCENARIO" -eq 1 && "$pre_boot" == "$post_boot" ]]; then
  result="FAIL"
  notes+=("boot_id_unchanged")
fi

if [[ "${#notes[@]}" -eq 0 ]]; then
  notes=("ok")
fi

printf '| %s | %s | %s | %s | `%s` | `%s` | %s | %s | %s | `%s` | `%s` | `%s` | `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | `%s` |\n' \
  "$TS_UTC" "$SCENARIO" "$REBOOT_SCENARIO" "$result" \
  "$pre_boot" "$post_boot" "$reboot_elapsed" \
  "$pre_policy_ok" "$post_policy_ok" \
  "$pre_permit" "$post_permit" \
  "$pre_password" "$post_password" \
  "$pre_svc_ok" "$post_svc_ok" \
  "$pre_gpu_count" "$post_gpu_count" \
  "$pre_ext" "$post_ext" \
  "$pre_fb_iface" "$post_fb_iface" \
  "$pre_ping_h2p" "$post_ping_h2p" \
  "$pre_ping_p2h" "$post_ping_p2h" \
  "$post_services" >>"$OUT_FILE"

{
  echo
  echo "## Host snapshot"
  ssh_host "hostnamectl --static; cat /proc/sys/kernel/random/boot_id; ip -4 -br addr; nvidia-smi --query-gpu=index,pci.bus_id,name,display_active,pstate,pcie.link.gen.current,pcie.link.width.current --format=csv"
  echo
  echo "## Peer fallback check"
  ssh_peer "hostnamectl --static; ip -4 -br addr show vmbr0.99 || true; ping -c 2 -W 1 ${HOST_FALLBACK_IP} >/dev/null && echo peer_to_host_fallback=ok || echo peer_to_host_fallback=fail"
} >>"$ARTIFACT_FILE" 2>&1 || true

log "Result=${result} notes=$(IFS=,; echo "${notes[*]}")"
log "Matrix row appended to ${OUT_FILE}"
log "Artifact log saved at ${ARTIFACT_FILE}"
