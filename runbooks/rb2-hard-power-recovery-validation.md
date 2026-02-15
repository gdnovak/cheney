# rb2 Hard Power-Recovery Validation Runbook

Purpose: validate recovery behavior for batteryless `rb2` after true power loss.

## Preconditions

1. `rb2` is physically connected in intended steady-state location.
2. Known-good management path to at least one other node remains available.
3. Keep this runbook and `runbooks/interface-cutover-safe.md` open.
4. Do not change multiple cables/ports at once during this test.

## Step 1 - Capture Baseline

From control host:

```bash
ping -c 4 192.168.5.108
ssh rb2 'hostname; ip -4 addr show vmbr0 | grep -E "inet "; systemctl is-active pveproxy pvedaemon pve-cluster'
```

Expected:

1. Host reachable.
2. `vmbr0` has `192.168.5.108/22`.
3. `pveproxy/pvedaemon/pve-cluster` all `active`.

## Step 2 - Check AC-Restore BIOS Behavior (Manual)

On `rb2` firmware/BIOS settings, verify:

1. AC power restore is enabled (`Power On` after AC restore, naming varies by firmware).
2. Boot order keeps Proxmox disk first.

Record exact firmware option names in notes.

## Step 3 - True No-Power Test (Manual + Observed)

1. Remove AC power from `rb2` completely for at least 15 seconds.
2. Reconnect AC power.
3. Wait up to 5 minutes for autonomous boot.

From control host, poll:

```bash
for i in $(seq 1 30); do date '+%H:%M:%S'; ping -c 1 -W 1 192.168.5.108 >/dev/null && echo up && break || echo down; sleep 10; done
ssh rb2 'systemctl is-active pveproxy pvedaemon pve-cluster'
```

Optional helper (recommended during this step):

```bash
scripts/rb2_recovery_watch.sh
```

This logs ping/SSH/service recovery timing to `notes/rb2-recovery-watch-<timestamp>.log`.

## Step 4 - Fallback if Auto-Boot Fails

1. Manually power `rb2` on.
2. Confirm management recovery:

```bash
ping -c 4 192.168.5.108
ssh rb2 'ip -4 addr show vmbr0 | grep -E "inet "; grep -nE "bridge-ports" /etc/network/interfaces'
```

3. If needed, run interface checks via `runbooks/interface-cutover-safe.md`.

## Step 4b - Optional Smart-Plug Hard Reset Validation

Use this only if you add a smart plug for unattended recovery.

1. Confirm smart-plug control API/app is reachable from your control host.
2. Power-cycle `rb2` outlet (off 15s, then on).
3. Run the same recovery poll sequence used in Step 3.
4. Record median recovery time across at least 2 cycles.

Pass criteria for smart-plug path:

1. Host consistently returns to SSH and healthy services.
2. Recovery timing is predictable enough for unattended runbooks.
3. No filesystem/service corruption signs after repeated cycles.

## Step 5 - Validate Watcher/Continuity

From `rb1` / `tsDeb` path, confirm continuity services still healthy:

```bash
ssh rb1-pve 'qm list'
ssh rb1-pve 'qm guest exec 101 -- systemctl is-active tsdeb-watchdog.timer tsdeb-watchdog.service'
```

## Pass/Fail Criteria

Pass:

1. `rb2` returns without manual intervention after AC restore.
2. Management IP and Proxmox services return healthy.
3. No regression on existing node/VM continuity checks.

Conditional pass:

1. Manual button press required, but post-boot services healthy and stable.
2. Document as known limitation and add manual recovery step to operational checklist.

Fail:

1. Repeated inability to return to healthy service state.
2. IP/bridge instability or service flapping after recovery.

## Logging Requirements

Update both:

1. `/home/tdj/cheney/log.md` with timestamped outcome and evidence.
2. `/home/tdj/log.md` pointer update.
