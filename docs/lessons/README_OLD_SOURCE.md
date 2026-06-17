# 🧊 旧目录冻结说明

## 状态：已冻结 — 不再作为正式产出物正源

**冻结日期：** 2026-06-13  
**原因：** xiaowuOS 目录优化 Phase 2.5 — 正源迁移完成，旧目录保留用于校验和回溯

---

## 当前正源位置

本目录中的正式产出物已归位至以下正源路径：

| 原内容类型 | 新正源路径 |
|-----------|-----------|
| 课程教案、课件、PPT | `/home/john/xiaowuOS/outputs/courses/` |
| 正式报告（PRD、方案、诊断） | `/home/john/xiaowuOS/outputs/reports/` |
| 文章产出 | `/home/john/xiaowuOS/outputs/articles/` |
| 零式协约项目文档 | `/home/john/xiaowuOS/projects/zprotocol_零式协约/` |

---

## 保留原因

1. **校验用途** — Phase 2 sha256 比对确认所有文件已复制，但澄木老师需人工最终确认
2. **回溯用途** — 部分文件可能有修改历史上下文
3. **安全缓冲** — 正源稳定运行 7 天后再执行清理

---

## 操作限制

| 操作 | 状态 |
|------|------|
| ❌ 新增正式交付物 | **禁止** — 新产出请放入 `outputs/` 对应目录 |
| ❌ 自动删除 | **禁止** — 清理需澄木老师手动确认 |
| ✅ 只读访问 | 允许 — 用于校验和回溯 |
| ✅ 人工审查 | 允许 — 澄木老师可手动审核文件内容 |

---

## 预计清理时间

- **最早：** 2026-06-20（正源冻结满 7 天后）
- **前提：** 澄木老师确认 outputs/ 正源完整无误
- **方式：** Phase 3 清理执行，需手动取消 dry-run 脚本中的 rm 注释

---

## 审计报告

详细审计数据见：
- `/home/john/xiaowuOS/docs/system_audit/xiaowuOS_outputs_phase2_dedup_audit_20260613_054000.md`
- `/home/john/xiaowuOS/docs/system_audit/xiaowuOS_outputs_phase2_cleanup_dry_run.sh`

---

*如需修改此目录状态，请联系澄木老师审批。*
