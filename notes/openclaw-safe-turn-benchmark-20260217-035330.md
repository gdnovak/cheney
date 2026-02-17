# OpenClaw Safe-Turn Benchmark

timestamp_local: 2026-02-17 03:53:30 EST  
host_alias: rb1-admin  
mode: gateway  
agent: main  
thinking: off  
profile: real

| case | forced_outage | backstop_used | final_provider | final_model | final_rc | tokens | duration_ms | wrapper_elapsed_ms | response_excerpt |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
| real_01_risk_summary | 0 | 0 | ollama | qwen2.5:7b | 0 | 10080 | 29290 | 34948 | Based on the fallback and eGPU facts, the highest current operational risk on rb1/rb2 is t |
| real_02_checklist | 0 | 0 | ollama | qwen2.5:7b | 0 | 10153 | 1638 | 7041 | 1. Verify network connectivity. 2. Check VLAN membership. 3. Test server access. |
| real_03_command | 0 | 0 | ollama | qwen2.5:7b | 0 | 10204 | 934 | 6387 | systemctl status ollama |
| real_04_transform | 0 | 0 | ollama | qwen2.5:7b | 0 | 10303 | 2614 | 7885 | {"host": "rb1-fedora", "status": "active", "ip": "192.168.5.107"} |
| real_05_changelog | 0 | 0 | ollama | qwen2.5:7b | 0 | 10368 | 1502 | 6753 | Enabled Wake-on-LAN on rb1-fedora for remote system booting. |
| real_06_recovery | 0 | 0 | ollama | qwen2.5:7b | 0 | 10424 | 1185 | 6683 | Disconnect and re-enable stable GPU before rebooting. |
| real_07_forced_outage | 1 | 1 | openai-codex | gpt-5.3-codex | 0 | 9512 | 1066 | 11525 | REAL_OUTAGE_RECOVERED |

## Summary
count=7
success_count=7
backstop_count=1
final_provider_ollama=6
final_provider_openai_codex=1
avg_tokens=10149
avg_duration_ms=5461
avg_wrapper_elapsed_ms=11603
cloud_final_tokens_total=9512
