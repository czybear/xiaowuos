#!/bin/bash

# xiaowuOS V0.1 最小调度器 - 修复版
# 用于在不重启 Gateway 的前提下主动启动任务

LOG_FILE="/home/john/.xiaowuOS/logs/scheduler.log"
LOCK_FILE="/tmp/xiaowuOS_scheduler.lock"
QUEUE_DIR="/home/john/.xiaowuOS/queue"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# dry-run 模式检查
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
else
    DRY_RUN=false
fi

# 检查锁文件
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE")
    if ps -p "$LOCK_PID" > /dev/null 2>&1; then
        log "Scheduler already running (PID: $LOCK_PID), exiting"
        exit 1
    else
        log "Stale lock file found, removing"
        rm -f "$LOCK_FILE"
    fi
fi

# 创建锁文件
echo $$ > "$LOCK_FILE"
log "Scheduler started with PID $$"

# 检查配置文件
if [ ! -f "$QUEUE_DIR/scheduler_config.json" ]; then
    log "ERROR: scheduler_config.json not found at $QUEUE_DIR/scheduler_config.json"
    rm -f "$LOCK_FILE"
    exit 1
fi

# 获取最大并行数 (使用 sed 替代 jq)
MAX_AGENTS=$(sed -n 's/.*"max_parallel_agents": *\([0-9]*\).*/\1/p' "$QUEUE_DIR/scheduler_config.json")
CURRENT_DOING=$(ls "$QUEUE_DIR/doing"/*.md 2>/dev/null | wc -l)

log "Current doing count: $CURRENT_DOING, max allowed: $MAX_AGENTS"

# 并发控制逻辑
AVAILABLE_SLOTS=$((MAX_AGENTS - CURRENT_DOING))

if [ "$DRY_RUN" = true ]; then
    log "=== DRY-RUN MODE ==="
    log "Available slots: $AVAILABLE_SLOTS (max: $MAX_AGENTS, current: $CURRENT_DOING)"
    
    if [ "$AVAILABLE_SLOTS" -le 0 ]; then
        log "No available slots, skipping task scheduling"
    else
        TODO_COUNT=$(ls "$QUEUE_DIR/todo"/*.md 2>/dev/null | wc -l)
        log "Found $TODO_COUNT tasks in todo queue"
        
        # 显示将要启动的任务
        for ((i=1; i<=AVAILABLE_SLOTS && i<=TODO_COUNT; i++)); do
            TASK_FILE=$(ls "$QUEUE_DIR/todo"/*.md 2>/dev/null | sed -n "${i}p")
            if [ ! -z "$TASK_FILE" ]; then
                TASK_NAME=$(basename "$TASK_FILE" .md)
                log "Would start task: $TASK_NAME"
                # 这里可以添加任务信息读取逻辑
            fi
        done
    fi
    
    log "DRY-RUN completed"
    rm -f "$LOCK_FILE"
    exit 0
fi

# 正式执行逻辑
if [ "$AVAILABLE_SLOTS" -le 0 ]; then
    log "No available slots ($AVAILABLE_SLOTS), skipping task scheduling"
else
    TODO_COUNT=$(ls "$QUEUE_DIR/todo"/*.md 2>/dev/null | wc -l)
    if [ "$TODO_COUNT" -gt 0 ]; then
        log "Starting task scheduling: $TODO_COUNT tasks in todo, $AVAILABLE_SLOTS available slots"
        
        # 启动最多 AVAILABLE_SLOTS 个任务
        for ((i=1; i<=AVAILABLE_SLOTS && i<=TODO_COUNT; i++)); do
            # 获取第 i 个待办任务（按文件名排序）
            TASK_FILE=$(ls "$QUEUE_DIR/todo"/*.md 2>/dev/null | sed -n "${i}p")
            if [ ! -z "$TASK_FILE" ]; then
                TASK_NAME=$(basename "$TASK_FILE" .md)
                log "Starting task: $TASK_NAME"
                
                # 移动任务到 doing 目录
                mv "$TASK_FILE" "$QUEUE_DIR/doing/"
                log "Moved $TASK_NAME to doing directory"
            fi
        done
        
        # 更新 dashboard
        /home/john/.xiaowuOS/scripts/sync_state.sh 2>/dev/null || log "Warning: sync_state.sh failed"
        log "Dashboard updated"
    else
        log "No tasks in todo queue"
    fi
fi

# 清理锁文件
rm -f "$LOCK_FILE"
log "Scheduler finished"
