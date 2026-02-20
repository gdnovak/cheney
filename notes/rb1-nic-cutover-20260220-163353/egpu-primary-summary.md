# rb1 eGPU-Primary Network Summary

Date: 2026-02-20
Host: `rb1-fedora`

## Goal

Shift preferred network routing to eGPU Ethernet (`enp20s0u1`) while keeping USB3 adapter (`enp0s20f0u1c2`) as fallback.

## Final Network Shape

- Primary route NIC: `enp20s0u1` (`egpu-primary`), IP `192.168.5.115/22`, route metric `80`.
- Fallback NIC: `enp0s20f0u1c2` (`Wired connection 2`), IP `192.168.5.114/22`, route metric `103`.
- Fallback VLAN: `fb99` (`fallback99-new`) on `enp0s20f0u1c2`, IP `172.31.99.1/30`.

## Validation Results

1. Preferred route behavior
- With both links up: default route uses `enp20s0u1` (`192.168.5.115`).
- Source route check to internet/LAN resolves via eGPU NIC as expected.

2. Failover behavior
- Simulated eGPU failure (`nmcli con down egpu-primary`) moved default route to fallback adapter (`192.168.5.114`).
- `rb2 -> 192.168.5.114` and `rb2 -> 172.31.99.1` both remained `0%` loss.
- Restoring `egpu-primary` returned default route to eGPU NIC.

3. Throughput (`rb2 -> rb1`, TCP P1, 20s)
- eGPU path (`192.168.5.115`): `929 Mbps` sender (`197` retrans).
- Fallback path (`192.168.5.114`): `933 Mbps` sender (`99` retrans).
- Conclusion: both paths are 1Gb-class; eGPU path is not faster in this test.

4. WoL
- eGPU NIC (`enp20s0u1`) reports `Supports Wake-on: pg` and `Wake-on: g`.
- Magic packet to `90:20:3a:1b:e8:d6` captured on `enp20s0u1` from `rb2`.
- USB fallback NIC remains no-hardware-WoL (`cdc_ncm` path).

## Operational Notes

- Keep `rb1-admin` on stable fallback IP `192.168.5.114` for recovery access.
- Watchdog mapping now pings `192.168.5.114` but sends WoL to eGPU MAC (`90:20:3a:1b:e8:d6`).
- If eGPU cable is unplugged, WoL to eGPU NIC will not work; smart-plug/manual path remains fallback.

## Artifacts

- `egpu-primary-failover-validation.txt`
- `egpu-vs-fallback-throughput.txt`
- `egpu-primary-wol-send.txt`
- `egpu-primary-wol-pcap.txt`
