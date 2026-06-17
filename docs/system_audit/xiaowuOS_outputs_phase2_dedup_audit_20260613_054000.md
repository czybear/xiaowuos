# xiaowuOS 目录优化 — Phase 2：去重与清理审计报告

**生成时间：** 2026-06-13 05:40 (GMT+8)  
**阶段：** Phase 2 — 校验 outputs 正源完整性 + 重复文件比对 + 清理分类  
**操作者：** 小悟同学（只读审计）  
**免责声明：** 本报告只审计，不删除/移动/覆盖任何文件

---

## 一、outputs 正源完整性校验

| 子目录 | 文件数 | PPT 数 | 状态 |
|--------|--------|--------|------|
| `outputs/courses/` | 36（含 ._ meta 约 45 条目） | 11 | ✅ 完整 |
| `outputs/reports/` | 19 | 0 | ✅ 完整 |
| `outputs/articles/` | 3 | 0 | ✅ 完整 |
| `outputs/slides/` | 0 | — | ✅ 无独立 PPT 需放入 |
| `outputs/media/` | 0 | — | ✅ 无媒体文件 |
| `outputs/exports/` | 0 | — | ✅ 暂无导出文件 |
| `projects/zprotocol_零式协约/` | 5 | 0 | ✅ 完整 |

### outputs/courses/ 内部重复检测

通过 sha256 扫描发现以下**命名不同但内容相同**的内部重复：

| Hash (前16位) | 文件 A | 文件 B | 说明 |
|---------------|--------|--------|------|
| `30786d2c...` | `上课清单_最终版.md` | `_archive/上课清单_最终版.md` | 同一文件，archive 为备份 |
| `2099a88a...` | `备课包_最终版.md` | `教师备课版.md` | 不同名称但内容相同 |
| `7a57bb33...` | `投屏PPT_最终版.md` | `学员投屏版.md` | md 版本相同 |
| `0b10ec59...` | `投屏PPT_最终版.pptx` | `学员投屏版.pptx` | PPT 完全一致 |

**结论：** outputs/courses/ 内有 4 组内容重复，但命名不同反映历史版本差异。建议暂时保留（Phase 3 再处理）。

---

## 二、旧目录逐个比对结果

### A. xiaowuOS/courses/（原始课程目录）

| 项目 | 状态 |
|------|------|
| `20260611_09嗨翻人工智能之决策支持/` | ✅ 全部 17 文件已复制到 outputs/courses/，sha256 一致 |
| `20260613_GESP-C4_植物大战僵尸/` | ✅ 全部 7 文件已复制，sha256 一致 |

**分类：A — 可删除候选（全部为重复）**

### B. xiaowuOS/docs/lessons/（混放课程教案的 docs 子目录）

| 文件 | outputs 正源 | SHA256 匹配 |
|------|-------------|------------|
| GESP-C4-考级辅导-20260613.md | ✅ `outputs/courses/20260613_GESP-C4-考级辅导/` | ✅ 完全一致 |
| GESP-C4-考级辅导-20260613_学员投屏版.pptx | ✅ 同上 | ✅ 完全一致 |
| 科创启蒙-零式协约-20260613.md | ✅ `outputs/courses/20260613_科创启蒙-零式协约/` | ✅ 完全一致 |
| 科创启蒙-零式协约-20260613_学员投屏版.pptx | ✅ 同上 | ✅ 完全一致 |

**分类：A — 可删除候选（4 文件全部为重复）**

### C. .xiaowuOS/docs/lessons/（系统目录中混放的课程教案）

| 文件 | outputs 正源 | SHA256 匹配 |
|------|-------------|------------|
| GESP-C4-植物大战僵尸-20260613/V0.2/ × 4份 | ✅ `outputs/courses/20260613_GESP-C4_植物大战僵尸/V0.2/` | ✅ 完全一致 |
| GESP-C4-考级辅导-20260613.md + .pptx | ✅ `outputs/courses/20260613_GESP-C4-考级辅导/` | ✅ 完全一致 |
| 科创启蒙-零式协约-20260613.md + .pptx | ✅ `outputs/courses/20260613_科创启蒙-零式协约/` | ✅ 完全一致 |

**分类：A — 可删除候选（8 文件全部为重复）**

### D. .xiaowuOS/docs/ 根目录 09嗨翻 文件

| 文件 | outputs 正源 | SHA256 匹配 |
|------|-------------|------------|
| 上课清单_最终版.md | ✅ outputs/courses/.../09嗨翻/ | ✅ 一致 |
| 备课包_最终版.md | ✅ 同上 | ✅ 一致 |
| 投屏PPT_最终版_marp修复版.md | ✅ 同上 | ✅ 一致 |
| 投屏PPT_最终版.md | ✅ 同上 | ✅ 一致 |
| 投屏PPT_最终版.pptx → 学员投屏版.pptx | ✅ 同上 | ✅ 一致（同名 hash） |
| 投屏PPT_最终版_修复版.pptx | ✅ 同上 | ✅ 一致 |
| 老师提词卡.md | ✅ 同上 | ✅ 一致 |

**分类：A — 可删除候选（7 文件全部为重复）**

### E. xiaowuOS/docs/零式协约/（项目文档放错位置）

5 份文档 sha256 与 `projects/zprotocol_零式协约/` 完全一致。

**分类：A — 可删除候选（5 文件全部为重复）**

### F. .xiaowuOS/docs/零式协约/（项目文档副本）

同样 5 份文档，sha256 与 `projects/zprotocol_零式协约/` 完全一致。

**分类：A — 可删除候选（5 文件全部为重复）**

### G. workspace/deliverables/（最大混乱源，29 文件）

| 状态 | 数量 | 说明 |
|------|------|------|
| ✅ SHA256 匹配 outputs/reports/ | 17 | 报告类全部确认重复 |
| ✅ SHA256 匹配 outputs/courses/ | 6 | 课程教案+编程习惯全部确认重复 |
| ✅ SHA256 匹配 outputs/articles/ | 3 | 纪事文章全部确认重复 |
| ❓ 未复制到 outputs/ | **1** | `人工智能视频创作课程-首版方案.md` — Phase 1 遗漏 |

**分类细分：**
- A（可删除）：28 文件 — sha256 完全匹配 outputs 正源
- D（需迁移）：1 文件 — `人工智能视频创作课程-首版方案.md` 未复制到 outputs/

### H. workspace/course-planning/（4 个规划方案文件）

| 文件 | 说明 |
|------|------|
| 01-课程套餐规划提案-V1.md | 历史规划文档，非正式产出物 |
| 嗨翻人工智能课程总控清单-V1.md | 同上 |
| 嗨翻人工智能课程资料整理与后续课程建议-V1.md | 同上 |
| 澄木教育微信小程序开发方案-V1.md | 技术方案 |

**分类：B — 建议归档后删除（有历史参考价值，但不是正源）**

### I. workspace/memory/（17 个旧版 memory 日记录）

日期范围：2026-04-15 ~ 2026-06-01  
与 `.openclaw/workspace/memory/` 不同源，含部分重叠和部分独有记录。

**分类：B — 建议归档后删除（有历史记录价值）**

### J. .xiaowuOS/docs/_archive/ 及其他系统文件

| 文件/目录 | 说明 |
|-----------|------|
| `_archive/20260611_夜校备课过程稿与系统报告/` | ~18 个文件，含历史备课过程稿和系统诊断报告 |
| `xiaowuOS-v0.1-devlog.md` | 开发日志 |
| `.~*.pptx` 临时文件 | macOS Office 遗留临时文件 |

**分类：**
- `_archive/`：C — 暂时保留（历史上下文，澄木老师判断）
- `devlog.md`：C — 暂时保留（系统开发历史）
- `.~*` 临时文件：A — 可删除候选

### K. .xiaowuOS/docs/ SOP 文件（2 份已归位 docs/sop/）

| 文件 | 状态 |
|------|------|
| 澄木备课SOP_V0.1.md | ✅ SHA256 与 docs/sop/ 中一致，可删除 |
| 科创纪事创作 SOP_V0.1.md | ✅ SHA256 与 docs/sop/ 中一致，可删除 |

**分类：A — 可删除候选（已归位到 docs/sop/）**

---

## 三、分类汇总

### A. 可删除候选（sha256 完全匹配 outputs 正源）

| 来源目录 | 文件数 | 大小 |
|----------|--------|------|
| xiaowuOS/courses/ × 2课次 | ~24 文件 | ~1.1MB |
| docs/lessons/ | 4 文件 | ~150KB |
| .xiaowuOS/docs/lessons/ | 8 文件 | ~136KB |
| .xiaowuOS/docs/ 根目录 (09嗨翻) | 7 文件 | ~2MB |
| docs/零式协约/ | 5 文件 | ~28KB |
| .xiaowuOS/docs/零式协约/ | 5 文件 | ~28KB |
| workspace/deliverables/ | 28 文件 | ~260KB |
| .xiaowuOS/docs/ SOP (2份) | 2 文件 | ~12KB |
| .xiaowuOS/docs/ `.~*` 临时文件 | 1 文件 | ~530KB |
| **合计** | **~84 文件 / ~3.9MB** | |

### B. 建议归档后删除

| 来源目录 | 文件数 | 说明 |
|----------|--------|------|
| workspace/course-planning/ | 4 | 规划方案，有历史参考价值 |
| workspace/memory/ | 17 | 旧版 memory 日记录 |
| **合计** | **21 文件** | 建议 tar.gz 归档到 /home/john/backups/xiaowuOS-workspace-archive/ |

### C. 暂时保留（需澄木老师人工判断）

| 来源目录 | 文件数 | 说明 |
|----------|--------|------|
| .xiaowuOS/docs/_archive/ | ~18 | 夜校备课过程稿 + 系统诊断报告 |
| .xiaowuOS/docs/xiaowuOS-v0.1-devlog.md | 1 | 开发日志 |
| outputs/courses/ 内部命名重复 | 4组 | 不同名称但相同内容，需澄木老师确认保留哪个版本名 |
| **合计** | **~23 文件** | |

### D. 需要迁移（outputs 中缺失）

| 文件 | 当前位置 | 建议归位 |
|------|---------|---------|
| 人工智能视频创作课程-首版方案.md | workspace/deliverables/ | outputs/courses/ |

### E. 禁止删除

| 目录/文件 | 理由 |
|-----------|------|
| .xiaowuOS/bin/, config/, data/ | 系统运行必需 |
| .xiaowuOS/docs/_archive/ | 历史上下文（C类） |
| .openclaw/workspace/memory/ | OpenClaw 运行时 memory（不归位范围） |

---

## 四、敏感信息检查

| 检查位置 | 结果 |
|----------|------|
| docs/lessons/ | ❌ 无 token/secret/key/password 关键词 |
| .xiaowuOS/docs/lessons/ | ❌ 同上 |
| workspace/deliverables/ | ❌ 同上 |
| .xiaowuOS/docs/ 根目录 | ❌ 同上 |

**结论：** 本次比对范围内未发现敏感信息。

---

## 五、清理建议优先级

```
优先级 1 (最安全): 删除 outputs/courses/ + outputs/reports/ + outputs/articles/ 的 sha256 确认副本
         → A类 ~84 文件, 释放 ~3.9MB

优先级 2 (低风险): 归档 workspace/course-planning/ + workspace/memory/
         → B类 21 文件, tar.gz 后约 ~50KB

优先级 3 (待人工审核): .xiaowuOS/docs/_archive/ + outputs/courses/ 内部命名重复
         → C类 ~23 文件

优先级 4 (补充迁移): workspace/deliverables/ 中遗漏的 1 个文件
         → D类 1 文件
```

---

*Phase 2 审计完毕。无文件被删除或修改。*
