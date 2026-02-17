# RB1 Operational Baseline Snapshot (20260216-204915)

Captured: 2026-02-16 20:49:15 EST

## Host Identity
```text
rb1-fedora
54381a9d-eca7-40e6-8b2e-9052e1ce52d4
6.18.9-200.fc43.x86_64
tdj
```

## SSH Effective Policy
```text
permitrootlogin without-password
pubkeyauthentication yes
passwordauthentication no
```

## Network State
```text
lo               UNKNOWN        127.0.0.1/8 
enp0s20f0u6      UP             192.168.5.107/22 
enp0s20f0u6.99@enp0s20f0u6 UP             172.31.99.1/30 
```

## Fallback VLAN99 Checks
```text
host_to_peer_fallback=ok
peer_to_host_fallback=ok
```

## NVIDIA/eGPU State
```text
index, pci.bus_id, name, display_active, pstate, pcie.link.gen.current, pcie.link.width.current
0, 00000000:01:00.0, NVIDIA GeForce GTX 1060, Enabled, P8, 1, 16
1, 00000000:0F:00.0, NVIDIA GeForce GTX 1060 6GB, Disabled, P8, 1, 4
0f:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP106 [GeForce GTX 1060 6GB] [10de:1c03] (rev a1)
0f:00.1 Audio device [0403]: NVIDIA Corporation GP106 High Definition Audio Controller [10de:10f1] (rev a1)
```

## Thunderbolt Authorization
```text
 * Razer Core
   |- type:          peripheral
   |- name:          Core
   |- vendor:        Razer
   |- uuid:          000429b5-f8dc-2701-ffff-ffffffffffff
   |- generation:    Thunderbolt 3
   |- status:        authorized
   |  |- domain:     cf030000-0070-6f08-a338-069985d3211e
   |  |- rx speed:   20 Gb/s = 2 lanes * 10 Gb/s
   |  |- tx speed:   20 Gb/s = 2 lanes * 10 Gb/s
   |  `- authflags:  none
   |- authorized:    Tue 17 Feb 2026 01:08:47 AM UTC
   |- connected:     Tue 17 Feb 2026 01:08:47 AM UTC
   `- stored:        Tue 17 Feb 2026 12:05:03 AM UTC
      |- policy:     iommu
      `- key:        no

 * Razer Core #2
   |- type:          peripheral
   |- name:          Core
   |- vendor:        Razer
   |- uuid:          00024978-2f5f-2701-ffff-ffffffffffff
   |- generation:    Thunderbolt 3
   |- status:        authorized
   |  |- domain:     cf030000-0070-6f08-a338-069985d3211e
   |  |- rx speed:   40 Gb/s = 2 lanes * 20 Gb/s
   |  |- tx speed:   40 Gb/s = 2 lanes * 20 Gb/s
   |  `- authflags:  none
   |- authorized:    Tue 17 Feb 2026 01:08:48 AM UTC
   |- connected:     Tue 17 Feb 2026 01:08:48 AM UTC
   `- stored:        Tue 17 Feb 2026 12:05:03 AM UTC
      |- policy:     iommu
      `- key:        no

```

## Service Posture (selected)
```text
enabled
enabled
enabled
enabled
enabled
enabled
disabled
disabled
active
active
active
active
active
inactive
inactive
inactive
```
