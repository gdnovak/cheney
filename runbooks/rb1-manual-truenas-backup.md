# Runbook: `rb1` Manual Backup to TrueNAS HDD Dataset

Date: 2026-02-20

## Purpose

Provide a manual (operator-directed) backup workflow for `rb1-fedora` to TrueNAS HDD storage with no auto-rotation timers.

## Current Destination

- TrueNAS dataset: `oyPool/rb1AssistantBackups`
- Mountpoint: `/mnt/oyPool/rb1AssistantBackups`
- Quota: `30G`
- Snapshot root: `/mnt/oyPool/rb1AssistantBackups/snapshots`

## Access Path

- Backup user on TrueNAS: `macmini_bu`
- `rb1` key path: `~/.ssh/id_ed25519_truenas_rb1`
- `rb1` SSH host alias: `truenas-rb1` (`192.168.5.100`)
- Backup script on `rb1`: `/home/tdj/bin/rb1_truenas_backup.sh`
- Repo-tracked copy: `scripts/rb1_truenas_backup.sh`

## Backed Up Scope (Current)

1. `/home/tdj/cheney`
2. `/home/tdj/reproduce-cheney` (if present)
3. `/home/tdj/.openclaw`
4. `/home/tdj/.config/openclaw`
5. `/home/tdj/.ssh`
6. `/etc/NetworkManager/system-connections/fallback99.nmconnection` (if present)
7. `/etc/ssh/sshd_config.d/00-lchl-access-policy.conf` (if present)

## Commands

Create a labeled snapshot:

```bash
/home/tdj/bin/rb1_truenas_backup.sh create baseline-YYYY-MM-DD
```

List snapshots:

```bash
/home/tdj/bin/rb1_truenas_backup.sh list
```

Prune manually to keep N:

```bash
/home/tdj/bin/rb1_truenas_backup.sh prune 2
```

## Operator Policy

1. Keep only `2-3` snapshots at any time.
2. Run backups manually before risky changes (driver updates, routing changes, large config edits).
3. Run `prune` manually after verification of a new snapshot.

## Verification

1. Confirm dataset exists and quota is set:

```bash
ssh rb2-pve 'qm guest exec 100 -- /bin/bash -lc "zfs get -H -o property,value quota oyPool/rb1AssistantBackups"'
```

2. Confirm snapshots present:

```bash
ssh rb1-admin '/home/tdj/bin/rb1_truenas_backup.sh list'
```

3. Inspect latest snapshot metadata:

```bash
ssh rb2-pve 'qm guest exec 100 -- /bin/bash -lc "latest=$(find /mnt/oyPool/rb1AssistantBackups/snapshots -mindepth 1 -maxdepth 1 -type d | sort | tail -n1); cat \"$latest/meta/backup_info.md\""'
```

