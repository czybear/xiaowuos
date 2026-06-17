#!/usr/bin/env bash
###############################################################################
# xiaowuOS Phase 2 清理脚本 - DRY RUN ONLY
# Generated: 2026-06-13 05:40 (GMT+8)
# Author: 小悟同学（自动审计）
#
# ⚠️ 重要：本脚本默认只 echo，不执行任何 rm 命令
#    - 所有 rm/rmdir 均已注释掉
#    - 澄木老师需逐条确认后手动取消注释
#
# 使用方式：
#   1. bash xiaowuOS_outputs_phase2_cleanup_dry_run.sh    # 只看预览
#   2. 确认无误后，手动编辑取消某行的 rm 注释
#   3. 再次运行执行实际清理
###############################################################################

set -euo pipefail

BASE="/home/john/xiaowuOS"
DOT_XIAOWU="/home/john/.xiaowuOS"

echo "============================================================"
echo " xiaowuOS Phase 2 去重清理 - DRY RUN"
echo "============================================================"
echo ""
echo "时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""


###############################################################################
# A. 可删除候选（sha256 完全匹配 outputs 正源）
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 A类：可删除候选（~84 文件 / ~3.9MB）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- docs/lessons/ 全部为重复 ---
TARGET="$BASE/docs/lessons"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    COUNT=$(find "$TARGET" -type f | wc -l)
    echo "[A] $TARGET ($COUNT 文件 / $SIZE)"
    echo "     原因：4份教案+PPT的 sha256 与 outputs/courses/ 完全一致，已归位为正源"
    echo ""
    echo "     ▶ 删除命令（确认后再执行）："
    #rm -rf "$TARGET"
else
    echo "[SKIP] $TARGET 不存在"
fi

# --- .xiaowuOS/docs/lessons/ 全部为重复 ---
TARGET="$DOT_XIAOWU/docs/lessons"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    COUNT=$(find "$TARGET" -type f | wc -l)
    echo "[A] $TARGET ($COUNT 文件 / $SIZE)"
    echo "     原因：8份教案+PPT的 sha256 与 outputs/courses/ 完全一致，已全部跳过 rsync"
    echo ""
    echo "     ▶ 删除命令（确认后再执行）："
    #rm -rf "$TARGET"
else
    echo "[SKIP] $TARGET 不存在"
fi

# --- .xiaowuOS/docs/ 根目录 09嗨翻文件 全部为重复 ---
echo ""
echo "[A] $DOT_XIAOWU/docs/09嗨翻*"
echo "     原因：7个文件的 sha256 与 outputs/courses/.../09嗨翻/ 完全一致"
echo "     文件清单："
for f in "$DOT_XIAOWU/docs"/09嗨翻*; do
    [ -f "$f" ] && echo "       - $(basename "$f")"
done
echo ""
echo "     ▶ 删除命令（确认后再执行）："
#find "$DOT_XIAOWU/docs/" -maxdepth 1 -name '09嗨翻*' -exec rm {} +

# --- docs/零式协约/ 全部为重复 ---
TARGET="$BASE/docs/零式协约"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    COUNT=$(find "$TARGET" -type f | wc -l)
    echo "[A] $TARGET ($COUNT 文件 / $SIZE)"
    echo "     原因：5份项目文档的 sha256 与 projects/zprotocol_零式协约/ 完全一致"
    echo ""
    echo "     ▶ 删除命令（确认后再执行）："
    #rm -rf "$TARGET"
else
    echo "[SKIP] $TARGET 不存在"
fi

# --- .xiaowuOS/docs/零式协约/ 全部为重复 ---
TARGET="$DOT_XIAOWU/docs/零式协约"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    COUNT=$(find "$TARGET" -type f | wc -l)
    echo "[A] $TARGET ($COUNT 文件 / $SIZE)"
    echo "     原因：5份项目文档的 sha256 与 projects/zprotocol_零式协约/ 完全一致"
    echo ""
    echo "     ▶ 删除命令（确认后再执行）："
    #rm -rf "$TARGET"
else
    echo "[SKIP] $TARGET 不存在"
fi

# --- .xiaowuOS/docs/ SOP 文件已归位 docs/sop/ ---
echo ""
echo "[A] $DOT_XIAOWU/docs/ 中的 SOP 文件（2份）"
for f in "$DOT_XIAOWU/docs"/澄木备课SOP* "$DOT_XIAOWU/docs"/科创纪事创作*; do
    [ -f "$f" ] && echo "       - $(basename "$f") → sha256 与 docs/sop/ 一致"
done
echo ""
echo "     ▶ 删除命令（确认后再执行）："
#rm -f "$DOT_XIAOWU/docs/澄木备课SOP_V0.1.md"
#rm -f "$DOT_XIAOWU/docs/科创纪事创作 SOP_V0.1.md"

# --- .xiaowuOS/docs/ 临时文件 ---
echo ""
echo "[A] $DOT_XIAOWU/docs/ 中的 macOS Office 临时文件"
for f in "$DOT_XIAOWU/docs"/.~*; do
    [ -f "$f" ] && echo "       - $(basename "$f") → macOS .tmp file, 无价值"
done
echo ""
echo "     ▶ 删除命令（确认后再执行）："
#find "$DOT_XIAOWU/docs/" -maxdepth 1 -name '.~*' -exec rm {} +

# --- workspace/deliverables/ 28份为重复 ---
DELIVERABLES="$BASE/workspace/deliverables"
if [ -d "$DELIVERABLES" ]; then
    SIZE=$(du -sh "$DELIVERABLES" | cut -f1)
    COUNT=$(find "$DELIVERABLES" -type f | wc -l)
    echo "[A] $DELIVERABLES ($COUNT 文件 / $SIZE)"
    echo "     原因：28/29 文件的 sha256 与 outputs/reports/courses/articles/ 完全一致"
    echo "     ⚠️ 其中 1 个文件（人工智能视频创作课程-首版方案.md）为 Phase 1 遗漏，"
    echo "        需先单独迁移到 outputs/courses/，再删除整个目录"
    echo ""
    echo "     ▶ 步骤1: 补迁遗漏文件（确认后再执行）："
    SRC="$DELIVERABLES/人工智能视频创作课程-首版方案.md"
    [ -f "$SRC" ] && echo "       rsync -av --ignore-existing '$SRC' '$BASE/outputs/courses/'"
    #rsync -av --ignore-existing "$SRC" "$BASE/outputs/courses/" 2>/dev/null || true

    echo ""
    echo "     ▶ 步骤2: 删除整个 deliverables/（确认补迁完成后再执行）："
    #rm -rf "$DELIVERABLES"
fi

# --- xiaowuOS/courses/ 全部为重复 ---
echo ""
TARGET="$BASE/courses"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    COUNT=$(find "$TARGET" -type f | wc -l)
    echo "[A] $TARGET ($COUNT 文件 / $SIZE)"
    echo "     原因：全部 2 课次内容的 sha256 与 outputs/courses/ 完全一致"
    echo "     ⚠️ 这是最大目录，建议最后执行，确认 outputs/courses/ 完整后再删"
    echo ""
    echo "     ▶ 删除命令（确认 outputs/courses/ 100% 完整后再执行）："
    #rm -rf "$TARGET"
else
    echo "[SKIP] $TARGET 不存在"
fi


###############################################################################
# B. 建议归档后删除
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 B类：建议 tar.gz 归档后删除（21 文件）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BACKUP_DIR="/home/john/backups/xiaowuOS-archive-$(date +%Y%m%d)"

# workspace/course-planning/
TARGET="$BASE/workspace/course-planning"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[B] $TARGET ($SIZE, 4 文件)"
    echo "     原因：历史规划方案，有参考价值但不是正源"
    echo ""
    echo "     ▶ 步骤1: 归档（确认后再执行）："
    echo "       mkdir -p '$BACKUP_DIR' && tar czf '\$BACKUP_DIR/course-planning.tar.gz' -C '$BASE/workspace' course-planning/"
    #mkdir -p "$BACKUP_DIR" && tar czf "$BACKUP_DIR/course-planning.tar.gz" -C "$BASE/workspace" course-planning/

    echo ""
    echo "     ▶ 步骤2: 删除（确认归档成功后再执行）："
    #rm -rf "$TARGET"
fi

# workspace/memory/
TARGET="$BASE/workspace/memory"
if [ -d "$TARGET" ]; then
    SIZE=$(du -sh "$TARGET" | cut -f1)
    echo "[B] $TARGET ($SIZE, 17 文件)"
    echo "     原因：旧版 memory 日记录（2026-04~06），与 .openclaw/workspace/memory/ 不同源"
    echo ""
    echo "     ▶ 步骤1: 归档（确认后再执行）："
    echo "       mkdir -p '$BACKUP_DIR' && tar czf '\$BACKUP_DIR/workspace-memory.tar.gz' -C '$BASE/workspace' memory/"
    #mkdir -p "$BACKUP_DIR" && tar czf "$BACKUP_DIR/workspace-memory.tar.gz" -C "$BASE/workspace" memory/

    echo ""
    echo "     ▶ 步骤2: 删除（确认归档成功后再执行）："
    #rm -rf "$TARGET"
fi


###############################################################################
# C. 暂时保留（需澄木老师人工判断）
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 C类：暂时保留（~23 文件，不动）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[C] $DOT_XIAOWU/docs/_archive/ (~18 文件)"
echo "     → 夜校备课过程稿 + 系统诊断报告，含历史上下文"
echo "     → 需澄木老师判断是否迁移到 outputs/courses/*/_archive/"

echo ""
echo "[C] $DOT_XIAOWU/docs/xiaowuOS-v0.1-devlog.md"
echo "     → 开发日志，系统历史信息"

echo ""
echo "[C] outputs/courses/ 内部命名重复（4组）"
echo "     → 上课清单_最终版.md vs _archive/上课清单_最终版.md (同 hash)"
echo "     → 备课包_最终版.md vs 教师备课版.md (同 hash)"
echo "     → 投屏PPT_最终版.md vs 学员投屏版.md (同 hash)"
echo "     → 投屏PPT_最终版.pptx vs 学员投屏版.pptx (同 hash)"
echo "     → 需澄木老师确认保留哪个命名版本"


###############################################################################
# D. 需要迁移（outputs 中缺失）
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 D类：需补迁到 outputs/（1 文件）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SRC="$DELIVERABLES/人工智能视频创作课程-首版方案.md"
if [ -f "$SRC" ]; then
    echo "[D] $SRC"
    echo "     原因：Phase 1 遗漏，未复制到 outputs/courses/"
    echo ""
    echo "     ▶ 补迁命令（确认后再执行）："
    echo "       rsync -av --ignore-existing '$SRC' '$BASE/outputs/courses/'"
    #rsync -av --ignore-existing "$SRC" "$BASE/outputs/courses/"
else
    echo "[SKIP] $SRC 不存在，可能已被清理"
fi


###############################################################################
# E. 禁止删除
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 E类：禁止删除（绝对不动）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[E] $DOT_XIAOWU/bin/, config/, data/"
echo "     → 系统运行必需文件"

echo "[E] /home/john/.openclaw/workspace/memory/"
echo "     → OpenClaw 运行时 memory，不在归位范围内"


###############################################################################
# 清理后验证步骤
###############################################################################

echo ""
echo "============================================================"
echo " 🔒 清理后必做验证"
echo "============================================================"
echo ""
echo "1. 确认 outputs/courses/ 完整："
echo "   find $BASE/outputs/courses/ -type f | wc -l    # 应 ≥ 36"
echo ""
echo "2. 确认 outputs/reports/ 完整："
echo "   find $BASE/outputs/reports/ -type f | wc -l     # 应 = 19"
echo ""
echo "3. 确认 outputs/articles/ 完整："
echo "   find $BASE/outputs/articles/ -type f | wc -l    # 应 ≥ 3"
echo ""
echo "4. 确认 projects/ 完整："
echo "   find $BASE/projects/zprotocol_零式协约/ -type f | wc -l  # 应 = 5"
echo ""
echo "5. 确认主系统正常运行："
echo "   openclaw status && openclaw gateway status"
echo ""
echo "============================================================"
echo " 📊 清理汇总"
echo "============================================================"
echo ""
echo "A类（直接删）: ~84 文件 / ~3.9MB（全部 sha256 确认重复）"
echo "B类（归档后删）: 21 文件（course-planning + workspace/memory）"
echo "C类（保留）: ~23 文件（_archive/ + devlog + 内部命名重复）"
echo "D类（补迁）: 1 文件（Phase 1 遗漏）"
echo "E类（禁止删）: .xiaowuOS/bin/config/data/ + .openclaw/memory/"
echo ""
echo "============================================================"
echo " DRY RUN 完成 - 无文件被删除"
echo "============================================================"
