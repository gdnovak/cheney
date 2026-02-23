# WoL From `rb2` Validation

## Objective

Validate that `rb2` can emit Wake-on-LAN packets for key hosts and keep a repeatable sender command.

## Sender Command

Use script:

```bash
cd ~/cheney
scripts/rb2_send_wol.sh --list
scripts/rb2_send_wol.sh rb1 rb2 mba
scripts/rb2_send_wol.sh fedora
```

Defaults:
- sender host: `rb2`
- broadcast: `255.255.255.255` (safe default for current `/22` LAN)

Override example:

```bash
scripts/rb2_send_wol.sh --broadcast 192.168.7.255 rb1
```

## Current Host MAC Map

- `rb1`: `90:20:3a:1b:e8:d6` (eGPU NIC)
- `rb2`: `00:05:1b:de:7e:6e`
- `mba`: `00:24:32:16:8e:d3`
- `fedora`: `3c:cd:36:67:e2:45`

## 2026-02-22 Validation Findings

1. `rb2` has working sender utility: `/usr/bin/wakeonlan`.
2. `mba` capture (`tcpdump` on `vmbr0`) confirmed WoL UDP broadcasts from `192.168.5.108` to `255.255.255.255:9`.
3. `rb1` capture on `enp20s0u1` saw no packets in this pass.
4. `rb1` capture on `any` showed WoL packets arriving on `enp0s20f0u1c2`.
5. Controlled suspend-to-wake validation for local workstation (`fedora`) succeeded:
   - `rb2` watcher detected host drop.
   - `rb2` sent 3 WoL packets to `3c:cd:36:67:e2:45`.
   - Host resumed from S3 and became ping-reachable again.
   - Artifact: `notes/wol-artifacts/rb2-wol-wake-test-fedora-20260222.log`.
6. Non-disruptive packet emission pass (`rb1`, `rb2`, `mba`) completed:
   - capture on `rb2` interface `enx00051bde7e6e` shows 3 WoL UDP broadcasts from `192.168.5.108` to `255.255.255.255:9`.
   - payload bytes include each target MAC:
     - `rb1`: `90:20:3a:1b:e8:d6`
     - `rb2`: `00:05:1b:de:7e:6e`
     - `mba`: `00:24:32:16:8e:d3`
   - Artifact: `notes/wol-artifacts/rb2-wol-multi-target-emission-20260222-195432.log`.
7. SSH key-path checks for same host set passed non-interactively:
   - `ssh -o BatchMode=yes rb1-admin`
   - `ssh -o BatchMode=yes rb2`
   - `ssh -o BatchMode=yes mba`

## Interpretation

- `rb2` broadcast WoL emission works.
- `mba` appears correctly reachable for WoL broadcasts.
- For `rb1`, packet path currently appears tied to USB management NIC traffic view in this test; verify physical cable/topology for the eGPU NIC path before relying on eGPU-MAC wake from fully off state.
- Per current operator direction, no per-host suspend/off wake cycle was required for `rb1`/`rb2`/`mba` in this pass; packet-send validation is the accepted check.

## Next Validation (optional)

1. If full wake assurance is needed later, run attended wake tests one host at a time.
2. For `rb1`, test with only intended wake NIC/cable path connected, then confirm wake from desired state (suspend or S5).
3. Keep packet-send verification (`scripts/rb2_send_wol.sh`) as quick preflight before unattended windows.
