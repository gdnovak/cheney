# Network Throughput Benchmark Runbook

Purpose: produce repeatable throughput data and identify link bottlenecks before/after recabling or NIC/switch upgrades.

## Scope

- Targets: `rb1-pve`, `rb2`, `mba`, workstation/mac mini path.
- Tools: `iperf3`, `ping`, NIC counter reads from `/sys/class/net`.
- Non-goal: this runbook does not change bridge config or IP assignments.

## Preconditions

1. All target hosts reachable via SSH.
2. Bridge/IP state already verified after latest cable changes.
3. Testing window is acceptable for temporary LAN load.
4. One inter-switch uplink only (avoid unmanaged loop hazards).

## Install `iperf3`

On Proxmox/Debian nodes:

```bash
apt-get update
apt-get install -y iperf3
```

On Fedora workstation:

```bash
sudo dnf install -y iperf3
```

On macOS workstation/mac mini (if tested locally from macOS):

```bash
brew install iperf3
```

## Baseline Capture (Before Tests)

From control host, capture link status/counters on each node:

```bash
for pair in "rb1-pve enx90203a1be8d6" "rb2 enx00051bde7e6e" "mba nic0"; do
  set -- $pair
  h=$1
  i=$2
  echo "=== $h $i ==="
  ssh "$h" "bash -lc '
    oper=\$(cat /sys/class/net/$i/operstate 2>/dev/null || echo ?)
    speed=\$(cat /sys/class/net/$i/speed 2>/dev/null || echo ?)
    duplex=\$(cat /sys/class/net/$i/duplex 2>/dev/null || echo ?)
    rx_err=\$(cat /sys/class/net/$i/statistics/rx_errors 2>/dev/null || echo ?)
    tx_err=\$(cat /sys/class/net/$i/statistics/tx_errors 2>/dev/null || echo ?)
    rx_drop=\$(cat /sys/class/net/$i/statistics/rx_dropped 2>/dev/null || echo ?)
    tx_drop=\$(cat /sys/class/net/$i/statistics/tx_dropped 2>/dev/null || echo ?)
    echo oper=\$oper speed=\$speed duplex=\$duplex rx_err=\$rx_err tx_err=\$tx_err rx_drop=\$rx_drop tx_drop=\$tx_drop
  '"
done
```

## Test Matrix

Run these pairs:

1. `rb1 -> rb2`
2. `rb2 -> rb1`
3. `rb1 -> mba`
4. `rb2 -> mba`
5. `workstation/mac mini -> rb1`
6. `workstation/mac mini -> rb2`

For each pair, run:

1. TCP single stream (`-P 1`)
2. TCP multi-stream (`-P 4`)
3. TCP reverse (`-R`)
4. UDP sanity (`-u`) at conservative rate first

## Command Pattern

On server host:

```bash
iperf3 -s
```

On client host:

```bash
iperf3 -c <server_ip> -t 30 -P 1
iperf3 -c <server_ip> -t 30 -P 4
iperf3 -c <server_ip> -t 30 -P 4 -R
iperf3 -c <server_ip> -t 30 -u -b 500M
```

For candidate 2.5Gb links, extend:

```bash
iperf3 -c <server_ip> -t 60 -P 8
iperf3 -c <server_ip> -t 60 -u -b 2G
```

Optional helper from control host:

```bash
scripts/iperf3_client_suite.sh <server_ip> 30 500M
```

## Acceptance Targets

1. 1GbE links: sustained TCP >900 Mbps with low retransmit counts.
2. 2.5GbE links: sustained TCP >2.0 Gbps on tuned parallel tests.
3. No sustained growth trend in NIC error/drop counters after tests.
4. No management path loss (`ssh`, `:8006`) during or after load.

## Troubleshooting Interpretation

1. Throughput near 940 Mbps with stable counters: normal 1GbE ceiling.
2. Throughput capped well below link speed with rising retransmits: suspect bad cable/dongle, duplex mismatch, or CPU bottleneck.
3. Good TCP but poor UDP with loss/jitter spikes: congestion or buffer pressure.
4. Directional asymmetry (`normal` vs `-R`): NIC/driver path issue on one endpoint.

## Post-Test Closeout

1. Re-capture NIC counters and compare deltas.
2. Save outputs using `notes/perf-baseline-template.md`.
3. Update `inventory/network-layout.md` with confirmed link rates and any adapter path changes.
4. Record outcomes in `log.md` with timestamp and next action.
