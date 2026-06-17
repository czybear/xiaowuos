# xiaowuOS macOS 迁移审计报告

**生成时间：** 2026-06-13 04:56 (GMT+8)  
**审计范围：** WSL2 主系统 + 内嵌 macOS 备份快照  
**操作者：** 小悟同学（自动审计）  
**免责声明：** 本报告只审计，不删除/移动/修改/重启任何文件

---

## 一、当前主系统健康状态

| 检查项 | 状态 | 说明 |
|--------|------|------|
| OpenClaw Gateway | ✅ 正常 | pid 13608, active, v2026.6.1, loopback:18789 |
| Dashboard 网页 | ✅ 正常 | HTTP 200 |
| Telegram 连接 | ✅ 正常 | 用户 8726424800, allowFrom 配置正确 |
| Cron 调度 | ✅ 正常 | 2 个 cron job 运行中（巡检轮询 + daily-calendar-check） |
| Memory 索引 | ✅ 正常 | main.sqlite 可用 |
| 模型配置 | ✅ 正常 | Cloud First 策略生效，6 个模型注册 |
| 敏感任务路由 | ⚠️ 需注意 | openclaw.json 无独立 routing 段落，依赖默认策略 |
| /xiaowuOS/courses | ✅ 就绪 | 20260611 + 20260613 GESP C4 |
| /xiaowuOS/projects | ❌ 不存在 | 未创建，当前无项目级工作流 |
| /xiaowuOS/assets | ❌ 不存在 | 公共素材目录为空/未建 |
| /xiaowuOS/config | ✅ 就绪 | feishu + telegram + models.yaml |
| /xiaowuOS/docs | ✅ 就绪 | 完整文档体系 |
| /xiaowuOS/status | ✅ 就绪 | tasks.json + dashboard.md |
| /xiaowuOS/scripts | ✅ 就绪 | 启停脚本 |

### ⚠️ 注意事项
- `openclaw doctor` 建议运行：service PATH 包含 nvm/包管理器，建议最小化
- plugin install index 有 SQLite 冲突提示（openclaw-weixin），不影响运行
- `.openclaw/npm` 占用 **1.4GB**，是最大目录

---

## 二、macOS 旧版本发现情况

### 📍 macOS 路径访问性

**当前环境：** Linux WSL2（6.18.33.1-microsoft-standard-WSL2）  
**直接访问 /Users/john/*：** ❌ 不可用，当前主机为 WSL2，非 macOS

### 📦 内嵌 macOS 备份快照

在 `/home/john/xiaowuOS/macos-openclaw-backup/` 发现完整 macOS OpenClaw 状态副本：

| 目录 | 大小 | 内容说明 |
|------|------|----------|
| workspace/ | **6.0GB** | 最大块，含 mirrors(5.6G)、outputs(49M)、lesson-prep、software-digest |
| backups/ | **1.9GB** | 嵌套备份（2026-06-01 快照 + git objects） |
| agents/ | **849MB** | crestodian, hermes, main agent 会话数据 |
| npm/ | **447MB** | node_modules 缓存 |
| browser/ | **64MB** | Playwright user data |
| tmp/ | **48MB** | JIT 编译缓存、playwright artifacts |
| memory/ | **26MB** | hermes.sqlite + main.sqlite |
| media/ | **18MB** | inbound/outbound/tool-image-generation |
| logs/ | **3.9MB** | 运行日志 |
| credentials/ | **24KB** | telegram/feishu pairing & allowFrom |
| service-env/ | **12KB** | .env（含 Google Cloud 项目 ID） |
| 其他小目录 | <1MB | cron, plugins, flows, nodes, config 等 |

**macOS 备份总计：约 9.3GB**

---

## 三、迁移完成度判断

### ✅ 已确认迁移到位

| 资产 | macOS 旧版 | 当前主系统 | 状态 |
|------|-----------|-----------|------|
| OpenClaw 核心配置 | ✅ | ✅ openclaw.json | ✅ 已迁移 |
| Telegram 配置 | ✅ allowFrom+pairing | ✅ credentials/ | ✅ 已迁移 |
| Feishu 配置 | ✅ pairing+allowFrom | ✅ .openclaw/credentials + xiaowuOS/config/feishu | ✅ 已迁移 |
| 课程资料 | ✅ courses 旧版 | ✅ xiaowuOS/courses/（含 6/13 GESP C4） | ✅ 已迁移+更新 |
| 系统文档 | ✅ docs 旧版 | ✅ xiaowuOS/docs/ + .xiaowuOS/docs/ | ✅ 已迁移+扩展 |
| 项目索引 | ✅ 部分文档 | ⚠️ projects 目录未建 | ⚠️ 待创建 |
| Memory 数据 | ✅ main.sqlite + daily files | ✅ workspace/memory/（29 日记录） | ✅ 已迁移+持续更新 |
| Workspace 核心文件 | ✅ AGENTS.md, SOUL.md, IDENTITY.md, USER.md, TOOLS.md | ✅ .openclaw/workspace/ | ✅ 已迁移 |
| Cron 配置 | ❌ 旧 cron | ✅ 2 jobs 运行中 | ✅ 已重建 |
| Model 路由配置 | ❌ 旧版无 | ✅ models.yaml (Cloud First) | ✅ 新创建 |

### ❌ 未迁移/仅存于 macOS 备份的内容

| 资产 | 位置 | 风险 |
|------|------|------|
| mirrors/dashima.net（5.6GB） | macOS backup workspace/mirrors/ | 镜像站点数据，可能为唯一副本 |
| outputs/（49MB） | macOS backup workspace/outputs/ | Lesson7 AI 最终版、jimeng 下载等图片资产 |
| software-digest/（8.3MB） | macOS backup workspace/software-digest/ | C++ 项目源码 |
| wechat-mini-program/ | macOS backup workspace/wechat-mini-program/ | 微信小程序 server/server-cpp |
| lesson-prep/（172KB） | macOS backup workspace/lesson-prep/ | client/public/server/tests |
| agents/hermes + crestodian | macOS backup agents/ | 旧 agent 会话数据，可能含历史对话 |
| Google Cloud Project ID（env） | macOS backup service-env/ | gen-lang-client-0753914132，需确认主系统是否已配置 |

---

## 四、目录大小统计

### 主系统

| 路径 | 大小 |
|------|------|
| /home/john/xiaowuOS/ | **9.3GB**（其中 macOS backup = 9.3GB） |
| /home/john/xiaowuOS/macos-openclaw-backup/ | **9.3GB** ← 主要空间占用源 |
| /home/john/.openclaw/ | **1.8GB**（npm=1.4G, tools=292M, agents=153M） |
| /home/john/.xiaowuOS/ | **2.7MB** |
| 系统磁盘总计 | 1007GB，已用 21GB（2%），可用 935GB |

### macOS 备份明细（降序）

| 目录 | 大小 | 可释放潜力 |
|------|------|-----------|
| workspace/mirrors/ | **5.6GB** | 高（镜像数据，大概率可删） |
| backups/ | **1.9GB** | 高（嵌套旧备份，主系统已有更新版本） |
| agents/ | **849MB** | 中（agent sessions，历史对话） |
| npm/node_modules/ | **447MB** | 高（npm 缓存，可重新安装） |
| browser/user-data/ | **64MB** | 高（Playwright profile，可重建） |
| tmp/ | **48MB** | 高（编译缓存+artifacts，可清理） |
| memory/ | **26MB** | 中（SQLite 旧索引，主系统已有新版） |
| workspace/outputs/ | **49MB** | 低-中（图片资产，需人工确认） |
| workspace/software-digest/ | **8.3MB** | 低（源码项目，有保留价值） |
| media/ | **18MB** | 中（AI 生成图+收发媒体，可清理） |

---

## 五、删除风险分级

### A. 可以直接删除 ✅

| 目录 | 大小 | 理由 |
|------|------|------|
| `macos-openclaw-backup/backups/` | **1.9GB** | 嵌套旧备份，主系统已完整运行 |
| `macos-openclaw-backup/npm/` | **447MB** | npm 缓存，OpenClaw CLI 已安装在本机 |
| `macos-openclaw-backup/tmp/` | **48MB** | JIT 编译缓存 + playwright artifacts，无保留价值 |
| `macos-openclaw-backup/browser/` | **64MB** | Playwright user-data profile，可重建 |
| `macos-openclaw-backups/subagents/` | **100KB** | 旧 agent run 状态数据 |
| `macos-openclaw-backup/delivery-queue/` | **124KB** | 已完成投递队列 |
| `macos-openclaw-backup/run/` + `locks/` | **20KB** | 运行时临时文件 |

**A 类可释放：约 2.5GB**

### B. 建议压缩备份后删除 ⚠️

| 目录 | 大小 | 理由 |
|------|------|------|
| `macos-openclaw-backup/workspace/mirrors/` | **5.6GB** | 镜像站点数据，可能未来查阅，建议 tar.gz 存档 |
| `macos-openclaw-backup/workspace/outputs/` | **49MB** | Lesson7 AI 图片资产，有纪念价值 |
| `macos-openclaw-backup/media/` | **18MB** | AI 生成图 + inbound/outbound 媒体 |
| `macos-openclaw-backup/logs/` | **3.9MB** | 运行日志，可归档后删除 |

**B 类可释放：约 5.7GB（压缩后可达 ~1-2GB）**

### C. 暂时保留 📌

| 目录 | 大小 | 理由 |
|------|------|------|
| `macos-openclaw-backup/workspace/software-digest/` | **8.3MB** | C++ 源码项目，有开发价值但未迁移 |
| `macos-openclaw-backup/workspace/wechat-mini-program/` | <1MB | 小程序服务端代码，未来可能复用 |
| `macos-openclaw-backup/workspace/lesson-prep/` | **172KB** | 旧备课项目结构，可参考 |
| `macos-openclaw-backup/agents/` | **849MB** | Agent 会话数据（hermes/sqlite），可能含历史上下文 |
| `macos-openclaw-backup/memory/` | **26MB** | 旧 memory SQLite，主系统已更新但需确认无遗漏 |

**C 类保留：约 1GB**

### D. 禁止删除 🚫

| 目录/文件 | 大小 | 理由 |
|------|------|------|
| `macos-openclaw-backup/service-env/` | **12KB** | 含 Google Cloud Project ID、NODE 环境变量等，可能为主系统未记录配置 |
| `macos-openclaw-backup/credentials/` | **24KB** | Telegram/Feishu pairing & allowFrom，删除后无法恢复旧 pairing |
| `macos-openclaw-backup/agents/main/agent/` | <1MB | 主 agent 配置数据（虽然主系统有新版，但以防万一） |
| `macos-openclaw-backup/workspace/knowledge/软件纪事/` | <1MB | 知识库内容，未确认已迁移 |

**D 类保留：<50KB（极小，安全第一）**

---

## 六、是否发现 macOS 上的唯一文件？

### ✅ 是，发现以下仅存于 macOS 备份的内容：

| 文件/目录 | 大小 | 说明 |
|-----------|------|------|
| `workspace/mirrors/dashima.net/` | ~5.6GB | 镜像站点数据，主系统无此内容 |
| `workspace/software-digest/` | 8.3MB | C++ 项目源码（CMakeLists + src + tests） |
| `workspace/wechat-mini-program/` | <1MB | 微信小程序服务端代码 |
| `workspace/outputs/lesson7-*` | ~40MB | Lesson7 AI 最终版图片/PDF，多种版本 |
| `agents/hermes/*.sqlite` | <100MB | Hermes agent 会话数据库 |
| `service-env/ai.openclaw.gateway.env` | 12KB | Google Cloud Project ID + 旧 macOS PATH |

---

## 七、是否发现未迁移配置？

### ✅ 是，以下配置仅存于 macOS 备份：

| 配置项 | 位置 | 说明 |
|--------|------|------|
| Google Cloud Project ID | `service-env/ai.openclaw.gateway.env` | `gen-lang-client-0753914132`，主系统 `.env` 仅有 proxy 设置，无此字段 |
| OpenClaw 微信 bot tokens | `openclaw-weixin/accounts/*.context-tokens.json` | 微信账号上下文 token（但当前插件已启用） |

**建议：** 在删除前确认 Google Cloud Project ID 是否需要保留在主系统 `.env` 中。

---

## 八、是否发现敏感信息？

### ✅ 是，macOS 备份包含以下敏感数据：

| 类型 | 位置 | 风险等级 |
|------|------|---------|
| 飞书 App Secret | `openclaw-weixin/accounts/*.context-tokens.json` | 🔴 高 |
| 微信 bot tokens | `openclaw-weixin/accounts/dab7f2eb8dbc-im-bot.context-tokens.json` | 🔴 高 |
| Gateway Token（旧） | `service-env/ai.openclaw.gateway.env` | 🟡 中 |
| Telegram pairing（旧） | `credentials/telegram-pairing.json` | 🟡 中 |
| Google Cloud Project ID | `service-env/ai.openclaw.gateway.env` | 🟡 中 |

**安全建议：** 如删除 macOS 备份，请确保上述敏感配置已正确迁移至主系统。

---

## 九、预计可释放空间

| 类别 | 目录 | 大小 | 操作方式 |
|------|------|------|---------|
| A（直接删） | backups/, npm/, tmp/, browser/, subagents/, delivery-queue/, run/, locks/ | **~2.5GB** | rm -rf |
| B（压缩后删） | workspace/mirrors/, outputs/, media/, logs/ | **~5.7GB** → 压缩后 ~1-2GB | tar.gz 存档后删除 |
| C（保留） | software-digest, wechat-mini-program, lesson-prep, agents, memory | **~1GB** | 暂不动 |
| D（禁止删） | service-env, credentials, knowledge, main agent config | **<50KB** | 绝对不删 |

### 📊 总计预计释放

- **保守方案（仅删 A 类）：** ~2.5GB
- **推荐方案（A + B 压缩后）：** ~4-7GB
- **激进方案（全删 macOS backup）：** ~9.3GB ❌ 不推荐，有未迁移资产+敏感信息

---

## 十、建议释放空间的安全步骤

```
步骤 1: 提取 Google Cloud Project ID
  → cat service-env/ai.openclaw.gateway.env | grep GOOGLE_CLOUD_PROJECT
  → 如需保留，追加到 /home/john/.xiaowuOS/.env

步骤 2: 确认微信 bot tokens 是否已同步
  → 对比 openclaw-weixin/accounts/ 与主系统 plugins 状态
  → 当前 openclaw-weixin 插件已启用，tokens 应由 OpenClaw 自动管理

步骤 3: 删除 A 类目录（无风险）
  → backups/, npm/, tmp/, browser/, subagents/, delivery-queue/, run/, locks/

步骤 4: 压缩 B 类目录后删除
  → tar czf mirrors_archive.tar.gz workspace/mirrors/
  → tar czf media_outputs_archive.tar.gz workspace/outputs/ media/ logs/
  → 将 .tar.gz 移至 /home/john/backups/xiaowuOS-macos-legacy/（可选）

步骤 5: 保留 C + D 类目录
  → software-digest, wechat-mini-program, lesson-prep, agents, memory
  → service-env, credentials, knowledge, main agent config

步骤 6: 验证主系统运行正常
  → openclaw status
  → openclaw gateway status
  → 确认 cron + Telegram + Memory 正常
```

---

## 十一、dry-run 清理脚本位置

`/home/john/xiaowuOS/docs/system_audit/macos_cleanup_dry_run.sh`

（已在下一步生成）

---

## 审计总结

| 项目 | 结论 |
|------|------|
| **主系统健康** | ✅ 运行正常，Gateway/Cron/Memory/Telegram 全部可用 |
| **macOS 迁移完成度** | ⚠️ ~70%，核心功能已迁移，但部分资产仅存于 macOS 备份 |
| **唯一文件存在** | ✅ 是（mirrors 5.6GB, software-digest, wechat-mini-program） |
| **未迁移配置** | ✅ 是（Google Cloud Project ID） |
| **敏感信息** | ✅ 是（微信 bot tokens, 旧 gateway token, 飞书 secret） |
| **可直接删除** | A 类 ~2.5GB（backups/npm/tmp/browser/等） |
| **建议备份后删除** | B 类 ~5.7GB（mirrors/outputs/media/logs，压缩后 ~1-2GB） |
| **暂时不能删除** | C+D 类 ~1GB（agents/software-digest/credentials/service-env 等） |
| **预计可安全释放** | **3-6GB**（取决于 B 类是否压缩保留） |
| **需要澄木老师手动处理** | ✅ 是（确认 Google Cloud ID、审核 B 类是否需保留） |

---

*报告完毕。本审计未修改、删除或移动任何文件。*
