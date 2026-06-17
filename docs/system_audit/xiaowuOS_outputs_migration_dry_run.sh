#!/usr/bin/env bash
###############################################################################
# xiaowuOS 目录优化 - 产出物归位 DRY RUN
# Generated: 2026-06-13 05:18 (GMT+8)
# Author: 小悟同学（自动审计）
#
# ⚠️ 重要：本脚本默认只 echo，不移动/删除/覆盖任何文件
#    - 使用 rsync --ignore-existing 避免覆盖已有文件
#    - 所有 rm 均已注释掉
#    - 澄木老师需逐条确认后手动取消注释
#
# 使用方式：
#   1. bash xiaowuOS_outputs_migration_dry_run.sh    # 只看预览
#   2. 确认无误后，手动编辑取消某行的 rsync 注释
#   3. 再次运行执行实际复制（非移动）
#   4. 确�� copies 正确后，再处理源文件清理
###############################################################################

set -euo pipefail

BASE="/home/john/xiaowuOS"
DOT_XIAOWU="/home/john/.xiaowuOS"
OUTPUTS="$BASE/outputs"

echo "============================================================"
echo " xiaowuOS 目录优化 - outputs 产出物归位 DRY RUN"
echo "============================================================"
echo ""
echo "基目录: $BASE"
echo "目标目录: $OUTPUTS"
echo "时间:   $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

# ============================================================
# 第0步：创建 outputs/ 目录结构（如不存在）
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 第0步：创建 outputs/ 目录结构"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

mkdir -p "$OUTPUTS"/{courses,articles,slides,reports,media,exports} 2>/dev/null && echo "✅ outputs/ 目录结构已就绪" || echo "⚠️ outputs/ 创建失败，检查权限"
mkdir -p "$BASE/projects/zero-contract" 2>/dev/null && echo "✅ projects/zero-contract/ 已就绪" || true

# ============================================================
# 第1步：courses/ → outputs/courses/（整体搬迁）
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 第1步：courses/ → outputs/courses/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SRC="$BASE/courses/20260611_09嗨翻人工智能之决策支持"
DST="$OUTPUTS/courses/20260611_09嗨翻人工智能之决策支持"
if [ -d "$SRC" ]; then
    SIZE=$(du -sh "$SRC" | cut -f1)
    echo "[COPY] $SRC ($SIZE) → $DST/"
    echo "       rsync -av --ignore-existing \"$SRC/\" \"$DST/\""
    #rsync -av --ignore-existing "$SRC/" "$DST/"
else
    echo "[SKIP] $SRC 不存在"
fi

SRC="$BASE/courses/20260613_GESP-C4_植物大战僵尸"
DST="$OUTPUTS/courses/20260613_GESP-C4-轩轩最后一波防守"
if [ -d "$SRC" ]; then
    SIZE=$(du -sh "$SRC" | cut -f1)
    echo "[COPY] $SRC ($SIZE) → $DST/"
    echo "       rsync -av --ignore-existing \"$SRC/\" \"$DST/\""
    #rsync -av --ignore-existing "$SRC/" "$DST/"
else
    echo "[SKIP] $SRC 不存在"
fi

# ============================================================
# 第2步：docs/lessons/ → outputs/courses/（移出 docs）
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 第2步：docs/lessons/ → outputs/courses/"
echo "       ⚠️ 这些文件混放在 docs/ 中，正式产出物应归位"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# GESP-C4 考级辅导
DST="$OUTPUTS/courses/20260613_GESP-C4-考级辅导"
mkdir -p "$DST" 2>/dev/null || true
for f in "$BASE/docs/lessons"/GESP-C4-考级辅导-20260613*; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        echo "[COPY] $f ($SIZE) → $DST/$FNAME"
        #rsync -av --ignore-existing "$f" "$DST/"
    fi
done

# 科创启蒙-零式协约
DST="$OUTPUTS/courses/20260613_科创启蒙-零式协约"
mkdir -p "$DST" 2>/dev/null || true
for f in "$BASE/docs/lessons"/科创启蒙-零式协约-20260613*; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        echo "[COPY] $f ($SIZE) → $DST/$FNAME"
        #rsync -av --ignore-existing "$f" "$DST/"
    fi
done

# ============================================================
# 第3步：.xiaowuOS/docs/ → outputs/courses/（正式交付物）
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 第3步：.xiaowuOS/docs/09嗨翻_* → outputs/courses/"
echo "       ⚠️ 系统运行目录中的正式 PPT/教案应归位"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

DST="$OUTPUTS/courses/20260611_09嗨翻人工智能之决策支持"
mkdir -p "$DST" 2>/dev/null || true
for f in "$DOT_XIAOWU/docs"/09嗨翻人工智能之决策支持_20260611_*; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        echo "[COPY] $f ($SIZE) → $DST/$FNAME"
        #rsync -av --ignore-existing "$f" "$DST/"
    fi
done

# .xiaowuOS/docs/lessons/ 中的文件（与 docs/lessons/ 重复）
echo ""
echo "[WARN] .xiaowuOS/docs/lessons/GESP-C4-植物大战僵尸-20260613/V0.2/*"
echo "       → 已在 outputs/courses/ 中存在，不重复复制"

echo "[WARN] .xiaowuOS/docs/lessons/GESP-C4-考级辅导-20260613*"
echo "       → 已在 docs/lessons/ 中（上一步已处理），不重复复制"

echo "[WARN] .xiaowuOS/docs/lessons/科创启蒙-零式协约-20260613*"
echo "       → 已在 docs/lessons/ 中（上一步已处理），不重复复制"

# ============================================================
# 第4步：workspace/deliverables/ → outputs/{courses,articles,reports}/
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 第4步：workspace/deliverables/ → outputs/{courses,articles,reports}/"
echo "       ⚠️ 30+ 份交付物需分类归位，以下为建议分类"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

DELIVERABLES="$BASE/workspace/deliverables"

# → outputs/courses/（课程相关）
DST="$OUTPUTS/courses"
echo "→ $DST/"
for f in \
    "$DELIVERABLES"/人工智能视频创作课程-* \
    "$DELIVERABLES"/未来创客-* \
    "$DELIVERABLES"/编程习惯-*; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        echo "   [COPY] $FNAME ($SIZE)"
        #rsync -av --ignore-existing "$f" "$DST/"
    fi
done

# → outputs/articles/（文章产出）
DST="$OUTPUTS/articles"
mkdir -p "$DST" 2>/dev/null || true
echo ""
echo "→ $DST/"
for f in \
    "$DELIVERABLES"/科创教育纪事* \
    "$DELIVERABLES"/澄木日课-*; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        echo "   [COPY] $FNAME ($SIZE)"
        #rsync -av --ignore-existing "$f" "$DST/"
    fi
done

# → outputs/reports/（报告类交付物）
DST="$OUTPUTS/reports"
mkdir -p "$DST" 2>/dev/null || true
echo ""
echo "→ $DST/"
for f in \
    "$DELIVERABLES"/澄木系统PRD-* \
    "$DELIVERABLES"/澄木系统-定义-* \
    "$DELIVERABLES"/dashboard-文案替换清单* \
    "$DELIVERABLES"/OpenClaw-cron-诊断* \
    "$DELIVERABLES"/johnonlife.com-* \
    "$DELIVERABLES"/小悟同学首页-* \
    "$DELIVERABLES"/小悟仪表盘-* \
    "$DELIVERABLES"/澄木教育纪事-* \
    "$DELIVERABLES"/澄木教育子系统-* \
    "$DELIVERABLES"/澄木系统项目推进计划* \
    "$DELIVERABLES"/澄木系统-09点前交付清单* \
    "$DELIVERABLES"/硬盘整理方案-* \
    "$DELIVERABLES"/小视同学工作流* \
    "$DELIVERABLES"/小视设计接单规范* \
    "$DELIVERABLES"/国内免费Token测试配置方案* \
    "$DELIVERABLES"/daily-work-report-* \
    "$DELIVERABLES"/飞书同步测试-*; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        echo "   [COPY] $FNAME ($SIZE)"
        #rsync -av --ignore-existing "$f" "$DST/"
    fi
done

echo ""
echo "[TODO] 澄木老师需审核 deliverables/ 中剩余文件归属"
echo "       当前可能遗漏的文件："
if [ -d "$DELIVERABLES" ]; then
    find "$DELIVERABLES" -type f -name "*.md" | while read -r f; do
        echo "         - $(basename "$f")"
    done
fi

# ============================================================
# 第5步：零式协约文档 → projects/zero-contract/
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 第5步：docs/零式协约/ → projects/zero-contract/"
echo "       ⚠️ 项目文档应归入 projects/，非 docs/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SRC="$BASE/docs/零式协约"
DST="$BASE/projects/zero-contract"
if [ -d "$SRC" ]; then
    SIZE=$(du -sh "$SRC" | cut -f1)
    echo "[COPY] $SRC ($SIZE) → $DST/"
    echo "       rsync -av --ignore-existing \"$SRC/\" \"$DST/\""
    #rsync -av --ignore-existing "$SRC/" "$DST/"

    # .xiaowuOS/docs/零式协约/ 为重复副本
    SRC2="$DOT_XIAOWU/docs/零式协约"
    if [ -d "$SRC2" ]; then
        echo ""
        echo "[WARN] $SRC2/ 为零式协约文档的重复副本，不重复复制"
    fi
else
    echo "[SKIP] $SRC 不存在"
fi

# ============================================================
# 第6步：SOP 文件归位 docs/sop/
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 第6步：SOP 文件 → docs/sop/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

mkdir -p "$BASE/docs/sop" 2>/dev/null || true

for f in \
    "$DOT_XIAOWU/docs/澄木备课SOP_V0.1.md" \
    "$DOT_XIAOWU/docs/科创纪事创作 SOP_V0.1.md"; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        DST_F="$BASE/docs/sop/$FNAME"
        echo "[COPY] $f ($SIZE) → $DST_F"
        #rsync -av --ignore-existing "$f" "$DST_F"
    fi
done

# .openclaw/workspace 中的 SOP
for f in \
    "/home/john/.openclaw/workspace/公众号文章创作 SOP.md"; do
    if [ -f "$f" ]; then
        FNAME=$(basename "$f")
        SIZE=$(du -sh "$f" | cut -f1)
        DST_F="$BASE/docs/sop/$FNAME"
        echo "[COPY] $f ($SIZE) → $DST_F"
        #rsync -av --ignore-existing "$f" "$DST_F"
    fi
done

# ============================================================
# 总结
# ============================================================
echo ""
echo "============================================================"
echo " 📊 迁移汇总"
echo "============================================================"
echo ""
echo "步骤 | 来源 | 目标 | 文件数"
echo "------|------|------|-------"
echo "第1步 | courses/ | outputs/courses/ | ~20 文件 (1MB)"
echo "第2步 | docs/lessons/ | outputs/courses/ | ~4 文件 (~150KB)"
echo "第3步 | .xiaowuOS/docs/ | outputs/courses/ | ~5 文件"
echo "第4步 | workspace/deliverables/ | outputs/{courses,articles,reports}/ | ~30 文件 (276KB)"
echo "第5步 | docs/零式协约/ | projects/zero-contract/ | 5 文件 (40KB)"
echo "第6步 | SOP 散落在各处 | docs/sop/ | ~3 文件"
echo ""
echo "⚠️ 所有 rsync 命令均已注释，需手动取消注释后执行"
echo ""
echo "============================================================"
echo " ⚠️ 澄木老师需确认的事项"
echo "============================================================"
echo ""
echo "1. workspace/deliverables/ (276KB, 30+ 文件) 分类是否准确？"
echo "   → 建议逐目���审核后再执行 rsync"
echo ""
echo "2. .xiaowuOS/docs/lessons/ 全部为副本，确认去重后正源在 outputs/courses/"
echo ""
echo "3. docs/lessons/ 搬迁后该目录为空，需手动删除"
echo ""
echo "4. workspace/course-planning/ (4 文件) 未包含在本次迁移中"
echo "   → 规划类文档归属：workspace/staging/（中间稿）还是 outputs/reports/？"
echo ""
echo "5. workspace/memory/ (~92KB, ~30 日记录) 未包含在本次迁移中"
echo "   → 与 .openclaw/workspace/memory/ 不同源，需人工确认是否合并"
echo ""

echo "============================================================"
echo " 🔒 安全验证（复制完成后必做）"
echo "============================================================"
echo ""
echo "→ ls -la $OUTPUTS/courses/ | head   # 确认文件已到位"
echo "→ diff -r <源> <目标>              # 比对内容一致性"
echo "→ 确认无误后再清理副本（rm）"
echo ""
echo "============================================================"
echo " DRY RUN 完成 - 无文件被移动或删除"
echo "============================================================"
