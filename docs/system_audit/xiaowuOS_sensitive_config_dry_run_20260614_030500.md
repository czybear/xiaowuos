# xiaowuOS 敏感配置边界治理 — dry-run 报告

**生成时间：** 2026-06-14 03:05 (GMT+8)  
**阶段：** Phase 2.5 只读审计 + dry-run 方案  
**操作者：** 小悟同学（不删除、不移动、不覆盖）

---

## 一、高风险文件清单

| # | 文件名 | 大小 | 权限 | 敏感关键词匹配 | 风险等级 |
|---|--------|------|------|---------------|---------|
| 1 | feishu-credentials.json | 348B | 664 | token:2, secret:1 | 🔴 高 — 飞书 API 凭证 |
| 2 | openclaw-backup.json | 2842B | 600 | token:3, key:1, secret:1 | 🔴 高 — OpenClaw 备份配置含 Token |

**注意：** feishu-credentials.json 权限为 664（world-readable），建议立即 chmod 600。

---

## 二、低风险文件清单

| # | 文件名 | 大小 | 权限 | 敏感关键词匹配 | 风险等级 |
|---|--------|------|------|---------------|---------|
| 3 | feishu-pairing.json | 37B | 600 | 无匹配 | 🟢 低 — 仅配对信息，建议保护但非高危 |

---

## 三、Git 跟踪状态

**当前状态：⚠️ 3个文件全部已被 Git 跟踪**

```
git ls-files 确认结果：
  ✅ config/feishu-credentials.json    — tracked (commit: 87001e5 Initial commit)
  ✅ config/openclaw-backup.json       — tracked (commit: 87001e5 Initial commit)
  ✅ config/feishu-pairing.json        — tracked (commit: 87001e5 Initial commit)

git status: nothing to commit, working tree clean
```

**这意味着：** 凭据信息已在 Git 历史记录中。即使后续 .gitignore 添加规则或文件移动，历史 commit 仍包含这些数据。

---

## 四、.gitignore 覆盖状态

**当前 .gitignore 内容：**

```
.env
token
secret
credentials
logs
node_modules
macos-openclaw-backup
```

| 检查项 | 状态 |
|--------|------|
| 是否排除 config/ 目录 | ❌ **否** — 无 `config/` 规则 |
| 是否排除 *.json 文件 | ❌ **否** — 无 `*.json` 规则 |
| 现有规则 "token" | ⚠️ 仅匹配文件名包含 "token" 的文件，不匹配 config/*.json |
| 现有规则 "credentials" | ⚠️ 仅匹配名为 "credentials" 的文件，不匹配 "feishu-credentials.json" |

**结论：.gitignore 未有效排除这些敏感文件**

---

## 五、建议迁移方案（dry-run）

### 目标目录
```
/home/john/.xiaowuOS/config/private/
```

此路径位于 .xiaowuOS/ 内部系统目录下，天然不在 Git 仓库中。

### dry-run 执行顺序

```bash
##############################################################################
# xiaowuOS 敏感配置迁移 dry-run
# ⚠️ 所有 mv/rm 均已注释，仅 echo 预览
##############################################################################

echo "=== Step 1: 创建目标目录 ==="
echo "mkdir -p /home/john/.xiaowuOS/config/private/"
#mkdir -p /home/john/.xiaowuOS/config/private/

echo ""
echo "=== Step 2: 收紧当前文件权限 ==="
echo "chmod 600 /home/john/xiaowuOS/config/feishu-credentials.json  (当前664→600)"
#chmod 600 /home/john/xiaowuOS/config/feishu-credentials.json

echo ""
echo "=== Step 3: 迁移高风险文件 ==="
echo "mv /home/john/xiaowuOS/config/feishu-credentials.json → .xiaowuOS/config/private/"
#mv /home/john/xiaowuOS/config/feishu-credentials.json /home/john/.xiaowuOS/config/private/

echo "mv /home/john/xiaowuOS/config/openclaw-backup.json → .xiaowuOS/config/private/"
#mv /home/john/xiaowuOS/config/openclaw-backup.json /home/john/.xiaowuOS/config/private/

echo ""
echo "=== Step 4: 迁移低风险文件 ==="
echo "mv /home/john/xiaowuOS/config/feishu-pairing.json → .xiaowuOS/config/private/"
#mv /home/john/xiaowuOS/config/feishu-pairing.json /home/john/.xiaowuOS/config/private/

echo ""
echo "=== Step 5: 在 Git 中移除引用（文件保留在新位置） ==="
echo "cd /home/john/xiaowuOS && git rm --cached config/feishu-credentials.json"
#git rm --cached config/feishu-credentials.json
echo "cd /home/john/xiaowuOS && git rm --cached config/openclaw-backup.json"
#git rm --cached config/openclaw-backup.json
echo "cd /home/john/xiaowuOS && git rm --cached config/feishu-pairing.json"
#git rm --cached config/feishu-pairing.json

echo ""
echo "=== Step 6: 补充 .gitignore ==="
echo '添加以下规则到 /home/john/xiaowuOS/.gitignore：'
echo "config/*.json"
echo "config/private/"

echo ""
echo "=== Step 7: 生成脱敏示例文件（替换原位置） ==="
echo "在 config/ 中创建 .placeholder 示例文件，保持目录结构但含零凭据"
```

---

## 六、建议保留的脱敏示例文件

迁移后，在 `/home/john/xiaowuOS/config/` 中创建以下占位文件：

**feishu-credentials.example.json：**
```json
{
  "app_id": "YOUR_FEISHU_APP_ID",
  "app_secret": "YOUR_FEISHU_APP_SECRET_HERE"
}
```

**openclaw-backup.example.json：**
```json
{
  "backup_token": "YOUR_BACKUP_TOKEN_HERE",
  "config_keys": ["PLACEHOLDER"]
}
```

**feishu-pairing.example.json：**
```json
{
  "pairing_code": "YOUR_PAIRING_CODE"
}
```

---

## 七、Git 历史凭据处理警告

⚠️ **重要提醒：**

即使执行上述迁移 + git rm --cached，敏感数据仍存在于 Git 历史记录中（commit 87001e5）。如需彻底清除历史中的凭据，澄木老师需考虑：

| 选项 | 操作 | 风险 |
|------|------|------|
| A. BFG Repo-Cleaner | `bfg --replace-text` 重写历史 | ⚠️ 中 — 需 force push，所有协作者需 reclone |
| B. git filter-repo | `git filter-repo --replace-refs` | ⚠️ 中 — 同上 |
| C. 接受现状 | 仅确保当前文件不跟踪 + .gitignore 保护 | ✅ 最低风险 |

**小悟建议：** C（接受现状）— 当前仓库无公网推送，历史 commit 安全。优先做迁移 + .gitignore 即可。

---

## 八、是否需要澄木老师手动确认

| # | 待确认项 | 优先级 |
|---|---------|--------|
| 1 | 是否执行敏感文件迁移到 .xiaowuOS/config/private/ | 🔴 高 |
| 2 | 是否立即 chmod 600 feishu-credentials.json（当前 664） | 🔴 高 |
| 3 | 是否补充 .gitignore config/*.json 规则 | 🟡 中 |
| 4 | 是否需要 git rm --cached 从 Git 跟踪中移除 | 🟡 中 |
| 5 | Git 历史中的凭据是否需 BFG/filter-repo 清理 | 🟢 低 |

---

*dry-run 完毕。无文件被移动或删除。*
