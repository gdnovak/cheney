# Runbook: `rb1` Fedora Baremetal Pivot (`truenas` -> `rb2`)

Purpose: transition from current Proxmox-on-`rb1` layout to:

1. `rb2` as Proxmox storage-primary host (`truenas` target).
2. `rb1` as Fedora baremetal GPU/agent host.

## Scope

In scope:

1. Move `truenas` workload from `rb1` to `rb2`.
2. Preserve continuity paths (management + fallback VLAN99 + tailscale utility nodes).
3. Reinstall `rb1` as Fedora baremetal after storage continuity is validated.

Out of scope:

1. Final production assistant stack rollout.
2. Broad model tuning/benchmarking.

## Preconditions

1. `rb1` and `rb2` are both reachable over management LAN.
2. Fallback VLAN path is healthy:
   - `rb1` `172.31.99.1/30`
   - `rb2` `172.31.99.2/30`
3. Fresh `truenas` backup artifact exists and checksum is recorded.
4. `rb2` power path is stable for migration window.
5. Current switch/cable map is documented.

## Phase A: Storage Safety Prep

1. Validate `truenas` health on `rb1` (`zpool status`, service state).
2. Create a fresh VM backup for `truenas` (`vzdump`).
3. Copy backup artifact to `rb2` and verify SHA256 match.
4. Record rollback command path before cutover.

## Phase B: Move `truenas` to `rb2`

1. Restore/import `truenas` VM on `rb2`.
2. Keep original `rb1` VM powered off (not deleted) during burn-in window.
3. Validate on `rb2`:
   - guest boots reliably
   - pool health is clean
   - shares/services reachable
4. Run at least one full backup/restore dry check from new location.

Rollback:

1. Stop `rb2` `truenas`.
2. Re-enable original `rb1` `truenas`.
3. Repoint service consumers.

## Phase C: `rb1` Baremetal Conversion

1. Export/backup `rb1` Proxmox configs and critical artifacts.
2. Confirm no critical VM remains on `rb1`.
3. Install Fedora Server/Cloud baremetal on `rb1`.
4. Re-establish:
   - management IP plan
   - SSH keys
   - tailscale (if needed)
   - local tooling (`git`, `tmux`, `jq`, `python3`, etc.)
5. Keep `rb1` eGPU Ethernet unplugged for management isolation; use dedicated USB NIC for management.

## Phase D: Post-Pivot Validation

1. `rb2` storage services stable for at least one overnight window.
2. `rb1` boots and remains reachable after reboot.
3. GPU availability validated on `rb1` baremetal.
4. Continuity controls still pass:
   - host SSH
   - fallback VLAN
   - tailscale utility nodes

## Notes from Current Testing

1. Proxmox + eGPU passthrough on `rb1` currently binds VFIO but repeatedly loses guest SSH/QGA when GPU is attached.
2. This pivot is motivated by reducing virtualization-layer GPU fragility for the primary agent host.
