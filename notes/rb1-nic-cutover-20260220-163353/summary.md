# rb1 NIC Cutover Summary

Date: 2026-02-20
Host: `rb1-fedora`

## Change

- Old management path: `enp0s20f0u6` (`192.168.5.107`), fallback `enp0s20f0u6.99` (`fallback99`).
- New management path: `enp0s20f0u1c2` (`192.168.5.114`), fallback `fb99` (`fallback99-new`).
- Old profiles retained with `autoconnect=no` for rollback.

## Before vs After

| metric | before | after | delta |
|---|---:|---:|---:|
| TCP P1 `rb2 -> rb1` | 942 Mbps | 943 Mbps | +1 Mbps |
| TCP P4 `rb2 -> rb1` | 942 Mbps | 943 Mbps | +1 Mbps |
| TCP P4 reverse `rb2 <- rb1` | 943 Mbps | 944 Mbps | +1 Mbps |
| TCP P1 `rb1 -> rb2` | 942 Mbps | 943 Mbps | +1 Mbps |
| TCP P4 `rb1 -> rb2` | 942 Mbps | 944 Mbps | +2 Mbps |
| UDP `500M` (`rb2 -> rb1`) | 500 Mbps, 0% loss | 500 Mbps, 0% loss | none |
| UDP `500M` (`rb1 -> rb2`) | 500 Mbps, 0% loss | 500 Mbps, 0% loss | none |
| Ping loss (`rb2 -> rb1 primary`) | 0% | 0% | none |
| Ping loss (`rb2 -> rb1 fallback`) | 0% | 0% | none |

## WoL Findings

- Previous active adapter (`enp0s20f0u6`, Realtek/r8152) exposed hardware WoL:
  - `Supports Wake-on: pumbg`
  - `Wake-on: g`
- New active adapter (`enp0s20f0u1c2`, AX88179A via `cdc_ncm`) does **not** expose hardware WoL fields.
- Explicit set attempt fails:
  - `ethtool -s enp0s20f0u1c2 wol g` -> `Operation not supported`
- Magic packet path to new MAC is present on-wire (captured from `rb2`).
- Retest (2026-02-20 17:11 EST):
  - Forcing USB config `2 -> 1` rebinds adapter to `ax88179_178a` and exposes WoL flags (`Supports Wake-on: pg`); `ethtool -s ... wol g` succeeds.
  - In that mode, this host loses carrier (`Link status: 0`) and cannot use the adapter for active networking; kernel logged register-read errors (`Failed to read reg index 0x0040: -32`).
  - After USB reset, adapter returned to config `2` (`cdc_ncm`) with stable networking restored.

## Other Observations

- Link reports `1000Mb/s` on new adapter.
- Duplex reports `Unknown (255)` on new adapter (common on this driver path).
- No throughput regression observed.
- Existing PCIe AER correctable noise remains in kernel logs (pre-existing, not specific to this NIC cutover).

## Artifacts

- `pre-switch-rb1-state.txt`
- `post-switch-rb1-state.txt`
- `pre-switch-iperf-rb2-to-rb1.txt`
- `pre-switch-iperf-rb1-to-rb2.txt`
- `post-switch-iperf-rb2-to-rb1.txt`
- `post-switch-iperf-rb1-to-rb2.txt`
- `pre-switch-wol-*`
- `post-switch-wol-*`
