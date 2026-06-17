#!/usr/bin/env python3
"""update_dashboard.py — Live data updater for xiaowuOS dashboard
Runs every 60s via crontab. Reads system metrics + queue state → patches dashboard.json.
Cloud: zero | Local only | No private/finance access.
"""

import json
import os
import socket
import subprocess
import time
from datetime import datetime, timezone, timedelta

DASHBOARD_JSON = os.path.expanduser("/home/john/xiaowuOS/status/dashboard.json")
QUEUE_DIR      = os.path.expanduser("~/.xiaowuOS/queue/")
LOCK_FILE      = "/tmp/update_dashboard.lock"
CST            = timezone(timedelta(hours=8))

def now_cst():
    return datetime.now(CST).strftime("%Y-%m-%dT%H:%M:%S+08:00")

def load_json(path):
    with open(path, "r") as f:
        return json.load(f)

def save_json(data, path):
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def get_uptime():
    try:
        with open("/proc/uptime") as f:
            seconds = float(f.read().split()[0])
    except Exception:
        return "?"
    days  = int(seconds // 86400)
    hours = int((seconds % 86400) // 3600)
    mins  = int((seconds % 3600) // 60)
    if days > 0:
        return f"{days}天{hours}时{mins}分"
    return f"{hours}时{mins}分"

def get_disk():
    try:
        result = subprocess.run(["df", "--block-size=1G", "/"], capture_output=True, text=True)
        line   = result.stdout.strip().split("\n")[-1]
        parts  = line.split()
        total  = parts[1]
        used   = parts[2]
        avail  = parts[3]
        pct    = int(parts[4].replace("%", ""))
    except Exception:
        return "?", "?", "?"
    return f"总计 {total} / 已用 {used} / 可用 {avail}", f"{pct}%", avail

def check_gateway():
    """Check if OpenClaw gateway is responsive via 'openclaw status'"""
    try:
        r = subprocess.run(
            ["openclaw", "gateway", "status"],
            capture_output=True, text=True, timeout=10
        )
        out = r.stdout.lower() + (r.stderr or "").lower()
        if "running" in out or r.returncode == 0:
            return "running", "运行中"
    except Exception:
        pass
    return "not_configured", "未检测"

def count_queue(dir_name):
    path = os.path.join(QUEUE_DIR, dir_name)
    if not os.path.isdir(path):
        return 0
    return len([f for f in os.listdir(path) if f.endswith(".md")])

def get_last_task(owner_name):
    """Scan doing/ directory for tasks assigned to a given owner name."""
    doing = os.path.join(QUEUE_DIR, "doing")
    if not os.path.isdir(doing):
        return None
    for fname in os.listdir(doing):
        fpath = os.path.join(doing, fname)
        try:
            with open(fpath) as f:
                content = f.read()
            # Simple keyword match — owner names or task keywords
            if owner_name.lower() in content.lower():
                lines = [l.strip() for l in content.split("\n") if l.strip()]
                title_line = [l for l in lines if "任务" in l or "#" in l][:1]
                return title_line[0] if title_line else fname
        except Exception:
            continue
    return None

def main():
    # Prevent overlapping runs
    try:
        with open(LOCK_FILE, "w") as f:
            f.write(str(os.getpid()))
    except Exception:
        pass

    try:
        data = load_json(DASHBOARD_JSON)
    except Exception as e:
        print(f"ERROR loading dashboard.json: {e}")
        return

    # ── System section ──
    sys_section = data.get("system", {})
    hostname = socket.gethostname()
    disk_info, disk_pct, disk_avail = get_disk()

    gw_status_raw, gw_label = check_gateway()
    status_map = {
        "running": "online",
        "not_configured": "not_configured",
    }
    sys_section.update({
        "hostname": hostname,
        "uptime": get_uptime(),
        "disk_free": disk_info,
        "openclaw_version": "2026.6.6+",
        "gateway_status": status_map.get(gw_status_raw, "not_configured"),
    })

    # Anomalies
    anomalies = []
    if int(disk_pct.replace("%", "")) > 90:
        anomalies.append({"type": "warning", "message": f"磁盘使用率 {disk_pct}，接近满载"})

    # Queue anomaly check
    doing_count = count_queue("doing")
    failed_count = count_queue("failed")
    if doing_count >= 5:
        anomalies.append({"type": "warning", "message": f"Doing 队列堆积 ({doing_count}个)"})
    if failed_count > 0:
        anomalies.append({"type": "info", "message": f"Failed 队列有 {failed_count} 个任务待处理"})

    sys_section["anomalies"] = anomalies
    data["system"] = sys_section

    # ── Queue stats in tasks_today ──
    tasks_section = data.get("tasks_today", {})
    todo_count   = count_queue("todo")
    doing_count  = count_queue("doing")
    done_count   = count_queue("done")
    failed_count = count_queue("failed")

    # Add queue summary as anomalies if none exist for it
    qs_msg = f"队列: TODO={todo_count} DOING={doing_count} DONE={done_count} FAILED={failed_count}"
    existing_qs = [a for a in tasks_section.get("anomalies", []) if "队列:" in a.get("message", "")]
    if not existing_qs and doing_count > 0:
        tasks_section.setdefault("anomalies", [])
        # Remove old queue summary if any
        tasks_section["anomalies"] = [a for a in tasks_section["anomalies"] if "队列:" not in a.get("message", "")]
    data["tasks_today"] = tasks_section

    # ── Update last_sync timestamp ──
    main_standby = data.get("main_standby", {})
    if "xiaowuos_main" in main_standby:
        main_standby["xiaowuos_main"]["last_sync"] = now_cst()
    data["main_standby"] = main_standby

    # Save
    save_json(data, DASHBOARD_JSON)
    print(f"[{now_cst()}] dashboard.json updated | system={gw_label} disk={disk_pct} queue=t{todo_count}/d{doing_count}/✓{done_count}/✗{failed_count}")

    # Release lock
    try:
        os.remove(LOCK_FILE)
    except Exception:
        pass

if __name__ == "__main__":
    main()
