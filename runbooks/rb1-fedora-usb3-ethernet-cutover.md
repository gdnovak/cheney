# Runbook: rb1 Fedora USB Ethernet Cutover (NetworkManager)

Purpose: safely move `rb1-fedora` management and fallback VLAN from one USB Ethernet adapter to another with rollback guardrails.

## Scope

- Host: `rb1-fedora`
- Management path: primary LAN SSH (`rb1-admin` / `rb1`)
- Fallback path: VLAN99 (`172.31.99.1/30`)

## Preconditions

1. Current host reachability confirmed from `rb2` on both primary LAN and VLAN99.
2. New adapter is physically attached and shows carrier (`Link detected: yes`).
3. Old adapter remains attached during initial cutover so rollback can recover if needed.

## Adapter Identity Pattern

Use this to map old/new paths before any config mutation:

```bash
ssh rb1-admin 'ip -br link; ip -4 -br addr'
ssh rb1-admin 'for i in /sys/class/net/*; do n=$(basename "$i"); [ "$n" = lo ] && continue; echo "=== $n ==="; udevadm info -q property -p "$i" | grep -E "ID_NET_DRIVER|ID_VENDOR_ID|ID_MODEL_ID|DEVPATH"; done'
```

## Guarded Cutover Flow

1. Arm timed rollback via `systemd-run` (3 minutes) that re-activates old primary + old fallback and deactivates new profiles.
2. Keep new primary connection up (`Wired connection 2` in current layout).
3. Create fallback VLAN on new NIC with short interface name to avoid 15-char Linux limit.

Important: using `<long-ifname>.99` can fail with:
`interface name is longer than 15 characters`.

Current known-good fallback shape on new NIC:

```bash
nmcli con add type vlan \
  con-name fallback99-new \
  ifname fb99 \
  dev enp0s20f0u1c2 \
  id 99 \
  ipv4.method manual \
  ipv4.addresses 172.31.99.1/30 \
  ipv6.method disabled \
  connection.autoconnect yes
```

4. Deactivate old fallback first, then activate new fallback.
5. Deactivate old primary and set old profiles to `autoconnect=no`.
6. Validate on new path, then cancel rollback timer.

## Post-Cutover Validation

```bash
ssh rb1-admin 'nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active; ip -4 -br addr'
ssh rb2 'ping -c 20 -i 0.5 192.168.5.114; ping -c 20 -i 0.5 172.31.99.1'
```

Throughput matrix:

- `notes/rb1-nic-cutover-YYYYMMDD-HHMMSS/post-switch-iperf-rb2-to-rb1.txt`
- `notes/rb1-nic-cutover-YYYYMMDD-HHMMSS/post-switch-iperf-rb1-to-rb2.txt`

WoL checks:

```bash
ssh rb1-admin 'sudo ethtool enp0s20f0u1c2'
ssh rb1-admin 'sudo ethtool -s enp0s20f0u1c2 wol g'
```

## Acceptance Criteria

1. Primary SSH stable on new adapter.
2. VLAN99 fallback (`172.31.99.1`) stable on new adapter.
3. Before/after throughput does not regress materially.
4. Kernel logs show no new NIC reset/fatal errors during cutover window.
5. WoL capability difference is explicitly recorded.

## Current 2026-02-20 Outcome Snapshot

- New active primary: `enp0s20f0u1c2` at `192.168.5.114/22`.
- New active fallback: `fb99` (`fallback99-new`) at `172.31.99.1/30`.
- Throughput: effectively unchanged from pre-cutover 1Gb baseline.
- WoL: regression on active adapter (`ethtool -s ... wol g` unsupported).
