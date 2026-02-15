# Monitoring Software Evaluation (2026-02-14)

Question: should third-party monitoring replace custom watcher scripts for this project?

Short answer: yes. A managed monitoring stack is better for reliability, visibility, and alerting than ad-hoc shell loops.

## Candidate Summary

## 1) Uptime Kuma (free, self-hosted)

Best for:

- uptime checks (ping/HTTP/TCP)
- simple status pages
- practical alerting without heavy infra

Tradeoffs:

- not a full time-series metrics platform

Source:

- Official repo/docs: https://github.com/louislam/uptime-kuma

## 2) Netdata (free + paid tiers, self-hosted agents)

Best for:

- deep host metrics
- anomaly/health visualization
- quick observability without building Prometheus/Grafana first

Tradeoffs:

- more telemetry than pure uptime tools
- can be heavier than basic ping checks

Source:

- Official docs: https://learn.netdata.cloud/docs/netdata-agent/installation/linux

## 3) Prometheus (+ Grafana)

Best for:

- long-term metrics, queries, dashboards, rule-based alerting
- scalable observability architecture

Tradeoffs:

- highest setup/ops overhead in this list

Source:

- Prometheus docs: https://prometheus.io/docs/introduction/overview/

## Recommendation for This Lab (Current Phase)

1. Start with `Uptime Kuma` for operational continuity checks now.
2. Optionally add `Netdata` later if deeper host metrics are needed.
3. Defer Prometheus/Grafana until automation footprint grows.

Rationale:

- You specifically need reliable node/service continuity while hardware changes continue.
- This is exactly where Uptime Kuma is strongest and simpler than custom scripts.

## Suggested Initial Check Set

1. `rb1` SSH (`22`) and Proxmox UI (`8006`)
2. `rb2` SSH (`22`) and Proxmox UI (`8006`)
3. `mba` SSH (`22`) and Proxmox UI (`8006`)
4. `tsDeb` heartbeat check
5. Gateway reachability (`192.168.4.1`)

## Proxmox Replication Note (for TrueNAS move planning)

- Native Proxmox VM replication is tied to ZFS-backed replication workflows.
- Current hosts are using local `lvmthin` (`local-lvm`) for VM disks, so native replication is not the immediate path in this setup.

Source:

- Proxmox replication docs: https://pve.proxmox.com/pve-docs/chapter-pvesr.html
