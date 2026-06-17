# xiaowuOS 目录优化审计报告

**生成时间：** 2026-06-13 05:18 (GMT+8)  
**审计范围：** courses/、docs/、workspace/、.xiaowuOS/docs/ 文件盘点 + outputs 迁移方案  
**操作者：** 小悟同学（只读审计）  
**免责声明：** 本报告只审计和生成 dry-run 脚本，不移动/删除/覆盖任何文件

---

## 一、当前目录混乱点

### 📊 全局概览

| 路径 | 大小 | 主要问题 |
|------|------|---------|
| `/home/john/xiaowuOS/courses/` | **1MB** | ✅ 定位基本正确，但只有 2 个课次目录，内容分散 |
| `/home/john/xiaowuOS/docs/` | **~270KB** | ❌ `docs/lessons/` 混放了正式 PPT 和教案（应为产出物） |
| `/home/john/xiaowuOS/workspace/` | **~490KB** | ❌ `deliverables/` 放了大量正式交付报告、`course-planning/` 放课程方案 |
| `/home/john/.xiaowuOS/docs/` | **~380KB** | ❌ 系统运行目录混放了正式 PPT、备课包、提词卡、零式协约文档 |
| `/home/john/xiaowuOS/docs/零式协约/` | **40KB** | ❌ 项目文档放在 docs/，应为 projects/ |

### 🔴 主要混乱点

#### 1. docs/lessons/ 混放正式课程产出物

```
xiaowuOS/docs/lessons/
├── GESP-C4-考级辅导-20260613.md          ← 正式教案（产出物）
├── GESP-C4-考级辅导-20260613_学员投屏版.pptx  ← 正式 PPT（产出物）
├── 科创启蒙-零式协约-20260613.md         ← 正式教案（产出物）
└── 科创启蒙-零式协约-20260613_学员投屏版.pptx  ← 正式 PPT（产出物）
```

#### 2. .xiaowuOS/docs/ 混放正式交付物

```
.xiaowuOS/docs/
├── 09嗨翻人工智能之决策支持_20260611_备课包_最终版.md       ← 正式交付物
├── 09嗨翻人工智能之决策支持_20260611_投屏PPT_最终版.pptx    ← 正式交付物
├── 09嗨翻人工智能之决策支持_20260611_老师提词卡.md          ← 正式交付物
├── lessons/ (同 docs/lessons/，含 PPT + 教案)             ← 重复产出物
├── 零式协约/ (5份项目文档)                                ← 应为 projects/
├── 澄木备课SOP_V0.1.md                                   ← SOP（归位 docs/sop/）
└── 科创纪事创作 SOP_V0.1.md                               ← SOP（归位 docs/sop/）
```

#### 3. workspace/deliverables/ 混放正式交付物

```
workspace/deliverables/ (276KB, 30+ 文件)
├── 人工智能视频创作课程-案例课-飞书版课件.md       ← 正式课件
├── 未来创客-六年级-编程习惯课-2026-05-24.md         ← 正式教案
├── 科创教育纪事001期-正式版.md                      ← 正式产出物
├── 澄木系统PRD-v0.1.md                              ← 正式文档
├── 编程习惯-01~04.md (4个)                         ← 正式教案素材
└── ... (26+ 其他交付报告)
```

#### 4. workspace/course-planning/ 混放课程规划方案

```
workspace/course-planning/ (36KB, 4 文件)
├── 01-课程套餐规划提案-V1.md
├── 嗨翻人工智能课程总控清单-V1.md
├── 嗨翻人工智能课程资料整理与后续课程建议-V1.md
└── 澄木教育微信小程序开发方案-V1.md
```

#### 5. docs/零式协约/ 项目文档放错位置

```
xiaowuOS/docs/零式协约/ (40KB, 5 文件)
├── 零式协约_项目背景_V0.1.md
├── 零式协约_组织结构_V0.1.md
├── 零式协约_队员简介与视频脚本_V0.1.md
├── 零式协约_赛车游戏项目拆解_V0.1.md
└── 零式协约_项目索引_V0.1.md
```

---

## 二、建议的新目录规范

### 📁 /home/john/xiaowuOS/outputs/ — 正式产出物总目录

```
outputs/                          ← 所有正式交付物的唯一出口
├── courses/                      ← 课程产出（教案、PPT、学生材料）
│   ├── 20260611_09嗨翻人工智能之决策支持/
│   ├── 20260613_GESP-C4-轩轩最后一波防守/
│   └── 20260613_科创启蒙-零式协约/
├── articles/                     ← 文章产出（公众号、纪事）
│   ├── 科创教育纪事001期-正式版.md
│   └── ...
├── slides/                       ← 独立幻灯片（非课程绑定）
├── reports/                      ← 报告类交付物
│   ├── 澄木系统PRD-v0.1.md
│   ├── dashboard-文案替换清单.md
│   └── ...
├── media/                        ← 图片、音频、视频素材
└── exports/                      ← 导出文件（飞书同步、PDF）
```

### 📁 /home/john/xiaowuOS/workspace/ — 临时工作区

```
workspace/                        ← 输入材料、中间稿、临时文件
├── inbox/                        ← 新素材入口
├── staging/                      ← 草稿/中间版本
│   ├── GESP-C4-轩轩_初稿.md
│   └── 课件制作中...
└── tmp/                          ← 一次性临时文件（课后清理）
```

### 📁 /home/john/xiaowuOS/docs/ — 系统文档与 SOP

```
docs/                             ← 只放系统级文档
├── sop/                          ← SOP（备课流程、创作规范）
│   ├── 澄木备课SOP_V0.1.md
│   ├── 科创纪事创作SOP_V0.1.md
│   └── 公众号文章创作SOP.md
├── system_audit/                 ← 审计报告（已有）
├── architecture/                 ← 架构说明
├── decisions/                    ← 决策记录
├── known-issues.md               ← 已知问题
├── openclaw-runbook.md           ← 运维手册
├── README.md                     ← 系统索引
└── feishu-*.md                   ← Feishu 集成文档（系统级）
```

### 📁 /home/john/xiaowuOS/projects/ — 长期项目

```
projects/                         ← 长期项目资料
└── zero-contract/                ← 零式协约项目
    ├── 项目背景_V0.1.md
    ├── 组织结构_V0.1.md
    ├── 队员简介与视频脚本_V0.1.md
    ├── 赛车游戏项目拆解_V0.1.md
    └── 项目索引_V0.1.md
```

### 📁 /home/john/.xiaowuOS/ — 系统运行数据（保持现状）

```
.xiaowuOS/                       ← 只放运行时文件，不放交付物
├── bin/                         ← wrapper 脚本
├── config/                      ← 系统配置
├── data/                        ← 运行数据
├── docs/_archive/               ← 历史归档（保留）
└── logs/                        ← 日志
```

---

## 三、courses/ 中发现的内容

| 文件/目录 | 类型 | 大小 | 当前状态 | 建议 |
|-----------|------|------|---------|------|
| `20260611_09嗨翻人工智能之决策支持/` | 正式课程产出物 | ~1MB | ✅ 位置基本正确 | 归位到 outputs/courses/ |
| `20260613_GESP-C4_植物大战僵尸/V0.2/` | 正式课程产出物 | ~36KB | ✅ 位置基本正确 | 归位到 outputs/courses/ |
| 各 PPT 文件 (.pptx) | 正式课件 | - | ✅ 在课程目录内 | 随课次一起归位 |
| 教师备课版.md / 学员投屏版.pptx | 正式教案 | - | ✅ 在课程目录内 | 随课次一起归位 |

**结论：** courses/ 本身定位正确，但需整体搬迁至 outputs/courses/。

---

## 四、docs/ 中发现的课程产出物（需移出的文件）

| 文件 | 类型 | 大小 | 建议去向 |
|------|------|------|---------|
| `docs/lessons/GESP-C4-考级辅导-20260613.md` | 正式教案 | ~8KB | outputs/courses/ |
| `docs/lessons/GESP-C4-考级辅导-20260613_学员投屏版.pptx` | 正式 PPT | ~90KB | outputs/courses/ |
| `docs/lessons/科创启蒙-零式协约-20260613.md` | 正式教案 | ~6KB | outputs/courses/ |
| `docs/lessons/科创启蒙-零式协约-20260613_学员投屏版.pptx` | 正式 PPT | ~50KB | outputs/courses/ |
| `docs/零式协约/*.md (5份)` | 项目文档 | ~40KB | projects/zero-contract/ |

**应保留在 docs/ 的文件：**
- README.md, migration-status.md, known-issues.md, openclaw-runbook.md ✅
- feishu-*.md（系统级集成文档）✅
- system_audit/*.md ✅
- api/, architecture/, deployment/, development/, examples/, integration/, troubleshooting/ ✅

---

## 五、workspace/ 中发现的产出物（需移出的文件）

| 目录 | 文件数 | 大小 | 内容类型 | 建议去向 |
|------|--------|------|---------|---------|
| `workspace/deliverables/` | 30+ | ~276KB | 课程课件、编程教案、纪事文章、PRD报告 | outputs/courses/ + outputs/articles/ + outputs/reports/ |
| `workspace/course-planning/` | 4 | ~36KB | 课程套餐规划、总控清单 | workspace/staging/（规划类为中间稿） |

### deliverables/ 详细分类

**→ outputs/courses/（正式课件+教案）：**
- 人工智能视频创作课程-案例课-飞书版课件.md
- 未来创客-六年级-编程习惯课-2026-05-24.md
- 编程习惯-01~04.md (4个)

**→ outputs/articles/（文章产出）：**
- 科创教育纪事001期-正式版.md
- 澄木日课-2026-05-26.md

**→ outputs/reports/（报告类交付物）：**
- 澄木系统PRD-v0.1.md
- 澄木系统-定义-2026-05-26.md
- dashboard-文案替换清单.md
- OpenClaw-cron-诊断.md
- johnonlife.com-小悟同学部署SOP.md
- 及其他 ~20 份运营/技术报告

---

## 六、.xiaowuOS/docs/ 中发现的正式交付物

| 文件 | 类型 | 大小 | 建议去向 |
|------|------|------|---------|
| `09嗨翻人工智能之决策支持_20260611_备课包_最终版.md` | 正式教案 | - | outputs/courses/ |
| `09嗨翻人工智能之决策支持_20260611_投屏PPT_最终版.pptx` | 正式 PPT | - | outputs/courses/ |
| `09嗨翻人工智能之决策支持_20260611_投屏PPT_最终版_修复版.pptx` | 正式 PPT（最新版） | - | outputs/courses/ |
| `09嗨翻人工智能之决策支持_20260611_老师提词卡.md` | 正式教案 | - | outputs/courses/ |
| `09嗨翻人工智能之决策支持_20260611_上课清单_最终版.md` | 正式教案 | - | outputs/courses/ |
| `lessons/GESP-C4-植物大战僵尸-20260613/V0.2/*` (4份) | 重复文件 | ~36KB | ⚠️ 已在 courses/ 存在，可删除副本 |
| `lessons/GESP-C4-考级辅导-20260613.*` (2份) | 重复文件 | ~100KB | ⚠️ 已在 docs/lessons/ 存在，可删除副本 |
| `lessons/科创启蒙-零式协约-20260613.*` (2份) | 重复文件 | ~56KB | ⚠️ 已在 docs/lessons/ 存在，可删除副本 |
| `零式协约/*.md (5份)` | 项目文档 | ~40KB | projects/zero-contract/（与 docs/零式协约/ 重复） |
| `澄木备课SOP_V0.1.md` | SOP | - | docs/sop/ |
| `科创纪事创作 SOP_V0.1.md` | SOP | - | docs/sop/ |

---

## 七、建议归位到 outputs/courses/ 的文件清单

### 来源：xiaowuOS/courses/（整体搬迁）

```
rsync -av --ignore-existing xiaowuOS/courses/20260611_09嗨翻人工智能之决策支持/ outputs/courses/20260611_09嗨翻人工智能之决策支持/
rsync -av --ignore-existing xiaowuOS/courses/20260613_GESP-C4_植物大战僵尸/ outputs/courses/20260613_GESP-C4-轩轩最后一波防守/
```

### 来源：xiaowuOS/docs/lessons/（需移出 docs）

```
rsync -av --ignore-existing xiaowuOS/docs/lessons/GESP-C4-考级辅导-20260613* outputs/courses/20260613_GESP-C4-考级辅导/
rsync -av --ignore-existing xiaowuOS/docs/lessons/科创启蒙-零式协约-20260613* outputs/courses/20260613_科创启蒙-零式协约/
```

### 来源：.xiaowuOS/docs/（非课程 PPT/教案部分）

```
rsync -av --ignore-existing .xiaowuOS/docs/09嗨翻人工智能之决策支持_20260611_* outputs/courses/20260611_09嗨翻人工智能之决策支持/
```

### 来源：workspace/deliverables/（课程相关）

```
rsync -av --ignore-existing workspace/deliverables/人工智能视频创作课程-案例课-飞书版课件.md outputs/courses/
rsync -av --ignore-existing workspace/deliverables/未来创客-六年级-编程习惯课-2026-05-24.md outputs/courses/
for i in 01 02 03 04; do rsync -av --ignore-existing workspace/deliverables/编程习惯-${i}*.md outputs/courses/编程习惯/; done
```

---

## 八、建议归位到其他 outputs/ 子目录的文件清单

### outputs/articles/

```
rsync -av --ignore-existing workspace/deliverables/科创教育纪事001期-正式版.md outputs/articles/
rsync -av --ignore-existing workspace/deliverables/澄木日课-2026-05-26.md outputs/articles/
```

### outputs/reports/

```
rsync -av --ignore-existing workspace/deliverables/澄木系统PRD-v0.1.md outputs/reports/
rsync -av --ignore-existing workspace/deliverables/澄木系统-定义-2026-05-26.md outputs/reports/
rsync -av --ignore-existing workspace/deliverables/dashboard-文案替换清单*.md outputs/reports/
rsync -av --ignore-existing workspace/deliverables/OpenClaw-cron-诊断*.md outputs/reports/
rsync -av --ignore-existing workspace/deliverables/johnonlife.com-小悟同学部署SOP*.md outputs/reports/
# ... 其余 deliverables/ 中的运营/技术报告
```

### projects/zero-contract/（从 docs/零式协约/）

```
rsync -av --ignore-existing xiaowuOS/docs/零式协约/ projects/zero-contract/
```

---

## 九、暂不处理文件清单

| 路径 | 理由 |
|------|------|
| `xiaowuOS/docs/feishu-*.md` (6份) | Feishu 集成文档，系统级，保留在 docs/ |
| `xiaowuOS/docs/{api,architecture,deployment,...}/` (7个子目录) | 空目录/脚手架，保留 |
| `.xiaowuOS/docs/_archive/20260611_夜校备课过程稿与系统报告/` | 历史归档，有参考价值 |
| `workspace/memory/` (~92KB) | 旧 memory 日记录，迁移中暂保留 |
| `workspace/state/` (~48KB) | 旧状态数据，迁移中暂保留 |
| `.xiaowuOS/docs/lessons/GESP-C4-植物大战僵尸-20260613/V0.2/*` | 重复文件，需人工确认哪个是正源 |
| `.openclaw/workspace/memory/*.md` (~30份) | OpenClaw 运行时 memory，不归位 |

---

## 十、是否发现重复文件？

### ✅ 是，发现以下重复：

| 文件名 | 位置 A | 位置 B | 说明 |
|--------|--------|--------|------|
| GESP-C4 V0.2 × 4份 | `courses/20260613_GESP-C4_植物大战僵尸/V0.2/` | `.xiaowuOS/docs/lessons/GESP-C4-植物大战僵尸-20260613/V0.2/` | **完全重复**，内容一致 |
| GESP-C4 考级辅导教案+PPT | `docs/lessons/` | `.xiaowuOS/docs/lessons/` | **完全重复** |
| 科创启蒙教案+PPT | `docs/lessons/` | `.xiaowuOS/docs/lessons/` | **完全重复** |
| 零式协约文档 × 5份 | `docs/零式协约/` | `.xiaowuOS/docs/零式协约/` | **完全重复** |

### 去重建议

以 **outputs/courses/** 为正源，迁移完成后删除其他副本：
- `.xiaowuOS/docs/lessons/` 整个目录可清理（全部为副本）
- `docs/lessons/` 整个目录可清理（搬迁至 outputs/courses/后为空）
- `.xiaowuOS/docs/零式协约/` 可清理（搬迁至 projects/后）

---

## 十一、是否发现唯一文件？

### ✅ 是，以下文件仅在单处存在：

| 文件 | 位置 | 说明 |
|------|------|------|
| workspace/deliverables/ (30+ 文件) | `workspace/deliverables/` | **唯一副本**，正式交付物放错了位置 |
| workspace/course-planning/ (4 文件) | `workspace/course-planning/` | **唯一副本**，课程规划方案 |
| .xiaowuOS/docs/09嗨翻_20260611_* (5 个非 lessons/ 文件) | `.xiaowuOS/docs/` | **唯一副本**，正式 PPT + 教案 + 提词卡 |
| workspace/memory/ (~30 日记录) | `workspace/memory/` | **唯一旧版 memory**，与 .openclaw/workspace/memory/ 不同 |

---

## 十二、是否需要澄木老师手动处理？

### ✅ 是，以下需人工决策：

1. **workspace/deliverables/ (276KB)** — 30+ 份报告/教案/纪事，量大且分散，建议澄木老师逐类审核归属
2. **.xiaowuOS/docs/_archive/** — 夜校备课过程稿，是否迁移至 outputs/courses/*/_archive/ 或保留原位？
3. **workspace/memory/** — 旧版 memory 日记录（4月~6月），与 .openclaw/workspace/memory/ 不同源，是否合并或归档？
4. **正源确认** — GESP-C4 V0.2、零式协约文档等重复文件的正源是哪个位置？

---

## 审计总结

| # | 问题 | 结论 |
|---|------|------|
| 1 | 是否建议采用 outputs 作为统一产出物目录 | ✅ **强烈建议** — 可彻底解决 courses/docs/workspace 混放问题 |
| 2 | 是否发现 docs 中混放课程产出物 | ✅ **是** — `docs/lessons/` (4份 PPT+教案)、`docs/零式协约/` (5份项目文档) |
| 3 | 是否发现 workspace 中混放正式产出物 | ✅ **是** — `workspace/deliverables/` (276KB, 30+ 文件)、`workspace/course-planning/` (4 文件) |
| 4 | 是否发现 .xiaowuOS 中混放正式交付物 | ✅ **是** — `.xiaowuOS/docs/` 含 PPT、备课包、提词卡、零式协约文档，且 lessons/ 下与 docs/lessons/ 完全重复 |
| 5 | 建议新增目录 | `outputs/{courses,articles,slides,reports,media,exports}/`、`workspace/{inbox,staging,tmp}/`、`docs/{sop,decisions}/`、`projects/zero-contract/` |
| 6 | 哪些内容建议归位到 outputs/courses | courses/全部内容、docs/lessons/全部内容、.xiaowuOS/docs/09嗨翻_*、workspace/deliverables/中课程相关文件 |
| 7 | dry-run 脚本路径 | `xiaowuOS/docs/system_audit/xiaowuOS_outputs_migration_dry_run.sh` |
| 8 | 审计报告路径 | `xiaowuOS/docs/system_audit/xiaowuOS_directory_optimization_20260613_051800.md` |
| 9 | 是否需要澄木老师手动处理 | ✅ **是** — deliverables/分类审核、正源确认、workspace/memory/归并决策 |

---

*报告完毕。本报告未修改、移动或删除任何文件。*
