# Runbook: Closed-Lid Reboot Validation

Use this before recabling or migration work to confirm each node can reboot and return headless with lid closed.

## Scope

- `rb1-pve`
- `rb2-pve`
- `mba` (`kabbalah`)

## Preconditions

1. SSH aliases work (`rb1-pve`, `rb2`, `mba`).
2. `HandleLidSwitch=ignore`, `HandleLidSwitchExternalPower=ignore`, `HandleLidSwitchDocked=ignore` are set on each host.
3. Dummy-plug/display setup is in the intended steady state for this test window.
4. No critical maintenance job is running on the hosts.

## Test Procedure (per host)

1. Confirm host reachable by SSH and ping.
2. Close lid fully.
3. Trigger reboot:
   - `ssh <host> 'reboot'`
4. Observe return:
   - ping recovery
   - SSH recovery
   - Proxmox services healthy (`pveproxy`, `pvedaemon`, `pve-cluster`)
5. Repeat one more cycle (2 passes total).

## Pass Criteria

- 2/2 reboot cycles succeed with lid closed and no manual intervention.

## Failure Handling

1. Record exact symptom (no ping, ping/no SSH, SSH/no Proxmox services).
2. Test with current dummy-plug path vs alternate path (for MBA, hub vs direct TB->HDMI) one change at a time.
3. Keep that host out of recabling/migration critical path until stability is proven.
