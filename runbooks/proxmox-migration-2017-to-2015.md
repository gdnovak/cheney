# Runbook: Proxmox VM Migration (RB14 2017 -> RB14 2015)
<!-- Running joke: this migration is phase one of the Cheney containment vessel. -->

## Scope Lock (Current Phase)

- In scope: compute/utility VM migration only.
- Out of scope: `truenas` VM (`100`) migration to `rb2`.
- `truenas` remains on `rb1-pve` for this phase.

## 1. Preconditions

- Source host (`rb14-2017`) is healthy and backups are current.
- Target host (`rb14-2015` / `rb2-pve`) is physically stable on power.
- Inventory files are updated (`inventory/hardware.md`, `inventory/vms.md`, `inventory/network-remote-access.md`).
- Freeze window defined: avoid unrelated config changes during migration.
- Mandatory gate `runbooks/phase-gate-full-device-inventory.md` is complete.
- Phase 1 completion confirmed, including MBA baseline as third-node continuity/quorum insurance.

## 2. Precheck

1. Capture source VM list, IDs, storage mapping, and network bridges.
2. Verify backup/restore viability for each VM.
3. Validate remote access to source and target hosts.
4. Confirm rollback path and available capacity on source host.
5. Confirm migration network path is stable (1GbE acceptable for this phase).

## 2a. TrueNAS No-Cutover Prep (Completed Once Per Window)

1. Produce fresh backup of VM `100` (`truenas`) on source host:
   - `vzdump 100 --mode snapshot --compress zstd --storage local`
2. Verify backup artifact integrity on source host:
   - `sha256sum /var/lib/vz/dump/<backup>.vma.zst`
3. Optional cold standby copy:
   - Copy artifact to an offline/archive location, but do not plan restore on `rb2` in this phase.
4. Keep `truenas` service active on `rb1`; no storage cutover in this runbook.

## 3. Migration Execution

1. Migrate low-criticality VM(s) first.
2. After each VM migration, verify boot, network reachability, and service health.
3. Update VM record in `inventory/vms.md` with result and timestamp.
4. Keep TrueNAS virtualized on `rb1` (do not switch to bare-metal TrueNAS in this phase).
5. Continue in defined migration order until in-scope compute/utility VMs are complete.

## 4. Post-Migration Validation

- Verify all migrated in-scope VMs are reachable and stable on `rb2-pve`.
- Verify `truenas` remains healthy and reachable on `rb1-pve`.
- Verify dependent services and automation jobs.
- Keep source host in ready-to-rollback state until validation window passes.

## 5. Rollback Criteria

Rollback a VM to source host if any of the following occur:

- Repeated boot failures on target.
- Persistent network/routing failure.
- Unacceptable service degradation.
- Power instability on target host affecting service continuity.

## 6. Rollback Steps

1. Stop affected VM on target host.
2. Restore/import from last known-good source/backup state.
3. Re-validate service on source.
4. Record incident and root-cause notes in `log.md` before retry.

## 7. 2015 Host Power-Risk Mitigations

- Secure physical power connection before cutover.
- Avoid moving/cable strain during migration window.
- Prefer staged migration windows with quick validation checkpoints.
- Keep one independent fallback node available at all times.
