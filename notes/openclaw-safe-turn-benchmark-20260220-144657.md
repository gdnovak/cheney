# OpenClaw Safe-Turn Benchmark

timestamp_local: 2026-02-20 14:46:57 EST  
host_alias: rb1-admin  
mode: gateway  
agent: main  
thinking: off  
profile: real

| case | forced_outage | backstop_used | final_provider | final_model | final_rc | tokens | duration_ms | wrapper_elapsed_ms | response_excerpt |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
| real_01_risk_summary | 0 | 0 | ollama | qwen2.5:7b | 0 | 8365 | 24413 | 30815 | Based on the fallback and eGPU facts, the highest current operational risk on rb1/rb2 is t |
| real_02_checklist | 0 | 0 | ollama | qwen2.5:7b | 0 | 8440 | 1624 | 7924 | 1. Ping VLAN99 IP. 2. Check network interfaces. 3. Verify DNS resolution. |
| real_03_command | 0 | 0 | ollama | qwen2.5:7b | 0 | 8496 | 1137 | 7471 | ```bash systemctl status ollama ``` |
| real_04_transform | 0 | 0 | ollama | qwen2.5:7b | 0 | 8599 | 2693 | 8851 | ```json {"host": "rb1-fedora", "status": "active", "ip": "192.168.5.107"} ``` |
| real_05_changelog | 0 | 0 | ollama | qwen2.5:7b | 0 | 8664 | 1383 | 7698 | Enabled Wake-on-LAN on rb1-fedora for remote system wakeups. |
| real_06_recovery | 0 | 0 | ollama | qwen2.5:7b | 0 | 8723 | 1223 | 7579 | Disconnect eGPU and reboot rb1-fedora to restore stability. |
| real_07_forced_outage | 1 | 1 | openai-codex | gpt-5.3-codex | 0 | 8093 | 1377 | 13374 | REAL_OUTAGE_RECOVERED |

## Summary
count=7
success_count=7
backstop_count=1
final_provider_ollama=6
final_provider_openai_codex=1
avg_tokens=8482
avg_duration_ms=4835
avg_wrapper_elapsed_ms=11958
cloud_final_tokens_total=8093
cloud_final_tokens_avg=8093
forced_outage_wrapper_elapsed_ms=13374

Artifacts:
- JSONL: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260220-144657.jsonl
- Log: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260220-144657.log
