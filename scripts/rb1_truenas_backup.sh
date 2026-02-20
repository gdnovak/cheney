#!/usr/bin/env bash
set -euo pipefail

TRUENAS_HOST="${TRUENAS_HOST:-192.168.5.100}"
TRUENAS_USER="${TRUENAS_USER:-macmini_bu}"
KEY_PATH="${KEY_PATH:-$HOME/.ssh/id_ed25519_truenas_rb1}"
KNOWN_HOSTS="${KNOWN_HOSTS:-$HOME/.ssh/known_hosts}"

DEST_BASE="${DEST_BASE:-/mnt/oyPool/rb1AssistantBackups}"
SNAP_DIR="$DEST_BASE/snapshots"
LOG_DIR="${LOG_DIR:-$HOME/backup-logs}"

STAMP="$(date +%F_%H-%M-%S)"
LOGFILE="$LOG_DIR/rb1_truenas_backup_${STAMP}.log"

SSH_CMD=(
  ssh
  -i "$KEY_PATH"
  -o BatchMode=yes
  -o StrictHostKeyChecking=yes
  -o UserKnownHostsFile="$KNOWN_HOSTS"
)
RSYNC_SSH="ssh -i $KEY_PATH -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$KNOWN_HOSTS"

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") create [label]
  $(basename "$0") list
  $(basename "$0") prune <keep_count>

Notes:
- Manual workflow only (no timers).
- Default destination: $SNAP_DIR
- Backed up paths (current scope):
  - /home/tdj/cheney
  - /home/tdj/reproduce-cheney
  - /home/tdj/.openclaw
  - /home/tdj/.config/openclaw
  - /home/tdj/.ssh
  - /etc/NetworkManager/system-connections/fallback99.nmconnection (if present)
  - /etc/ssh/sshd_config.d/00-lchl-access-policy.conf (if present)
USAGE
}

log() {
  local msg="[$(date +%F_%T)] $*"
  echo "$msg" | tee -a "$LOGFILE"
}

run_ssh() {
  "${SSH_CMD[@]}" "$TRUENAS_USER@$TRUENAS_HOST" "$@"
}

run_rsync() {
  set +e
  "$@" 2>&1 | tee -a "$LOGFILE"
  local rc="${PIPESTATUS[0]}"
  set -e
  if [[ "$rc" -ne 0 && "$rc" -ne 24 ]]; then
    return "$rc"
  fi
  return 0
}

sanitize_label() {
  local raw="$1"
  echo "$raw" | tr ' /:' '___' | tr -cd 'A-Za-z0-9._-'
}

ensure_prereqs() {
  mkdir -p "$LOG_DIR"
  [[ -r "$KEY_PATH" ]] || { echo "SSH key missing: $KEY_PATH" >&2; exit 1; }
  [[ -r "$KNOWN_HOSTS" ]] || { echo "known_hosts missing: $KNOWN_HOSTS" >&2; exit 1; }
  run_ssh "mkdir -p '$SNAP_DIR' '$DEST_BASE/meta'"
}

backup_dir_if_exists() {
  local src="$1"
  local rel="$2"
  local remote_dir
  remote_dir="$TARGET/data/$rel"
  if [[ -d "$src" ]]; then
    log "Backing up dir: $src -> $rel"
    run_ssh "mkdir -p '$remote_dir'"
    run_rsync rsync -aHAX --numeric-ids --human-readable -e "$RSYNC_SSH" \
      "$src/" "$TRUENAS_USER@$TRUENAS_HOST:$remote_dir/"
  else
    log "Skipping missing dir: $src"
  fi
}

create_snapshot() {
  local label="${1:-}"
  if [[ -z "$label" ]]; then
    label="manual-${STAMP}"
  fi
  label="$(sanitize_label "$label")"
  [[ -n "$label" ]] || { echo "Invalid label after sanitize" >&2; exit 1; }

  TARGET="$SNAP_DIR/$label"
  run_ssh "test ! -e '$TARGET'"
  run_ssh "mkdir -p '$TARGET/data' '$TARGET/meta'"

  log "Creating snapshot: $label"
  backup_dir_if_exists "$HOME/cheney" "home/tdj/cheney"
  backup_dir_if_exists "$HOME/reproduce-cheney" "home/tdj/reproduce-cheney"
  backup_dir_if_exists "$HOME/.openclaw" "home/tdj/.openclaw"
  backup_dir_if_exists "$HOME/.config/openclaw" "home/tdj/.config/openclaw"
  backup_dir_if_exists "$HOME/.ssh" "home/tdj/.ssh"

  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/system"

  if sudo -n test -f /etc/NetworkManager/system-connections/fallback99.nmconnection 2>/dev/null; then
    sudo -n install -D -m 600 /etc/NetworkManager/system-connections/fallback99.nmconnection \
      "$tmp/system/etc/NetworkManager/system-connections/fallback99.nmconnection"
  fi
  if sudo -n test -f /etc/ssh/sshd_config.d/00-lchl-access-policy.conf 2>/dev/null; then
    sudo -n install -D -m 600 /etc/ssh/sshd_config.d/00-lchl-access-policy.conf \
      "$tmp/system/etc/ssh/sshd_config.d/00-lchl-access-policy.conf"
  fi

  if [[ -d "$tmp/system/etc" ]]; then
    sudo -n chown -R "$USER:$USER" "$tmp/system/etc"
    sudo -n chmod -R u+rwX,go+rX "$tmp/system/etc"
    log "Backing up system config snippets"
    run_ssh "mkdir -p '$TARGET/data/etc'"
    run_rsync rsync -aHAX --numeric-ids --human-readable -e "$RSYNC_SSH" \
      "$tmp/system/etc/" "$TRUENAS_USER@$TRUENAS_HOST:$TARGET/data/etc/"
  fi

  local host kernel now_iso total_kb total_human
  host="$(hostname -f 2>/dev/null || hostname)"
  kernel="$(uname -r)"
  now_iso="$(date --iso-8601=seconds)"
  total_kb="$(run_ssh "du -sk '$TARGET/data' 2>/dev/null | cut -f1" || true)"
  total_human="unknown"
  if [[ "$total_kb" =~ ^[0-9]+$ ]]; then
    total_human="$(numfmt --to=iec --suffix=B "$((total_kb * 1024))")"
  fi

  cat > "$tmp/backup_info.md" <<META
# RB1 Manual Backup Metadata

- label: $label
- created_at: $now_iso
- source_host: $host
- kernel: $kernel
- destination: $TARGET
- approx_size: $total_human
- workflow: manual create/list/prune
META

  run_rsync rsync -a --human-readable -e "$RSYNC_SSH" \
    "$tmp/backup_info.md" "$TRUENAS_USER@$TRUENAS_HOST:$TARGET/meta/backup_info.md"

  rm -rf "$tmp"
  log "Snapshot complete: $label ($total_human)"
  log "Log file: $LOGFILE"
}

list_snapshots() {
  run_ssh "find '$SNAP_DIR' -mindepth 1 -maxdepth 1 -type d -printf '%TY-%Tm-%Td %TH:%TM %f\\n' | sort -r"
}

prune_snapshots() {
  local keep="${1:-}"
  [[ "$keep" =~ ^[0-9]+$ ]] || { echo "keep_count must be integer" >&2; exit 1; }

  mapfile -t entries < <(run_ssh "find '$SNAP_DIR' -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\\n' | sort -nr")
  local count="${#entries[@]}"
  if (( count <= keep )); then
    echo "Nothing to prune (count=$count keep=$keep)"
    return 0
  fi

  local i name
  for (( i=keep; i<count; i++ )); do
    name="${entries[$i]#* }"
    echo "Pruning: $name"
    run_ssh "rm -rf '$SNAP_DIR/$name'"
  done
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    create)
      ensure_prereqs
      create_snapshot "${2:-}"
      ;;
    list)
      ensure_prereqs
      list_snapshots
      ;;
    prune)
      ensure_prereqs
      prune_snapshots "${2:-}"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
