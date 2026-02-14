# Runbook: Safe Proxmox Management Interface Cutover

Use this when moving a Proxmox host management bridge (`vmbr0`) from one NIC to another while keeping the same IP.

## Scope

- Target host keeps same management IP on `vmbr0`
- Only `bridge-ports` member changes (example: `nic0` -> `enx...`)

## Preconditions

1. Confirm target NIC exists:
```bash
ip -brief link
```
2. Bring target NIC up and confirm carrier:
```bash
ip link set <target_nic> up
ethtool <target_nic> | grep -E "Speed|Link detected"
```
Proceed only if `Link detected: yes`.
3. Confirm `ifreload` is available:
```bash
command -v ifreload
```

## Guarded Cutover Procedure

Run on control host:

```bash
ssh <host_alias> 'bash -s' <<'EOF'
set -euo pipefail
TARGET="<target_nic>"
OLD="<old_nic>"
BACK=/root/interfaces.pre_cutover.$(date +%Y%m%d-%H%M%S).bak

cp /etc/network/interfaces "$BACK"

# Ensure target NIC stanza exists
if ! grep -q "^iface ${TARGET} inet manual" /etc/network/interfaces; then
  awk -v old="$OLD" -v target="$TARGET" '
    $0 ~ ("^iface " old " inet manual$") {print; print ""; print "iface " target " inet manual"; next}
    {print}
  ' /etc/network/interfaces > /etc/network/interfaces.new
  mv /etc/network/interfaces.new /etc/network/interfaces
fi

# Switch bridge port
sed -i "s/^\\([[:space:]]*bridge-ports[[:space:]]*\\)${OLD}$/\\1${TARGET}/" /etc/network/interfaces

# Arm rollback in 120s
nohup bash -lc "sleep 120; cp '$BACK' /etc/network/interfaces; ifreload -a" >/root/net-cutover-rollback.log 2>&1 &
echo $! >/root/net-cutover-rollback.pid

ifreload -a
sleep 2

# Verify local network state
ip -brief link show "$TARGET"
ip -brief link show vmbr0
ip -4 -brief addr show vmbr0
ip route | head -n 3
bridge link | sed -n '1,30p'

# Cancel rollback after successful verification
kill "$(cat /root/net-cutover-rollback.pid)" 2>/dev/null || true
rm -f /root/net-cutover-rollback.pid
EOF
```

## Post-Cutover Validation

From control host:

```bash
ping -c2 <mgmt_ip>
ssh <host_alias> 'hostname; systemctl is-active pveproxy pvedaemon pve-cluster | tr "\n" " "; echo'
ssh <host_alias> 'qm list'
```

## Failure Handling

1. If SSH/ping do not return, wait up to 120 seconds for auto-rollback.
2. Re-verify host on previous path.
3. Do not retry until target NIC link is stable.

## Notes

- Never bridge both old and new NICs together ad hoc on the same L2 unless you intentionally configured bonding/STP behavior.
- Perform one cable/interface move at a time and validate before the next change.
