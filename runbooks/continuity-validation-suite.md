# Continuity Validation Suite (Reproducible, No-Execution Template)

Purpose: provide a deterministic, reusable validation script for future agents/sessions to run after recabling, reboots, or major network changes.

This document is an execution template. It does not imply tests should be run immediately.

## Scope

- Proxmox host health on:
  - `rb1-pve` (`192.168.5.98`)
  - `rb2-pve` (`192.168.5.108`)
  - `mba-pve` / `kabbalah` (`192.168.5.66`)
- Utility tailscale VM health on:
  - `lchl-tsnode-rb2` (`VMID 201`, `192.168.5.112`)
  - `lchl-tsnode-mba` (`VMID 301`, `192.168.5.113`)
- Fallback VLAN99 management path:
  - `rb1 vmbr0.99` = `172.31.99.1/30`
  - `rb2 vmbr0.99` = `172.31.99.2/30`
- Continuity helper VM:
  - `tsDeb` (`VMID 101` on `rb1`)

## Preconditions

1. Do not move cables during test execution.
2. SSH keys are available:
   - `rb1-pve`, `rb2-pve`, `mba-pve` aliases configured.
   - `~/.ssh/id_ed25519` for `lchl-tsnode-*`.
   - `~/.ssh/id_ed25519_rb2-pve` for fallback jump checks.
3. A maintenance window is active for host reboot steps.

## Test 0 - Baseline Snapshot

```bash
date
ssh rb1-pve 'hostname; qm list'
ssh rb2-pve 'hostname; qm list; qm config 201 | grep -E "^(name|onboot|ipconfig0):"'
ssh mba-pve 'hostname; qm list; qm config 301 | grep -E "^(name|onboot|ipconfig0):"'
ssh rb1-pve 'qm config 100 | grep -E "^(name|memory|balloon):"'
```

Expected:

1. `qm status 100/101/201/301` all `running`.
2. `onboot: 1` for `201` and `301`.
3. TrueNAS (`100`) memory policy matches current baseline target.

## Test 1 - Utility VM Reboot + Tailscale Reconnect

```bash
ssh rb2-pve 'qm reboot 201 || true'
ssh mba-pve 'qm reboot 301 || true'

ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes root@192.168.5.112 \
  'hostname; systemctl is-active tailscaled; tailscale status --json | grep BackendState'
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes root@192.168.5.113 \
  'hostname; systemctl is-active tailscaled; tailscale status --json | grep BackendState'
```

Expected:

1. `tailscaled` reports `active` on both utility VMs.
2. `BackendState` is `Running` on both utility VMs.

## Test 2 - Host Reboot Sequence (One at a Time)

Recommended order: `rb2` -> `rb1` -> `mba`.

After each host reboot, verify:

```bash
ssh <host> 'hostname; systemctl is-active pveproxy pvedaemon pve-cluster | tr "\n" " "; echo'
```

Then verify onboot VMs on that host:

```bash
ssh rb2-pve 'qm status 201'
ssh rb1-pve 'qm status 100; qm status 101'
ssh mba-pve 'qm status 301'
```

Note: Onboot VMs can briefly show `stopped`/`activating` immediately after host boot. Allow 1-3 minutes before declaring failure.

## Test 3 - Fallback Path Persistence + Reachability

Check persistence config on both hosts:

```bash
ssh rb1-pve 'grep -nE "vmbr0\\.99|172\\.31\\.99\\.1/30|vlan-raw-device vmbr0" /etc/network/interfaces'
ssh rb2-pve 'grep -nE "vmbr0\\.99|172\\.31\\.99\\.2/30|vlan-raw-device vmbr0" /etc/network/interfaces'
```

Check interface up-state:

```bash
ssh rb1-pve 'ip -4 -br addr show dev vmbr0.99'
ssh rb2-pve 'ip -4 -br addr show dev vmbr0.99'
```

Check fallback connectivity:

```bash
ssh rb1-pve 'ping -c 3 -W 2 172.31.99.2'
ssh -J rb1-pve -i ~/.ssh/id_ed25519_rb2-pve -o IdentitiesOnly=yes root@172.31.99.2 \
  'hostname; ip -4 -br addr show dev vmbr0.99'
```

Expected:

1. `vmbr0.99` exists on both hosts.
2. `rb1` reaches `rb2` over `172.31.99.0/30`.
3. Fallback SSH via jump host succeeds.

## Test 4 - Security Guardrail Checks (VLAN99)

```bash
ssh rb1-pve 'ip route show | grep -E "default|172\\.31\\.99\\.0/30"'
ssh rb2-pve 'ip route show | grep -E "default|172\\.31\\.99\\.0/30"'
```

Expected:

1. No fallback interface default route.
2. Fallback subnet present as direct host route only.
3. No evidence of fallback usage as general forwarding path.

## Test 5 - Continuity Service Check (`tsDeb`)

```bash
ssh rb1-pve 'qm status 101'
ssh rb1-pve 'qm guest exec 101 -- systemctl is-active tsdeb-watchdog.timer tsdeb-watchdog.service'
```

Expected:

1. `101` is `running`.
2. Timer state is `active`.
3. Service state can be `inactive` between timer triggers.

## Pass/Fail Criteria

Pass if all are true:

1. All hosts reachable with active Proxmox core services.
2. `201` and `301` auto-start and reconnect to tailscale.
3. `vmbr0.99` persists on both hosts and fallback reachability works.
4. `tsDeb` watchdog timer remains active.

Fail if any are true:

1. A host loses `pveproxy/pvedaemon/pve-cluster` post-reboot.
2. Utility VM fails to return to `BackendState=Running`.
3. Fallback path missing on either host after reboot.
4. `tsDeb` watchdog timer remains non-active after settling period.

## Failure Handling

1. Capture current state in `log.md` with timestamp.
2. Avoid additional concurrent changes.
3. Restore last-known-good network/VM config before retrying.
4. Retry only one failing step at a time.
