# xiaowuOS 主备方案 — Phase 2：敏感配置加密备份设计

**日期:** 2026-06-15 10:23 (GMT+8)
**状态：** 设计方案（待澄木老师确认后执行）
**前置：** Phase 1 /home/john/xiaowuOS 普通目录同步已完成

---

## 一、Phase 1 完成记录

| 项目 | 状态 |
|------|------|
| SSH 三机互信 | ✅ macOS↔xiaowuOS、macOS↔xiaowuOSb、xiaowuOS↔xiaowuOSb |
| xiaowuOSb FRP 端口 | ✅ johnonlife.com:60024 |
| 备机目录创建 | ✅ ~/xiaowuOS_standby/xiaowuOS/ |
| rsync dry-run | ✅ Exit 0，总大小 6.5MB |
| 实际同步 | ✅ /home/john/xiaowuOS → 约 5.4MB |
| --delete 使用 | ❌ 未使用 |
| 敏感 JSON 混入检查 | ✅ 未发现明显泄露 |

---

## 二、敏感目录盘点（只读扫描结果）

### 2.1 /home/john/.openclaw/（总计 ~2GB，核心配置文件 ~46KB）

#### 🔴 高度敏感 — 必须加密

| 路径 | 内容类型 | 大小 | 风险 |
|------|---------|------|------|
| `openclaw.json` | Gateway 主配置：bot token、API keys、feishu appId/appSecret、channel 配置 | 8KB | 🔴 |
| `credentials/feishu-pairing.json` | 飞书配对请求记录 | 24K | 🔴 |
| `credentials/telegram-pairing.json` | Telegram 配对记录 | 24K | 🔴 |
| `credentials/*-allowFrom.json` (×3) | 各通道安全白名单 | <10K | 🟡 |
| `identity/device.json` | 设备标识 | 12K | 🟡 |
| `identity/device-auth.json` | 设备认证信息 | 12K | 🔴 |
| `state/*` | 运行状态 | 4.5MB | 🟡 |

#### ⚪ 可明文备份（无密钥/Token）

| 路径 | 内容类型 | 大小 |
|------|---------|------|
| `agents/main/` | Agent 配置、SOUL/AGENTS.md 等 | 189MB |
| `workspace/` | 工作区文档、memory | 1.3MB |
| `cron/`, `tasks/`, `flows/` | 定时任务定义 | <400K |
| `completions/` | 补全记录 | 952K |
| `plugin-skills/` | 技能插件配置 | 24K |
| `logs/` | 日志（可能含运行时信息） | 36K |

#### ❌ 排除备份（可重建，不需要）

| 路径 | 原因 |
|------|------|
| `npm/` | 1.4GB，可重新安装 |
| `tools/` | 292MB，可重新初始化 |
| `cache/` | 缓存，可随时重建 |
| `subagents/` | 运行时临时状态 |

### 2.2 /home/john/.xiaowuOS/（总计 ~180KB + PPTX）

#### 🔴 高度敏感 — 必须加密

| 路径 | 内容类型 | 风险 |
|------|---------|------|
| `.env` | HTTP_PROXY、GOOGLE_CLOUD_PROJECT、OPENCLAW_PROXY_URL | 🔴 |
| `feishu.env` | FEISHU_APP_ID、FEISHU_APP_SECRET、FEISHU_XIAOWU_FOLDER_TOKEN | 🔴 |
| `aizzz.env` | AIZZZ_BASE_URL、AIZZZ_MODEL、AIZZZ_API_KEY | 🔴 |
| `config/private/feishu-credentials.json` | app_id/app_secret/tenant_token | 🔴 |
| `config/private/openclaw-backup.json` | 完整 openclaw.json 备份副本（含 bot token） | 🔴 |
| `config/private/*-pairing.json` | 飞书/Telegram 配对记录 | 🔴 |

#### ⚪ 可明文备份

| 路径 | 内容类型 |
|------|---------|
| `docs/` | 课件、SOP、备课文档（含 PPTX） |
| `feishu_*.py`, `lesson_to_docx.py` | Python 脚本 |
| `config/models.yaml` | 模型定义（无密钥） |
| `config/xiaowu_agents_models.json` | Agent 模型映射（无密钥） |
| `bin/` | 启动脚本 |
| `data/`, `logs/` | 数据/日志 |

#### ❌ 排除备份

| 路径 | 原因 |
|------|------|
| `__pycache__/` | Python 缓存 |
| `backups/git/*.bundle` | Git bundle，约 40MB+，已有其他备份机制 |
| `*.bak-*` | 旧备份文件 |

---

## 三、加密备份方案设计

### 3.1 总体架构

```
xiaowuOS (主机)                          xiaowuOSb (备机)
┌─────────────────────┐           ┌──────────────────────────┐
│                     │    SSH   │                            │
│  🔒 encrypt + send  │ ──────→  │ ~/xiaowuOS_standby/       │
│                     │          │   secrets/*.gpg            │
└─────────────────────┘          │   config-openclaw/         │
                                 │   config-xiaowuOS/         │
                                 └──────────────────────────┘
```

**设计原则：**
1. 敏感文件单独打包 + GPG 对称加密（AES256）
2. 非敏感明文文件 rsync 直传
3. 密码不写在任何文件中，由澄木老师口头/记忆掌握
4. 备份频率暂定每日一次，通过 cron 调用
5. 不加 --delete，只追加不覆盖

### 3.2 备份清单（tar 打包结构）

#### secrets.tar.gpg（加密包）

```
secrets-YYYYMMDD.tar.gpg
├── .openclaw/openclaw.json
├── .openclaw/credentials/          (全部)
├── .openclaw/identity/device-auth.json
├── .xiaowuOS/.env
├── .xiaowuOS/feishu.env
├── .xiaowuOS/aizzz.env
├── .xiaowuOS/config/private/       (全部)
```

#### plaintext-sync（明文 rsync）

```
.openclaw/workspace/         →  ~/xiaowuOS_standby/openclaw-workspace/
.openclaw/agents/            →  ~/xiaowuOS_standby/openclaw-agents/
.openclaw/cron/, tasks/, flows/ → ~/xiaowuOS_standby/openclaw-cron-tasks/
.xiaowuOS/docs/              →  ~/xiaowuOS_standby/xiaowuos-docs/
.xiaowuOS/config/models.yaml →  ~/xiaowuOS_standby/xiaowuos-config/
.xiaowuOS/config/xiaowu_agents_models.json
.xiaowuOS/bin/, data/
```

### 3.3 加密工具选择：GPG 对称加密（无公钥基础设施）

**理由：**
- xiaowuOS ↔ xiaowuOSb 之间无需非对称加密
- GPG 对称加密 + AES256 已足够保护静态数据
- 密码由澄木老师掌握，不在任何文件中
- gpg 已在 Ubuntu/Debian 系统中预装

**命令示例（dry-run 阶段）：**

```bash
# 主机执行：打包敏感文件 + 加密
tar cf - \
  --transform='s|^/home/john||' \
  /home/john/.openclaw/openclaw.json \
  /home/john/.openclaw/credentials/ \
  /home/john/.openclaw/identity/device-auth.json \
  /home/john/.xiaowuOS/.env \
  /home/john/.xiaowuOS/feishu.env \
  /home/john/.xiaowuOS/aizzz.env \
  /home/john/.xiaowuOS/config/private/ \
| gpg --symmetric --cipher-algo AES256 --batch --yes \
  -o /tmp/secrets-$(date +%Y%m%d).tar.gpg

# 加密密码：由澄木老师手动输入（不写进脚本）

# 发送到备机
scp /tmp/secrets-$(date +%Y%m%d).tar.gpg xiaowuOSb:~/xiaowuOS_standby/secrets/

# 清理本地临时文件
rm -f /tmp/secrets-*.tar.gpg
```

### 3.4 解密恢复流程（备机端）

```bash
# 在备机上执行
cd ~/xiaowuOS_standby/secrets/
gpg --decrypt secrets-20260615.tar.gpg | tar xf -

# 解压后的目录结构与主机一致：
# .openclaw/openclaw.json
# .openclaw/credentials/...
# .xiaowuOS/.env
# etc.
```

### 3.5 自动化（Phase 3，当前不执行）

Phase 2 仅设计方案。Phase 3 才考虑：
- cron 定时备份
- gpg-agent + passphrase-file（需评估安全级别）
- 旧备份轮转策略（保留最近 N 天）

---

## 四、风险矩阵

| # | 风险 | 影响等级 | 缓解措施 |
|---|------|---------|---------|
| 1 | 密码遗忘 | 🔴 无法恢复加密备份 | 建议澄木老师记录在物理笔记本或 1Password 中 |
| 2 | GPG 未安装 | 🟡 备机可能无 gpg | 先检查备机环境，必要时 apt install gnupg |
| 3 | .env 文件权限被修改 | 🔴 其他用户可读 | 备份前确认 permissions (600/400) |
| 4 | 临时文件泄露 | 🟡 /tmp/secrets-*.gpg 可能被截获 | 加密后立即删除本地副本 |
| 5 | openclaw.json 未纳入 .xiaowuOS 同步 | 🟡 需单独处理 | 本方案已将其放入加密包 |

---

## 五、下一步行动（待澄木老师确认）

| # | 动作 | 状态 |
|---|------|------|
| 1 | 确认加密方案是否接受 | ⏳ 待确认 |
| 2 | 澄木老师设定 GPG 对称密码 | ⏳ 需手动操作 |
| 3 | Dry-run：本地打包+加密+发送测试（不解密） | ⏳ 确认后执行 |
| 4 | 验证：备机端解密恢复测试 | ⏳ 第 3 步通过后 |
| 5 | rsync 明文目录同步到备机 | ⏳ 独立并行 |
| 6 | Phase 3：自动化 cron + 轮转策略 | ⏳ Phase 2 完全通过后再考虑 |

---

## 六、文件清单汇总（便于澄木老师快速审查）

### 需要加密的文件（共 ~15KB 原始数据）

```
.home/john/.openclaw/openclaw.json               (8.2KB)  Gateway 主配置
/home/john/.openclaw/credentials/*                (~24K)  配对+权限
/home/john/.openclaw/identity/device-auth.json    (12K)   设备认证
/home/john/.xiaowuOS/.env                        (662B)   Proxy/API
/home/john/.xiaowuOS/feishu.env                  (217B)   飞书凭据
/home/john/.xiaowuOS/aizzz.env                   (122B)   AI 服务密钥
/home/john/.xiaowuOS/config/private/*             (~3K)   完整备份副本+配对
```

### 可明文同步的目录

```
.openclaw/workspace/           → 文档、memory、heartbeat
.openclaw/agents/main/         → Agent 配置、SOUL.md
.xiaowuOS/docs/               → 课件、SOP、PPT
.xiaowuOS/config/models.yaml   → 模型定义
```

### 排除项（可重建，不需要备份）

```
.openclaw/npm/                (1.4GB, 包管理缓存)
.openclaw/tools/              (292MB, 运行时工具)
.xiaowuOS/__pycache__/        (Python 字节码)
.xiaowuOS/backups/git/*.bundle (已有独立备份机制)
```

---

**报告结束 — Phase 2 设计方案**
待澄木老师确认后进入 Dry-Run 验证阶段。
