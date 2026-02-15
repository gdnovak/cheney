# Peripheral and Dock Inventory

| peripheral_id | device_name | interface | functions | current_usage | known_constraints | last_verified_at |
|---|---|---|---|---|---|---|
| dock-wd19 | Dell WD19 | USB-C | Ethernet + display + USB expansion | Available for node connectivity/testing | Verify stable NIC behavior under sustained uptime | 2026-02-13 23:45 EST |
| dock-k-series | K-series USB-C dock (exact model TBD) | USB-C + legacy DP/TB-style port | Ethernet + HDMI + USB3 | Available; candidate for staging host connectivity | Exact model unknown; port-mode compatibility needs validation | 2026-02-13 23:45 EST |
| kvm-2port-dp-usb3 | 2-port KVM switch (dual DP + USB3 host links) | DisplayPort + USB3 | Switches keyboard/mouse/USB and optional video between 2 hosts | Available; better suited for USB/control-path switching than display mux in current setup | DP->USB-C/DP monitor chain is unreliable; only one regular DP monitor is available for stable direct DP output | 2026-02-14 19:42 EST |
| mba-adapter-hub | MacBook Air adapter hub (miniDP/Thunderbolt-era) | Mini DisplayPort/Thunderbolt legacy connector | DP/HDMI breakout + USB3 expansion | Used with MBA fallback node; current dummy HDMI plug is connected via this hub | Legacy adapter chain may affect reliability and wake behavior | 2026-02-14 03:13 EST |
| mba-direct-video-alt | MBA direct thunderbolt->HDMI path (alternate) | Direct TB/miniDP to HDMI adapter path | Alternative display/dummy-plug path bypassing hub | Not yet validated vs hub path | Unknown whether better than hub for closed-lid reboot reliability; test later | 2026-02-14 03:13 EST |
| razer-core-net | Razer Core network path | Thunderbolt to host | Acts as Ethernet path in current environment | Available as alternate Ethernet path | eGPU enclosure state can couple network behavior to TB stability | 2026-02-13 23:45 EST |

## Notes

- User reports all docks plus the Razer Core can provide Ethernet connectivity.
- Current active Razer host is running via USB Ethernet path.
- MBA currently uses dummy HDMI via hub; direct TB->HDMI path is retained as fallback test option.
- 2-port DP/USB3 KVM is in inventory and reliable for USB/control switching, but not preferred for display due to DP->USB-C monitor conversion issues.
- During eGPU passthrough validation on `rb1`, record HDMI dummy-plug state explicitly (`present`/`absent`) because display emulation can influence GPU init/reset behavior.
