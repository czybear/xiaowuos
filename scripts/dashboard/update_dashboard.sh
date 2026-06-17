#!/bin/bash
# update_dashboard.sh — xiaowuOS 总状态仪表盘数据更新脚本
# Crontab: * * * * * /home/john/xiaowuOS/scripts/dashboard/update_dashboard.sh
# Cloud: zero | Local only | No private/finance access.

DASHBOARD_JSON="/home/john/xiaowuOS/status/dashboard.json"
QUEUE_DIR="/home/john/.xiaowuOS/queue"
LOCKFILE="/tmp/update_dashboard.lock"

# Prevent overlapping runs
if [ -f "$LOCKFILE" ]; then
  OLD_PID=$(cat "$LOCKFILE" 2>/dev/null)
  if kill -0 "$OLD_PID" 2>/dev/null; then
    exit 0
  fi
fi
echo $$ > "$LOCKFILE"

# ── Collect all metrics as env vars ──
export D_HOSTNAME=$(hostname)
export D_UPTIME=$(uptime -p | sed 's/up //')

export D_DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
export D_DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
export D_DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
export D_DISK_PCT=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')

export D_MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
export D_MEM_USED=$(free -h | awk '/^Mem:/{print $3}')
export D_MEM_AVAIL=$(free -h | awk '/^Mem:/{print $7}')

export D_OC_VERSION=$(openclaw --version 2>/dev/null | head -1)

GW_HTTP=$(curl -so /dev/null -w "%{http_code}" http://127.0.0.1:18789/ --connect-timeout 3 2>/dev/null || echo "000")
if [ "$GW_HTTP" = "200" ]; then
  export D_GW_STATUS="running"
elif [ "$GW_HTTP" = "000" ] && ! pgrep -f "openclaw.*gateway" >/dev/null 2>&1; then
  export D_GW_STATUS="stopped"
else
  export D_GW_STATUS="degraded"
fi
export D_GW_HTTP="$GW_HTTP"

if systemctl is-active --quiet frpc 2>/dev/null; then
  export D_FRPC="active"
elif pgrep -f "[f]rpc" >/dev/null 2>&1; then
  export D_FRPC="running"
else
  export D_FRPC="inactive"
fi

export D_TODO=$(ls "$QUEUE_DIR"/todo/*.md 2>/dev/null | wc -l)
export D_DOING=$(ls "$QUEUE_DIR"/doing/*.md 2>/dev/null | wc -l)
export D_DONE=$(ls "$QUEUE_DIR"/done/*.md 2>/dev/null | wc -l)
export D_FAILED=$(ls "$QUEUE_DIR"/failed/*.md 2>/dev/null | wc -l)

export D_NOW_CST=$(date '+%Y-%m-%dT%H:%M:%S+08:00')

# ── Patch JSON via Python (env vars, no interpolation issues) ──
export PYTHONIOENCODING=utf-8
python3 /home/john/xiaowuOS/scripts/dashboard/_patch.py

rm -f "$LOCKFILE"

# ── PATCH 3: Sync single state source (12:54) ──
bash ~/.xiaowuOS/scripts/sync_state.sh >> /tmp/state_sync.log 2>&1 || true
