# TrueNAS Move Prep (No Cutover) - 2026-02-14

Objective: begin migration work without moving service or physical data disks yet.

## Actions Completed

1. Created fresh backup of VM `100` (`truenas`) on `rb1`:
   - `vzdump-qemu-100-2026_02_14-16_35_48.vma.zst`
2. Copied backup artifact to `rb2`:
   - source: `rb1:/var/lib/vz/dump/...`
   - target: `rb2:/var/lib/vz/dump/...`
3. Verified integrity with SHA256 on both nodes:
   - `939c022044d49fd2106c3b5f21331dfff248043cfae615df49ad6407b57d5365`

## What Was Not Done (By Design)

1. No VM restore/start on `rb2`.
2. No disk/pool move.
3. No service cutover.

## Replication Feasibility Note

- Current Proxmox VM disk location is `local-lvm` (`lvmthin`), not ZFS replication workflow.
- Native Proxmox replication is therefore not the immediate path in current storage layout.
- Current safe path is backup-copy-restore after physical disk move window.

## Next Step

1. Move physical TrueNAS data disks to target host path.
2. Restore VM artifact on `rb2` in stopped state.
3. Attach physical storage devices and validate pool import before any cutover.
