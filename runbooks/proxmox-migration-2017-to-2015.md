# Runbook: Proxmox VM Migration (RB14 2017 -> RB14 2015)
<!-- Running joke: this migration is phase one of the Cheney containment vessel. -->

## 1. Preconditions

- Source host (`rb14-2017`) is healthy and backups are current.
- Target host (`rb14-2015`) is physically stable on power.
- Inventory files are updated (`inventory/hardware.md`, `inventory/vms.md`, `inventory/network-remote-access.md`).
- Freeze window defined: avoid unrelated config changes during migration.

## 2. Precheck

1. Capture source VM list, IDs, storage mapping, and network bridges.
2. Verify backup/restore viability for each VM.
3. Validate remote access to source and target hosts.
4. Confirm rollback path and available capacity on source host.

## 3. Migration Execution

1. Migrate low-criticality VM(s) first.
2. After each VM migration, verify boot, network reachability, and service health.
3. Update VM record in `inventory/vms.md` with result and timestamp.
4. Continue in defined migration order until critical VMs are complete.

## 4. Post-Migration Validation

- Verify all migrated VMs are reachable and stable on `rb14-2015`.
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
