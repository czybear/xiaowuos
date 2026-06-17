#!/usr/bin/env python3
"""_patch.py — Patch dashboard.json with live metrics from environment variables."""

import json
import os
import sys
import glob
from datetime import datetime, timezone, timedelta

DATA_PATH = "/home/john/xiaowuOS/status/dashboard.json"
QUEUE_DIR = "/home/john/.xiaowuOS/queue"
CST = timezone(timedelta(hours=8))

def env_int(name, default=0):
    try:
        return int(os.environ.get(name, str(default)))
    except ValueError:
        return default

def scan_queue(subdir):
    """Scan a queue subdirectory and return list of task items."""
    p = os.path.join(QUEUE_DIR, subdir)
    if not os.path.isdir(p):
        return 0, []
    files = sorted(glob.glob(os.path.join(p, "*.md")))
    result = []
    for fp in files:
        try:
            with open(fp) as fh:
                content = fh.read()
        except Exception:
            continue
        lines = [l.strip() for l in content.split("\n") if l.strip()]
        title = ""
        for l in lines:
            if "#" in l and len(l) < 120:
                title = l.lstrip("#").strip()
                break
        bn = os.path.basename(fp).replace(".md", "")
        # Extract priority from filename or content
        prio = "P2"
        if any(k in fp for k in ["P0_", "Q008"]):
            prio = "P0"
        elif any(k in fp for k in ["P1_", "Q004", "Q005", "Q006"]):
            prio = "P1"
        result.append({"priority": prio, "title": title or bn.replace("_", " ")})
    return len(files), result

def main():
    try:
        with open(DATA_PATH) as f:
            data = json.load(f)
    except Exception as e:
        print(f"ERROR loading dashboard.json: {e}", flush=True)
        sys.exit(1)

    gw_status  = os.environ.get("D_GW_STATUS", "unknown")
    gw_http    = os.environ.get("D_GW_HTTP", "000")
    disk_pct   = env_int("D_DISK_PCT")
    doing      = env_int("D_DOING")
    failed_cnt = env_int("D_FAILED")

    # ── System section ──
    s = data.setdefault("system", {})
    s["hostname"]         = os.environ.get("D_HOSTNAME", "?")
    s["uptime"]           = os.environ.get("D_UPTIME", "?")
    s["disk_free"]        = (f"总计 {os.environ['D_DISK_TOTAL']} / "
                            f"已用 {os.environ['D_DISK_USED']} / "
                            f"可用 {os.environ['D_DISK_AVAIL']}")
    s["memory"]           = (f"总计 {os.environ['D_MEM_TOTAL']} / "
                            f"已用 {os.environ['D_MEM_USED']} / "
                            f"可用 {os.environ['D_MEM_AVAIL']}")

    oc_ver = os.environ.get("D_OC_VERSION", "").strip()
    s["openclaw_version"] = oc_ver if oc_ver else s.get("openclaw_version", "?")
    s["gateway_status"]   = gw_status
    s["gateway_http"]     = gw_http
    s["frpc_status"]      = os.environ.get("D_FRPC", "unknown")

    # ── Anomalies ──
    anomalies = []

    if disk_pct > 85:
        anomalies.append({"type": "warning", "message": f"磁盘使用率 {disk_pct}%"})

    # Always show queue summary
    level = "info" if (doing < 5 and failed_cnt == 0) else "warning"
    anomalies.append({
        "type": level,
        "message": (f"队列: TODO={env_int('D_TODO')} "
                    f"DOING={doing} "
                    f"DONE={env_int('D_DONE')} "
                    f"FAILED={failed_cnt}")
    })

    if gw_http == "000":
        anomalies.append({"type": "warning", "message": "Gateway HTTP 不可达"})
    elif gw_status != "running":
        anomalies.append({"type": "info", "message": f"Gateway 状态: {gw_status}"})

    s["anomalies"] = anomalies
    data["system"] = s

    # ── Timestamps ──
    now = os.environ.get("D_NOW_CST", "?")
    ms = data.setdefault("main_standby", {})
    if "xiaowuos_main" in ms:
        ms["xiaowuos_main"]["last_sync"] = now
    data["main_standby"] = ms

    # ── Sync tasks_today from real queue (eliminates stale snapshot) ──
    tc_todo,  items_todo   = scan_queue("todo")
    tc_doing, items_doing  = scan_queue("doing")
    tc_done,  items_done   = scan_queue("done")
    tc_failed,items_failed = scan_queue("failed")

    ts = data.setdefault("tasks_today", {})
    ts["in_progress"] = items_doing
    ts["todo"]        = items_todo
    ts["done"]        = items_done[:10]  # Cap display at 10
    ts["snapshot_at"]  = now
    ts["real_counts"] = {
        "todo": tc_todo,
        "doing": tc_doing,
        "done": tc_done,
        "failed": tc_failed
    }
    # Sync anomalies from failed queue
    ts["anomalies"] = []
    if tc_failed > 0:
        ts["anomalies"].append({
            "priority": "P0",
            "title": f"⚠️ Failed队列有{tc_failed}个任务需处理"
        })
    data["tasks_today"] = ts

    # Save
    with open(DATA_PATH, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"[{now}] OK | gw={gw_status} http={gw_http} frpc={os.environ.get('D_FRPC','?')} "
          f"disk={disk_pct}% queue=t{env_int('D_TODO')}/d{doing}/✓{env_int('D_DONE')}/✗{failed_cnt}",
          flush=True)

if __name__ == "__main__":
    main()
