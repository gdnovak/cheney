#!/usr/bin/env bash
set -euo pipefail

# Run a short non-AI external GPU benchmark on rb1 and save an artifact log.

usage() {
  cat <<'EOF'
Usage:
  scripts/egpu_hashcat_benchmark.sh [options]

Options:
  --host <alias>         SSH alias for benchmark host (default: rb1-admin)
  --device-id <id>       Hashcat backend device id (default: 2)
  --hash-mode <mode>     Hashcat mode to benchmark (default: 1400)
  --out-dir <dir>        Artifact directory
                         (default: notes/egpu-acceptance-artifacts)
  --install-hashcat      Install hashcat on host before running benchmark
  -h, --help             Show help

Example:
  scripts/egpu_hashcat_benchmark.sh --device-id 2 --hash-mode 1400
EOF
}

HOST_ALIAS="rb1-admin"
DEVICE_ID="2"
HASH_MODE="1400"
OUT_DIR="notes/egpu-acceptance-artifacts"
INSTALL_HASHCAT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --device-id)
      DEVICE_ID="${2:-}"
      shift 2
      ;;
    --hash-mode)
      HASH_MODE="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --install-hashcat)
      INSTALL_HASHCAT=1
      shift
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

mkdir -p "$OUT_DIR"

TS_STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_FILE="${OUT_DIR}/egpu-benchmark-hashcat-external-${TS_STAMP}.log"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*"
}

ssh_host() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST_ALIAS" "$@"
}

if [[ "$INSTALL_HASHCAT" -eq 1 ]]; then
  log "Installing hashcat on ${HOST_ALIAS}"
  ssh_host "sudo -n dnf -y install hashcat"
fi

{
  log "Scenario=egpu_workload_hashcat host=${HOST_ALIAS} device=${DEVICE_ID} mode=${HASH_MODE}"
  ssh_host "bash -s -- '$DEVICE_ID' '$HASH_MODE'" <<'EOS'
set -euo pipefail
device_id="$1"
hash_mode="$2"

if ! command -v hashcat >/dev/null 2>&1; then
  echo "hashcat is not installed on host" >&2
  exit 1
fi

echo "PRE_NVIDIA_SMI"
nvidia-smi --query-gpu=index,pci.bus_id,name,display_active,utilization.gpu,pstate,pcie.link.gen.current,pcie.link.width.current --format=csv

echo "HASHCAT_DEVICE_ENUM_START"
hashcat -I
echo "HASHCAT_DEVICE_ENUM_END"

echo "HASHCAT_BENCHMARK_START $(date -Iseconds)"
hashcat -b -m "$hash_mode" -d "$device_id"
echo "HASHCAT_BENCHMARK_END $(date -Iseconds)"

echo "POST_NVIDIA_SMI"
nvidia-smi --query-gpu=index,pci.bus_id,name,display_active,utilization.gpu,pstate,pcie.link.gen.current,pcie.link.width.current --format=csv
EOS
} | tee "$ARTIFACT_FILE"

log "Artifact log saved at ${ARTIFACT_FILE}"
