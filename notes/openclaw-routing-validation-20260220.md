| timestamp_utc | case | mode | provider | model | duration_ms | input_tokens | output_tokens | total_tokens | result | notes | response_excerpt |
|---|---|---|---|---|---:|---:|---:|---:|---|---|---|
| 2026-02-20T19:44:14Z | route_01_marker | local | ollama | qwen2.5:7b | 23472 | 8159 | 6 | 8165 | PASS | ok | ROUTE_OK_01 |
| 2026-02-20T19:44:40Z | route_02_math | local | ollama | qwen2.5:7b | 2157 | 8162 | 4 | 8166 | PASS | ok | 391 |
| 2026-02-20T19:44:45Z | route_03_json_extract | local | ollama | qwen2.5:7b | 2742 | 8180 | 14 | 8194 | PASS | ok | 192.168.5.107 |
| 2026-02-20T19:44:51Z | route_04_sort_csv | local | ollama | qwen2.5:7b | 2575 | 8167 | 9 | 8176 | PASS | ok | mba,rb1,rb2 |
| 2026-02-20T19:44:57Z | route_05_transform | local | ollama | qwen2.5:7b | 2321 | 8165 | 8 | 8173 | PASS | ok | aa:bb:cc:dd |
| 2026-02-20T19:45:02Z | route_06_wol_short | local | ollama | qwen2.5:7b | 2263 | 8167 | 7 | 8174 | PASS | ok | Magic packet wakes sleeping computer. |
| 2026-02-20T19:45:07Z | route_07_ping_cmd | local | ollama | qwen2.5:7b | 7408 | 16455 | 88 | 16543 | FAIL | missing ping/ip | The ping command is now running in the background. You can check its status or log output using the `process` tool if ne |
| 2026-02-20T19:45:17Z | route_08_yaml | local | ollama | qwen2.5:7b | 2522 | 8169 | 11 | 8180 | PASS | ok | host: rb1-fedora status: ok |
| 2026-02-20T19:45:23Z | route_09_python | local | ollama | qwen2.5:7b | 7489 | 16405 | 92 | 16497 | PASS | ok | The function `def add(a, b): return a + b` has been written to the file `/home/tdj/.openclaw/workspace/add.py`. You can  |
| 2026-02-20T19:45:33Z | route_10_gateway_marker | gateway | ollama | qwen2.5:7b | 6428 | 8338 | 6 | 8344 | PASS | ok | ROUTE_OK_10 |
| 2026-02-20T19:45:45Z | coder_path_check | local | ollama | qwen2.5-coder:7b | 30041 | 8176 | 17 | 8193 | PASS | ok | ```python def add(a, b): return a + b ``` |
| 2026-02-20T19:46:21Z | fallback_forced_check | gateway | ollama | qwen2.5:7b | 14151 | 0 | 0 | 0 | FAIL | expected FALLBACK_PATH_OK; provider!=openai-codex | fetch failed |
| 2026-02-20T19:46:41Z | fallback_manual_backstop | gateway | openai-codex | gpt-5.3-codex | 2828 | 7645 | 9 | 7654 | PASS | ok | FALLBACK_PATH_OK |
