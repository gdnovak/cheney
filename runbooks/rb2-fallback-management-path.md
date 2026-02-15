# rb2 Fallback Management Path Runbook

Purpose: establish and test an emergency direct management path to `rb2` that survives primary switch/cable failures.

## Design (Default)

1. Keep primary management unchanged on normal LAN (`192.168.5.108/22` via `vmbr0`).
2. Add a separate point-to-point fallback link between `rb1` and `rb2` using spare Ethernet-capable adapters/ports.
3. Use dedicated static addresses on fallback interfaces only:
- `rb1` fallback IP: `172.31.99.1/30`
- `rb2` fallback IP: `172.31.99.2/30`

## Preconditions

1. At least one spare Ethernet path per host is physically available.
2. You can recable without touching the currently working primary management path.
3. `rb1` and `rb2` SSH access is healthy before starting.

## Step 1 - Identify Candidate Fallback Interfaces

On each host:

```bash
ip -br link
```

Pick interfaces that:

1. Are not current `vmbr0` bridge-ports.
2. Show physical link when direct cable is inserted.

Record chosen interfaces in `inventory/network-layout.md`.

## Step 2 - Bring Up Temporary Runtime Fallback IPs (Non-Persistent)

On `rb1` (replace `<RB1_FALLBACK_IFACE>`):

```bash
ip link set <RB1_FALLBACK_IFACE> up
ip addr add 172.31.99.1/30 dev <RB1_FALLBACK_IFACE>
```

On `rb2` (replace `<RB2_FALLBACK_IFACE>`):

```bash
ip link set <RB2_FALLBACK_IFACE> up
ip addr add 172.31.99.2/30 dev <RB2_FALLBACK_IFACE>
```

## Step 3 - Validate Fallback Reachability

From `rb1`:

```bash
ping -c 4 172.31.99.2
ssh -o ConnectTimeout=5 root@172.31.99.2 'hostname; ip -4 -br addr'
```

From control host (through rb1 jump, optional):

```bash
ssh rb1-pve 'ssh -o ConnectTimeout=5 root@172.31.99.2 hostname'
```

## Step 4 - Required Persistent Config (Both Hosts)

Persist fallback interface in `/etc/network/interfaces` on each host only after Step 3 passes repeatedly.

Keep persistent fallback config isolated:

1. No gateway on fallback interface.
2. No bridge changes to existing `vmbr0` primary path.
3. No forwarding/NAT/routing use for fallback subnet; this path is host-management only.

After persisting, validate reboot survival:

1. Reboot `rb1` and confirm fallback interface/IP returns automatically.
2. Reboot `rb2` and confirm fallback interface/IP returns automatically.
3. Re-test ping/SSH over fallback subnet in both directions.
4. Treat runbook as incomplete if persistence is missing on either host.

## Step 5 - Failure Drill

Simulate primary-path loss (one change at a time):

1. Disconnect primary uplink for `rb2`.
2. Confirm fallback SSH still works through `172.31.99.2`.
3. Reconnect primary path and verify normal management returns.

## Rollback (Runtime Config)

On `rb1`:

```bash
ip addr del 172.31.99.1/30 dev <RB1_FALLBACK_IFACE>
```

On `rb2`:

```bash
ip addr del 172.31.99.2/30 dev <RB2_FALLBACK_IFACE>
```

## Pass Criteria

1. `rb2` reachable over direct fallback IP even with primary path interrupted.
2. Primary management path remains unchanged and recoverable.
3. Procedure repeatable after recabling.
4. Persistent fallback interface exists and survives reboot on both `rb1` and `rb2`.
