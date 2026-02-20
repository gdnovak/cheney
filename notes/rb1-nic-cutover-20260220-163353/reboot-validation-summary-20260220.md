# rb1 eGPU-Primary Reboot Validation Summary

Date: 2026-02-20
Host: `rb1-fedora`

## Result

PASS.

## Evidence

- Pre-reboot boot ID: `dc0ee06b-7cda-423e-9a09-6fb4d5cd766b`
- Post-reboot boot ID: `674570f7-c8be-4b22-9cd0-b536fbfd18f6`
- Reboot downtime window observed: `26s` (`down_seen=1`, `up_seen=1`)
- Artifact log: `reboot-validation-20260220-172904.log`

## Post-Boot Network State

- `egpu-primary` active on `enp20s0u1` (`192.168.5.115/22`)
- `Wired connection 2` active on `enp0s20f0u1c2` (`192.168.5.114/22`)
- `fallback99-new` active on `fb99` (`172.31.99.1/30`)
- Route preference preserved:
  - primary: metric `80` on eGPU NIC
  - fallback: metric `300` on USB NIC

## Post-Boot WoL State

- `enp20s0u1` reports:
  - `Supports Wake-on: pg`
  - `Wake-on: g`
  - `Link detected: yes`

## Failover Sanity After Reboot

- Bringing `egpu-primary` down moved default route to USB fallback (`192.168.5.114`, metric `300`).
- `rb2` ping checks during fallback showed `0%` loss to:
  - `192.168.5.114`
  - `172.31.99.1`
- Restoring `egpu-primary` returned default route to eGPU NIC (metric `80`).
