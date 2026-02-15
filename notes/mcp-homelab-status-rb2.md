# MCP Install Note: `homelab-status` on `rb2`

Goal: demonstrate end-to-end MCP install on one node with a practical read-only toolset.

## Why This MCP

- It gives fast health answers an agent needs while operating the lab:
  - host identity/uptime
  - Proxmox service status
  - network snapshot
  - tailscale state
- It is read-only and low-risk.

## Installed Location

- Node: `rb2`
- Server script: `/opt/mcp-homelab-status/server.py`
- Launcher: `/usr/local/bin/mcp-homelab-status`
- Python venv: `/opt/mcp-homelab-status/.venv`

## Install Steps Used

1. Install Python packaging prerequisites on `rb2`:
   - `python3-pip`
   - `python3.13-venv`
2. Create venv:
   - `python3 -m venv /opt/mcp-homelab-status/.venv`
3. Install MCP SDK:
   - `/opt/mcp-homelab-status/.venv/bin/pip install mcp`
4. Add server + launcher script.
5. Validate by importing module and calling one tool function.

## Tool Surface

- `host_info()`
- `pve_service_status()`
- `network_snapshot()`
- `tailscale_snapshot()`

## Example MCP Client Wiring (SSH transport)

Use this pattern in an MCP-capable client that launches stdio commands:

```json
{
  "mcpServers": {
    "rb2-homelab-status": {
      "command": "ssh",
      "args": ["rb2", "/usr/local/bin/mcp-homelab-status"]
    }
  }
}
```

## Security/Scope

- Read-only command set.
- No file writes outside normal system command output.
- No power/cable/change actions exposed via tools.
