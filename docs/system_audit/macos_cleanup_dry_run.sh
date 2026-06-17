#!/usr/bin/env bash
###############################################################################
# macOS OpenClaw Legacy Cleanup - DRY RUN ONLY
# Generated: 2026-06-13 04:56 (GMT+8)
# Author: 小悟同学（自动审计）
#
# ⚠️ 重要：本脚本默认只 echo，不执行任何 rm 命令
#    所有 rm 均已注释掉，需澄木老师逐条确认后手动取消注释
#
# 使用方式：
#   1. bash macos_cleanup_dry_run.sh          # 只看预览
#   2. 确认无误后，手动编辑取消某行的 #rm 注释
#   3. 再次运行执行实际删除
###############################################################################

set -euo pipefail

BASE="/home/john/xiaowuOS/macos-openclaw-backup"

echo "============================================================"
echo " macOS OpenClaw Legacy Cleanup - DRY RUN"
echo "============================================================"
echo ""
echo "基目录: $BASE"
echo "时间:   $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

# 检查基目录是否存在
if [ ! -d "$BASE" ]; then
    echo "❌ 错误: $BASE 不存在，退出。"
    exit 1
fi

# 当前大小
echo "📊 macOS 备份当前大小:"
du -sh "$BASE" 2>/dev/null
echo ""
echo "------------------------------------------------------------"


###############################################################################
# A. 可以直接删除（低风险）
# 预计释放：~2.5GB
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 A 类：直接可删除（低风险）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# backups/ - 嵌套旧备份，主系统已完整运行
TARGET="$BASE/backups"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：嵌套旧备份（2026-06-01 快照），主系统已完整运行且有更新版本"
    #rm -rf "$TARGET"
else
    echo "[A] $TARGET (不存在，跳过)"
fi

# npm/ - npm 缓存
TARGET="$BASE/npm"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：npm node_modules 缓存，OpenClaw CLI 已安装在本机"
    #rm -rf "$TARGET"
else
    echo "[A] $TARGET (不存在，跳过)"
fi

# tmp/ - 编译缓存 + playwright artifacts
TARGET="$BASE/tmp"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：JIT 编译缓存、playwright artifacts，无保留价值"
    #rm -rf "$TARGET"
else
    echo "[A] $TARGET (不存在，跳过)"
fi

# browser/ - Playwright user data
TARGET="$BASE/browser"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：Playwright user-data profile，可重建"
    #rm -rf "$TARGET"
else
    echo "[A] $TARGET (不存在，跳过)"
fi

# subagents/ - 旧 agent run 状态
TARGET="$BASE/subagents"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：旧 agent 运行状态数据，已过时"
    #rm -rf "$TARGET"
else
    echo "[A] $TARGET (不存在，跳过)"
fi

# delivery-queue/ - 已完成投递队列
TARGET="$BASE/delivery-queue"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：已完成投递队列，无保留价值"
    #rm -rf "$TARGET"
else
    echo "[A] $TARGET (不存在，跳过)"
fi

# run/ + locks/ - 运行时临时文件
TARGET="$BASE/run"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：运行时 PID/状态文件，已失效"
    #rm -rf "$TARGET"
fi

TARGET="$BASE/locks"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[A] $TARGET ($SIZE)"
    echo "     理由：旧锁文件，已失效"
    #rm -rf "$TARGET"
fi

echo ""


###############################################################################
# B. 建议压缩备份后删除（中风险）
# 预计释放：~5.7GB（压缩后 ~1-2GB）
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 B 类：建议 tar.gz 压缩后删除（中风险）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️ 以下操作需要先确认是否需要保留这些文件的历史副本。"
echo "   如果确认无需保留，可先注释掉 tar 命令，再取消 rm 注释。"
echo ""

# workspace/mirrors/ - 镜像站点数据
TARGET="$BASE/workspace/mirrors"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[B] $TARGET ($SIZE)"
    echo "     理由：dashima.net 镜像站点数据，可能未来查阅"
    echo ""
    echo "     ▶ 步骤1: 压缩备份（如需保留）"
    BACKUP_DIR="/home/john/backups/xiaowuOS-macos-legacy"
    echo "       mkdir -p $BACKUP_DIR && tar czf \$BACKUP_DIR/mirrors_archive_$(date +%Y%m%d).tar.gz -C \"$BASE/workspace\" mirrors/"
    echo ""
    echo "     ▶ 步骤2: 删除原文件（确认备份后）"
    #rm -rf "$TARGET"
else
    echo "[B] $TARGET (不存在，跳过)"
fi

# workspace/outputs/ - Lesson7 AI 图片资产
TARGET="$BASE/workspace/outputs"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[B] $TARGET ($SIZE)"
    echo "     理由：Lesson7 AI 最终版、jimeng 下载等图片资产，有纪念价值"
    echo ""
    echo "     ▶ 步骤1: 压缩备份（如需保留）"
    BACKUP_DIR="/home/john/backups/xiaowuOS-macos-legacy"
    echo "       mkdir -p $BACKUP_DIR && tar czf \$BACKUP_DIR/outputs_archive_$(date +%Y%m%d).tar.gz -C \"$BASE/workspace\" outputs/"
    echo ""
    echo "     ▶ 步骤2: 删除原文件（确认备份后）"
    #rm -rf "$TARGET"
else
    echo "[B] $TARGET (不存在，跳过)"
fi

# media/ - AI 生成图 + 收发媒体
TARGET="$BASE/media"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[B] $TARGET ($SIZE)"
    echo "     理由：AI 生成图片、inbound/outbound 媒体文件，可清理"
    echo ""
    echo "     ▶ 步骤1: 压缩备份（如需保留）"
    BACKUP_DIR="/home/john/backups/xiaowuOS-macos-legacy"
    echo "       mkdir -p $BACKUP_DIR && tar czf \$BACKUP_DIR/media_archive_$(date +%Y%m%d).tar.gz -C \"$BASE\" media/"
    echo ""
    echo "     ▶ 步骤2: 删除原文件（确认备份后）"
    #rm -rf "$TARGET"
else
    echo "[B] $TARGET (不存在，跳过)"
fi

# logs/ - 运行日志
TARGET="$BASE/logs"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[B] $TARGET ($SIZE)"
    echo "     理由：运行日志，可归档后删除"
    echo ""
    echo "     ▶ 步骤1: 压缩备份（如需保留）"
    BACKUP_DIR="/home/john/backups/xiaowuOS-macos-legacy"
    echo "       mkdir -p $BACKUP_DIR && tar czf \$BACKUP_DIR/logs_archive_$(date +%Y%m%d).tar.gz -C \"$BASE\" logs/"
    echo ""
    echo "     ▶ 步骤2: 删除原文件（确认备份后）"
    #rm -rf "$TARGET"
else
    echo "[B] $TARGET (不存在，跳过)"
fi

echo ""


###############################################################################
# C. 暂时保留（高风险）
# 约 ~1GB
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 C 类：暂时保留（高风险 - 未迁移资产）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[C] $BASE/workspace/software-digest/ (~8.3MB)"
echo "     理由：C++ 项目源码，有开发价值但未迁移至主系统"

TARGET="$BASE/workspace/wechat-mini-program"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
fi
echo "[C] $BASE/workspace/wechat-mini-program/ (小)"
echo "     理由：微信小程序服务端代码，未来可能复用"

TARGET="$BASE/workspace/lesson-prep"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
fi
echo "[C] $BASE/workspace/lesson-prep/ (~172KB)"
echo "     理由：旧备课项目结构，可参考"

TARGET="$BASE/agents"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
fi
echo "[C] $BASE/agents/ (~849MB)"
echo "     理由：Agent 会话数据（hermes/sqlite），可能含历史上下文"

TARGET="$BASE/memory"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
fi
echo "[C] $BASE/memory/ (~26MB)"
echo "     理由：旧 memory SQLite，主系统已更新但需确认无遗漏"

echo ""


###############################################################################
# D. 禁止删除（极高风险）
# <50KB
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 D 类：禁止删除（极高风险 - 敏感配置/密钥）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[D] $BASE/service-env/"
echo "     ⚠️ 含 Google Cloud Project ID (gen-lang-client-0753914132)"
echo "        需确认主系统 .env 是否已配置此字段"
echo ""

echo "[D] $BASE/credentials/"
echo "     ⚠️ 含 Telegram/Feishu pairing & allowFrom 旧凭证"
echo "        删除后无法恢复旧 pairing"
echo ""

TARGET="$BASE/agents/main/agent"
if [ -d "$TARGET" ]; then
    echo "[D] $TARGET"
    echo "     ⚠️ 主 agent 配置数据，虽主系统有新版但保留以防万一"
fi

TARGET="$BASE/workspace/knowledge"
if [ -d "$TARGET" ]; then
    echo "[D] $TARGET/"
    echo "     ⚠️ 知识库内容（软件纪事），未确认已迁移"
fi

echo ""


###############################################################################
# 总结 & 验证
###############################################################################

echo ""
echo "============================================================"
echo " 📊 清理总结"
echo "============================================================"
echo ""
echo "A 类（直接删）: ~2.5GB → backups, npm, tmp, browser, subagents, delivery-queue, run, locks"
echo "B 类（压缩后删）: ~5.7GB → mirrors, outputs, media, logs (压缩后 ~1-2GB)"
echo "C 类（保留）: ~1GB → software-digest, wechat-mini-program, lesson-prep, agents, memory"
echo "D 类（禁止删）: <50KB → service-env, credentials, main agent, knowledge"
echo ""
echo "预计安全释放：3-6GB（取决于 B 类是否压缩保留）"
echo ""

# 当前剩余大小估算
REMAINING_C=$(du -sh "$BASE/workspace/software-digest" 2>/dev/null | cut -f1)
REMAINING_D="<50KB"
echo "删除后预计剩余：~$REMAINING_C + $REMAINING_D"
echo ""

# 主系统验证提醒
echo "============================================================"
echo " ⚠️ 澄木老师需确认的事项"
echo "============================================================"
echo ""
echo "1. Google Cloud Project ID 是否需要保留在主系统 .env 中？"
echo "   → cat $BASE/service-env/ai.openclaw.gateway.env | grep GOOGLE_CLOUD_PROJECT"
echo ""
echo "2. mirrors/dashima.net (5.6GB) 是否还需要查阅？"
echo "   → 如需保留，先 tar.gz 到 /home/john/backups/"
echo ""
echo "3. software-digest 项目是否需要迁移至主系统？"
echo ""
echo "4. wechat-mini-program 代码是否需要复用？"
echo ""
echo "5. agents/hermes 会话数据中是否有重要历史信息？"
echo ""

echo "============================================================"
echo " 🔒 安全验证（清理后必做）"
echo "============================================================"
echo ""
echo "→ openclaw status"
echo "→ openclaw gateway status"
echo "→ 确认 cron job 正常运行"
echo "→ 确认 Telegram 消息收发正常"
echo "→ 确认 Memory search 可用"
echo ""
echo "============================================================"
echo " DRY RUN 完成 - 无文件被删除"
echo "============================================================"
