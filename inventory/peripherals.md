# Peripheral and Dock Inventory

| peripheral_id | device_name | interface | functions | current_usage | known_constraints | last_verified_at |
|---|---|---|---|---|---|---|
| dock-wd19 | Dell WD19 | USB-C | Ethernet + display + USB expansion | Available for node connectivity/testing | Verify stable NIC behavior under sustained uptime | 2026-02-13 23:45 EST |
| dock-k-series | K-series USB-C dock (exact model TBD) | USB-C + legacy DP/TB-style port | Ethernet + HDMI + USB3 | Available; candidate for staging host connectivity | Exact model unknown; port-mode compatibility needs validation | 2026-02-13 23:45 EST |
| mba-adapter-hub | MacBook Air adapter hub (miniDP/Thunderbolt-era) | Mini DisplayPort/Thunderbolt legacy connector | DP/HDMI breakout + USB3 expansion | Used with MBA fallback node | Legacy adapter chain may affect reliability and wake behavior | 2026-02-13 23:45 EST |
| razer-core-net | Razer Core network path | Thunderbolt to host | Acts as Ethernet path in current environment | Available as alternate Ethernet path | eGPU enclosure state can couple network behavior to TB stability | 2026-02-13 23:45 EST |

## Notes

- User reports all docks plus the Razer Core can provide Ethernet connectivity.
- Current active Razer host is running via USB Ethernet path.
