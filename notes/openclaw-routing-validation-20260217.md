| timestamp_utc | case | mode | provider | model | duration_ms | input_tokens | output_tokens | total_tokens | result | notes | response_excerpt |
|---|---|---|---|---|---:|---:|---:|---:|---|---|---|
| 2026-02-17T07:55:09Z | route_01_marker | local | ollama | qwen2.5:7b | 19779 | 7837 | 6 | 7843 | PASS | ok | ROUTE_OK_01 |
| 2026-02-17T07:55:31Z | route_02_math | local | ollama | qwen2.5:7b | 19940 | 7840 | 4 | 7844 | PASS | ok | 391 |
| 2026-02-17T07:55:54Z | route_03_json_extract | local | ollama | qwen2.5:7b | 21347 | 7858 | 14 | 7872 | PASS | ok | 192.168.5.107 |
| 2026-02-17T07:56:18Z | route_04_sort_csv | local | ollama | qwen2.5:7b | 21915 | 7846 | 29 | 7875 | FAIL | expected mba,rb1,rb2 |  |
| 2026-02-17T07:56:42Z | route_05_transform | local | ollama | qwen2.5:7b | 20401 | 7843 | 8 | 7851 | PASS | ok | aa:bb:cc:dd |
| 2026-02-17T07:57:06Z | route_06_wol_short | local | ollama | qwen2.5:7b | 20590 | 7845 | 7 | 7852 | PASS | ok | Magic packet wakes sleeping computer. |
| 2026-02-17T07:57:29Z | route_07_ping_cmd | local | ollama | qwen2.5:7b | 26482 | 15941 | 82 | 16023 | PASS | ok | The ping to host `172.31.99.2` was successful with a response time of approximately 0.625ms on both attempts. No packet  |
| 2026-02-17T07:57:58Z | route_08_yaml | local | ollama | qwen2.5:7b | 19721 | 7847 | 11 | 7858 | PASS | ok | host: rb1-fedora status: ok |
| 2026-02-17T07:58:20Z | route_09_python | local | ollama | qwen2.5:7b | 26599 | 15762 | 110 | 15872 | FAIL | missing def add | The Python function `add` has been created in the file `/home/tdj/.openclaw/workspace/add.py`. You can use it like this: |
| 2026-02-17T07:58:49Z | route_10_gateway_marker | gateway | unknown | unknown | 0 | 0 | 0 | 0 | FAIL | expected ROUTE_OK_10; provider!=ollama |  |
| 2026-02-17T07:59:01Z | coder_path_check | local | ollama | qwen2.5-coder:7b | 46630 | 7854 | 17 | 7871 | PASS | ok | ```python def add(a, b): return a + b ``` |
| 2026-02-17T07:59:53Z | fallback_forced_check | gateway | unknown | unknown | 0 | 0 | 0 | 0 | FAIL | expected FALLBACK_PATH_OK; provider!=openai-codex |  |
| 2026-02-17T08:04:03Z | route_01_marker | local | ollama | qwen2.5:7b | 20382 | 7837 | 6 | 7843 | PASS | ok | ROUTE_OK_01 |
| 2026-02-17T08:04:26Z | route_02_math | local | ollama | qwen2.5:7b | 19936 | 7840 | 4 | 7844 | PASS | ok | 391 |
| 2026-02-17T08:04:49Z | route_03_json_extract | local | ollama | qwen2.5:7b | 20255 | 7858 | 14 | 7872 | PASS | ok | 192.168.5.107 |
| 2026-02-17T08:05:11Z | route_04_sort_csv | local | ollama | qwen2.5:7b | 21615 | 7846 | 29 | 7875 | FAIL | expected mba,rb1,rb2 |  |
| 2026-02-17T08:05:36Z | route_05_transform | local | ollama | qwen2.5:7b | 19880 | 7843 | 8 | 7851 | PASS | ok | aa:bb:cc:dd |
| 2026-02-17T08:05:58Z | route_06_wol_short | local | ollama | qwen2.5:7b | 20373 | 7845 | 7 | 7852 | PASS | ok | Magic packet wakes sleeping computers. |
| 2026-02-17T08:06:21Z | route_07_ping_cmd | local | ollama | qwen2.5:7b | 26930 | 15941 | 86 | 16027 | PASS | ok | The ping to host `172.31.99.2` was successful with a round-trip time of approximately 0.477 milliseconds on average. No  |
| 2026-02-17T08:06:51Z | route_08_yaml | local | ollama | qwen2.5:7b | 21414 | 7847 | 11 | 7858 | PASS | ok | host: rb1-fedora status: ok |
| 2026-02-17T08:07:15Z | route_09_python | local | ollama | qwen2.5:7b | 27106 | 15764 | 123 | 15887 | FAIL | missing def add | The Python function `add` has been successfully written to the file `/home/tdj/.openclaw/workspace/add_function.py`. You |
| 2026-02-17T08:07:45Z | route_10_gateway_marker | gateway | ollama | qwen2.5:7b | 6248 | 8047 | 6 | 8053 | PASS | ok | ROUTE_OK_10 |
| 2026-02-17T08:07:56Z | coder_path_check | local | ollama | qwen2.5-coder:7b | 47150 | 7854 | 17 | 7871 | PASS | ok | ```python def add(a, b): return a + b ``` |
| 2026-02-17T08:08:48Z | fallback_forced_check | gateway | ollama | qwen2.5:7b | 14138 | 0 | 0 | 0 | FAIL | expected FALLBACK_PATH_OK; provider!=openai-codex | fetch failed |
