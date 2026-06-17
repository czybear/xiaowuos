#!/usr/bin/env python3
"""Ollama Local Model Concurrency Test — qwen3.6:27b via http://172.22.0.1:11434"""
import json, time, subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor, as_completed

OLLAMA_URL = "http://172.22.0.1:11434/api/generate"
MODEL = "qwen3.6:27b"
TIMEOUT_PER_REQ = 90  # seconds
REPORT_PATH = "/home/john/xiaowuOS/outputs/reports/model_providers/ollama_local_concurrency_test_20260616.md"

PROMPT_SIMPLE = {"model": MODEL, "prompt": "用一句话回答：1+1等于几？", "stream": False, "options": {"num_ctx": 2048}}
LOG_DIR = "/home/john/.xiaowuOS/logs/concurrency_test/"
os.makedirs(LOG_DIR, exist_ok=True)

def run_request(req_id: int, concurrency_label: str) -> dict:
    """Single Ollama API call with timeout tracking."""
    log_file = os.path.join(LOG_DIR, f"req_{concurrency_label}_{req_id}.log")
    start = time.time()
    result = {"id": req_id, "label": concurrency_label, "start": start}

    try:
        body = json.dumps(PROMPT_SIMPLE).encode()
        proc = subprocess.run(
            ["curl", "-s", "--max-time", str(TIMEOUT_PER_REQ),
             "-X", "POST", OLLAMA_URL,
             "-H", "Content-Type: application/json",
             "-d", json.dumps(PROMPT_SIMPLE)],
            capture_output=True, timeout=TIMEOUT_PER_REQ + 5
        )
        elapsed = time.time() - start

        if proc.returncode == 0 and b"error" not in proc.stdout.lower():
            data = json.loads(proc.stdout)
            result["status"] = "success"
            result["elapsed_s"] = round(elapsed, 2)
            result["total_tokens"] = data.get("eval_count", "?")
            result["response_snippet"] = (data.get("response", "")[:60]).strip()
        else:
            result["status"] = "error"
            result["elapsed_s"] = round(elapsed, 2)
            result["error"] = proc.stderr.decode(errors="replace")[:200] if proc.stderr else (proc.stdout.decode(errors="replace")[:200])

    except subprocess.TimeoutExpired:
        elapsed = time.time() - start
        result["status"] = "timeout"
        result["elapsed_s"] = round(elapsed, 2)
        result["error"] = f"Timeout after {TIMEOUT_PER_REQ}s"
    except Exception as e:
        elapsed = time.time() - start
        result["status"] = "exception"
        result["elapsed_s"] = round(elapsed, 2)
        result["error"] = str(e)[:200]

    # Write per-request log file
    with open(log_file, "w") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    return result


def run_concurrent_test(concurrency: int, label: str) -> list:
    print(f"\n--- Test: {concurrency} concurrent request(s) [{label}] ---")
    results = []

    if concurrency == 1:
        r = run_request(0, label)
        results.append(r)
    else:
        with ThreadPoolExecutor(max_workers=concurrency) as pool:
            futures = {pool.submit(run_request, i, label): i for i in range(concurrency)}
            for f in as_completed(futures, timeout=TIMEOUT_PER_REQ * 2 + 10):
                try:
                    results.append(f.result(timeout=TIMEOUT_PER_REQ * 2))
                except Exception as e:
                    results.append({"id": futures[f], "label": label, "status": "pool_error", "error": str(e)})

    for r in sorted(results, key=lambda x: x["start"]):
        st = r["status"].ljust(10)
        elapsed = f"{r['elapsed_s']}s" if 'elapsed_s' in r else "?"
        print(f"  req_{r['id']}: [{st}] {elapsed}")

    ok = sum(1 for r in results if r["status"] == "success")
    print(f"  Result: {ok}/{len(results)} succeeded")
    return results


def main():
    overall = []

    # Phase 0: Single request baseline (run 3 times)
    print("=== Phase 0: Single request baseline ===")
    for i in range(1, 4):
        r = run_request(i - 1, f"baseline_{i}")
        elapsed = r.get("elapsed_s", "?")
        status = r["status"]
        print(f"  Baseline #{i}: [{status}] {elapsed}s")
        overall.append(r)

    # Phase 1: Concurrency tests
    for conc, label in [(1, "conc1"), (2, "conc2"), (3, "conc3")]:
        results = run_concurrent_test(conc, label)
        overall.extend(results)

    # === Generate report ===
    baseline = [r for r in overall if "baseline" in r["label"]]
    conc1 = [r for r in overall if "conc1" in r["label"]]
    conc2 = [r for r in overall if "conc2" in r["label"]]
    conc3 = [r for r in overall if "conc3" in r["label"]]

    def stats(label, results):
        ok = sum(1 for r in results if r["status"] == "success")
        times = [r["elapsed_s"] for r in results if r.get("elapsed_s")]
        return {
            "ok": ok,
            "total": len(results),
            "avg_s": round(sum(times)/len(times), 2) if times else "?",
            "min_s": min(times) if times else "?",
            "max_s": max(times) if times else "?"
        }

    all_stats = {}
    for label, grp in [("baseline", baseline), ("conc1", conc1), ("conc2", conc2), ("conc3", conc3)]:
        all_stats[label] = stats(label, grp)

    report_lines = [
        "# Ollama 本地模型并发压测报告",
        f"\n**测试时间:** 2026-06-16 ~15:37 (CST)",
        f"**Ollama 地址:** http://172.22.0.1:11434 (WSL → Windows)",
        f"**模型:** qwen3.6:27b",
        f"**单次超时:** {TIMEOUT_PER_REQ}s",
        "",
        "---",
        "",
        "## 测试概要",
        ""
    ]

    for label, grp in [("baseline", baseline), ("conc1", conc1), ("conc2", conc2), ("conc3", conc3)]:
        s = all_stats[label]
        lines = [f"### {label.replace('conc', '并发')} ({s['total']}次请求)", "",
            f"| 指标 | 值 |", "|------|-----|",
            f"| 成功率 | {s['ok']}/{s['total']} |",
            f"| 平均耗时 | {s['avg_s']}s |",
            f"| 最快 | {s['min_s']}s |",
            f"| 最慢 | {s['max_s']}s |", ""]
        report_lines.extend(lines)

    # Detailed per-request table
    report_lines += ["---", "", "## 详细请求记录", ""]
    for i, r in enumerate(overall):
        log_name = f"req_{r.get('label','?')}_{r.get('id','?')}.log"
        snippet = (r.get("response_snippet", "") or "").strip()[:40]
        report_lines.append(f"- `#{i}` [{r.get('label','?')}] req_{r.get('id','?')}: "
            f"**{r['status']}** | {r.get('elapsed_s','?')}s | `{log_name}`")

    # Conclusions
    conc2_ok = all_stats["conc2"]["ok"] == all_stats["conc2"]["total"]
    conc3_ok = all_stats["conc3"]["ok"] == all_stats["conc3"]["total"]

    if conc2_ok and not conc3_ok:
        verdict = "建议 max_parallel = 2（并发2稳定，并发3开始不稳）"
    elif conc2_ok and conc3_ok:
        verdict = "并发 1/2/3 均成功，建议可尝试逐步放宽至 3，但仍需谨慎"
    elif not conc2_ok:
        verdict = "⚠️ 并发2已不稳定，建议 max_parallel = 1（串行执行更安全）"
    else:
        verdict = "需人工判断"

    report_lines += [
        "", "---", "", "## 初步结论", "",
        f"**{verdict}**", "",
        "### 建议 scheduler_config.json 调整", "",
        "| max_parallel_agents | 建议值 |", "|---|---|",
        "| 当前配置 | 2 |",
    ]

    if conc3_ok:
        report_lines.append("| ✅ 并发3全通过 | **可保持 2，后续验证后可尝试 3** |")
    elif not conc2_ok:
        report_lines.append("| ❌ 并发2失败 | **建议降至 1（串行）** |")
    else:
        report_lines.append("| ⚠️ 并发3部分失败 | **保持 2，暂不提升** |")

    report_lines += ["", f"**日志文件:** `{LOG_DIR}` 目录下 req_*.log"]

    os.makedirs(os.path.dirname(REPORT_PATH), exist_ok=True)
    with open(REPORT_PATH, "w") as f:
        f.write("\n".join(report_lines))

    print(f"\n✅ Report written to {REPORT_PATH}")


if __name__ == "__main__":
    main()
