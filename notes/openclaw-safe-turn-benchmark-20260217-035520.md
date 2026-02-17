# OpenClaw Safe-Turn Benchmark

timestamp_local: 2026-02-17 03:55:20 EST  
host_alias: rb1-admin  
mode: gateway  
agent: main  
thinking: off  
profile: real

| case | forced_outage | backstop_used | final_provider | final_model | final_rc | tokens | duration_ms | wrapper_elapsed_ms | response_excerpt |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
| real_01_risk_summary | 0 | 0 | ollama | qwen2.5:7b | 0 | 10550 | 30019 | 35670 | The highest current operational risk on rb1/rb2 is system instability due to improper eGPU |
| real_02_checklist | 0 | 0 | ollama | qwen2.5:7b | 0 | 10623 | 1658 | 7066 | 1. Check network interfaces. 2. Verify IP assignment. 3. Test server access. |
| real_03_command | 0 | 0 | ollama | qwen2.5:7b | 0 | 10674 | 936 | 6354 | systemctl status ollama |
| real_04_transform | 0 | 0 | ollama | qwen2.5:7b | 0 | 10773 | 2652 | 7945 | {"host": "rb1-fedora", "status": "active", "ip": "192.168.5.107"} |
| real_05_changelog | 0 | 0 | ollama | qwen2.5:7b | 0 | 10838 | 1534 | 6894 | Enabled Wake-on-LAN on rb1-fedora for remote system booting. |
| real_06_recovery | 0 | 0 | ollama | qwen2.5:7b | 0 | 10897 | 1357 | 6800 | Reconnect stable GPU and reboot before re-enabling eGPU. |
| real_07_forced_outage | 1 | 1 | openai-codex | gpt-5.3-codex | 0 | 9926 | 1230 | 11635 | REAL_OUTAGE_RECOVERED |

## Summary
count=7
success_count=7
backstop_count=1
final_provider_ollama=6
final_provider_openai_codex=1
avg_tokens=10611
avg_duration_ms=5626
avg_wrapper_elapsed_ms=11766
cloud_final_tokens_total=9926
cloud_final_tokens_avg=9926
forced_outage_wrapper_elapsed_ms=11635

Artifacts:
- JSONL: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-035520.jsonl
- Log: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-035520.log
