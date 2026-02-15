# Network Procurement Shortlist

Purpose: keep spending practical while maximizing throughput gains for `rb1`/`rb2`/workstation paths.

## Buying Principles

1. Upgrade bottlenecks in this order: endpoint NIC capability -> switch port capability -> cable quality.
2. Keep one spare adapter/cable path for recovery access.
3. Avoid enterprise-priced gear unless it delivers a clear step-function gain.

## Reuse First (No Purchase)

1. Keep one managed-to-unmanaged switch uplink only.
2. Move high-throughput endpoints to the faster unmanaged switch first.
3. Reserve smart switch visibility and known-good management paths.
4. Retire fragile adapter chains from primary data paths.

## High-Value Purchases (Recommended First)

| item | qty | target budget (usd) | why it matters |
|---|---:|---:|---|
| USB 3.x -> 2.5GbE adapters (RTL8156B-class) | 3-4 | 25-45 each | fastest path to >1GbE on mixed laptop hardware |
| short known-good Cat6/Cat6A patch cables | 6-10 | 8-20 each | reduces mystery failures and bad-cable troubleshooting time |
| spare 2.5GbE adapter | 1 | 25-45 | immediate fallback during remote troubleshooting |

## Optional Next Step (Prosumer, Not Enterprise)

| item | qty | target budget (usd) | when to buy |
|---|---:|---:|---|
| managed multi-gig switch (2.5GbE-focused) | 1 | 180-450 | when you want both visibility and multi-gig on the same fabric |
| TB3/USB-C 10GbE adapter(s) for top endpoints | 1-2 | 140-260 each | when storage path can benefit from near-10Gb transfer rates |
| prosumer 10Gb-capable switch | 1 | 300-800 | only after confirming 2.5GbE is fully utilized |

## Purchase Order (Default)

1. Buy 3x 2.5GbE adapters + 1 spare.
2. Rewire and validate with `iperf3` matrix.
3. If results are still constrained, upgrade switch layer.
4. Defer 10Gb until there is a proven workload bottleneck at 2.5GbE.

## Success Criteria

1. `rb1 <-> rb2` sustained throughput >2.0Gbps on tuned TCP tests.
2. No sustained increase in NIC error/drop counters during 15-30 min load.
3. Management access remains stable during data-plane load tests.
