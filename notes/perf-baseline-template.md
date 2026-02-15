# Performance Baseline Template

Use this template to capture before/after network changes.

## Metadata

- date:
- operator:
- phase:
- change under test:
- controller host:

## Topology Snapshot

- smart switch uplink:
- unmanaged switch uplink:
- hosts on unmanaged switch:
- hosts on smart switch:
- known fallback management path:

## Link Status Before Test

| host | interface | operstate | speed | duplex | rx_err | tx_err | rx_drop | tx_drop |
|---|---|---|---|---|---:|---:|---:|---:|
| rb1 | | | | | | | | |
| rb2 | | | | | | | | |
| mba | | | | | | | | |
| workstation/mac mini | | | | | | | | |

## `iperf3` Results

| client | server | mode | duration_s | parallel | bandwidth_mbps | retransmits | loss_pct | jitter_ms | notes |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| | | tcp | 30 | 1 | | | n/a | n/a | |
| | | tcp | 30 | 4 | | | n/a | n/a | |
| | | tcp-reverse | 30 | 4 | | | n/a | n/a | |
| | | udp | 30 | n/a | | n/a | | | |

## Link Status After Test

| host | interface | rx_err_delta | tx_err_delta | rx_drop_delta | tx_drop_delta | notes |
|---|---|---:|---:|---:|---:|---|
| rb1 | | | | | | |
| rb2 | | | | | | |
| mba | | | | | | |
| workstation/mac mini | | | | | | |

## Assessment

- bottleneck found:
- stable/unstable paths:
- immediate fixes:
- follow-up experiments:
