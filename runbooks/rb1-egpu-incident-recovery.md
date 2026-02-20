# rb1 eGPU Incident Recovery Runbook

Purpose: provide one deterministic recovery path when `rb1` eGPU/TB behavior becomes unstable (detach/reattach faults, missing external GPU, or post-incident uncertainty).

## Preconditions

1. `rb1` management IP remains reachable (`192.168.5.114`) or console access is available.
2. `rb2` remains reachable for fallback cross-checks.
3. Keep changes minimal during incident handling (no concurrent recabling experiments).

## Primary Recovery Rule

Do not loop repeated hot-unplug/replug attempts when instability is observed.  
Use controlled reboot + structured validation.

## Step 1 - Quick Symptom Confirmation

```bash
ssh rb1-admin 'nvidia-smi --query-gpu=index,pci.bus_id,name --format=csv'
ssh rb1-admin 'ip -4 -br addr show fb99'
ssh rb2 'ping -c 2 -W 1 172.31.99.1 >/dev/null && echo peer_to_host_fallback=ok'
```

If external GPU is missing or behavior is inconsistent, continue to Step 2.

## Step 2 - Controlled Recovery Validation (No Reboot Path)

```bash
scripts/rb1_recovery_validate.sh --scenario incident_quick_check
```

Outputs:

1. Matrix row: `notes/rb1-recovery-matrix-YYYYMMDD.md`
2. Artifact: `notes/rb1-recovery-artifacts/rb1-recovery-incident_quick_check-<timestamp>.log`

If result is `PASS`, stop here.

## Step 3 - Controlled Reboot Recovery (Preferred)

```bash
scripts/rb1_recovery_validate.sh \
  --scenario incident_reboot_recovery \
  --reboot \
  --timeout 360
```

This performs reboot + post-boot verification in one run.

## Step 4 - If SSH Is Not Returning

Use local console on `rb1`:

```bash
sudo systemctl status --no-pager sshd
sudo systemctl restart sshd
sudo ss -ltnp | grep ':22'
```

Then rerun Step 2.

## Step 5 - Close Incident

Record in project logs:

1. `log.md` entry with timestamp, symptom, recovery path used, and outcome.
2. `/home/tdj/log.md` pointer update.

## Post-Incident Acceptance

Incident is considered recovered only if all are true:

1. `scripts/rb1_recovery_validate.sh` reports `PASS`.
2. External GPU is visible (`0F:00.0`) in `nvidia-smi`.
3. Fallback VLAN99 checks pass both directions (`rb1` <-> `rb2`).
4. SSH policy remains hardened (`permitrootlogin without-password`, `passwordauthentication no`).

## Scheduled Use (Maintenance)

Run this validator after major host changes:

1. Kernel updates
2. NVIDIA stack updates
3. Thunderbolt/firmware-related adjustments
