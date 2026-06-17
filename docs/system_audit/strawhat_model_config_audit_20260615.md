# 草帽团队模型配置检查报告

**日期:** 2026-06-15 08:30 (GMT+8)
**修正日期:** 2026-06-15 08:40 (根据 ollama list 实际结果修正)
**检查人:** 路飞同学 (Luffy Agent)
**范围:** 只读检查，无修改

---

## 一、当前实际配置

### 全局默认模型（openclaw.json）

| 层级 | 配置 | 值 |
|------|------|-----|
| `agents.defaults.model` | 默认模型 | `ollama/qwen3.6:27b` |
| `agents.defaults.thinking` | 推理模式 | `off` (关闭) |

**确认：** ✅ 路飞主 Agent 当前使用本地 Ollama qwen3.6:27b，符合预期。

### Agent Override 情况

- **openclaw.json 中无 `agentOverrides` 字段**
- **所有 10 个草帽团队 Agent 配置文件中均无 `modelOverride` 或等效模型覆盖字段**

### 各 Agent 配置文件摘要

| Agent | 文件 | modelOverride | currentModel (继承) |
|-------|------|---------------|---------------------|
| Luffy (主) | openclaw.json | ❌ 无 | ollama/qwen3.6:27b |
| Robin | agents/nami/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Nami | agents/nami/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Chopper | agents/chopper/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Usopp | agents/usopp/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Sanji | agents/sanji/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Brook | agents/brook/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Franky | agents/franky/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Zoro | agents/zoro/config.json | ❌ 无 | 继承 → qwen3.6:27b |
| Shinji | agents/jinbe/config.json | ❌ 无 | 继承 → qwen3.6:27b |

> **结论：** 目前所有 Agent 均继承全局默认 `ollama/qwen3.6:27b`，无任何差异配置。

---

## 二、Ollama Cloud 模型可用性

### 本机已安装的全部模型（ollama list）

| # | 模型 | 类型 | 大小 | 状态 |
|---|------|------|------|------|
| 1 | qwen3.6:27b | Local | ~18GB | ✅ 运行中，全局默认 |
| 2 | qwen3.6:35b | Local | ~24GB | ✅ 已安装，索隆使用 |
| 3 | qwen3-coder:30b | Local | ~20GB | ✅ 已安装，弗兰奇使用 |
| 4 | qwen3-vl:8b | Local | ~5GB | ✅ 已安装（视觉/多模态） |
| 5 | qwen3:8b | Local | ~5GB | ✅ 已安装（轻量兜底） |
| 6 | qwen3-coder:480b-cloud | Cloud | — | ✅ 已注册，Franky 复杂代码可用 |
| 7 | gpt-oss:20b-cloud | Cloud | — | ✅ 已注册，布鲁克使用 |
| 8 | gpt-oss:120b-cloud | Cloud | — | ✅ 已注册，内容生成组使用 |

**Cloud Provider 状态：** ✅ Ollama Cloud 已注册为 `ollamacloud`，API Key (`ollamactl-...`) 有效。

**Free Tier 限制：**
- 免费额度有限，高并发可能触发速率限制
- 建议 concurrency=1 观察一周
- 暂不购买 Pro

---

## 三、本地 Ollama 模型情况

### Local 模型已就位，无需额外安装

| 模型 | 用途 |
|------|------|
| qwen3.6:27b | 路飞 / 甚平默认模型；Cloud Agent fallback |
| qwen3.6:35b | 索隆终检风控（Local Only） |
| qwen3-coder:30b | 弗兰奇代码工程（Local Only，敏感配置必走本地） |
| qwen3-vl:8b | 视觉/多模态任务备用 |
| qwen3:8b | 轻量兜底，短文本 / 格式校验 |

> **结论：模型已齐全。当前瓶颈不在安装，而在 openclaw.json 中缺少 `agentOverrides`，导致所有 Agent 统一继承默认 qwen3.6:27b。**

---

## 四、推荐调整方案

### 4.1 各 Agent 推荐模型分配

基于澄木老师确认的分工：

#### Local-Only Agent（安全 + 调度组）

| Agent | 推荐模型 | 类型 | 职责 |
|-------|---------|------|------|
| 路飞 | qwen3.6:27b (不变) | Local | 总控、调度、汇总，不承担重内容生成 |
| 乔巴 | qwen3.6:27b (不变) | Local | 学员诊断；涉及学生/家长/成绩/心理/隐私时必走 Local；非敏感学习建议后续可试用 Cloud |
| 弗兰奇 | qwen3-coder:30b | Local | 代码、脚本、工程实现；敏感系统配置必走 Local；非敏感复杂代码可调用 qwen3-coder:480b-cloud |
| 索隆 | qwen3.6:35b | Local | 终检、风控、防误删、防跑偏，必须 Local Only |
| 甚平 | qwen3.6:27b (不变) | Local | 系统健康检查，Local Only |

#### Cloud-First Agent（内容生成组）

| Agent | 推荐模型 | Fallback | 职责 |
|-------|---------|----------|------|
| 罗宾 | gpt-oss:120b-cloud | qwen3.6:27b | 课程资料整理、知识沉淀 |
| 娜美 | gpt-oss:120b-cloud | qwen3.6:27b | 课程节奏、规划、排期 |
| 乌索普 | gpt-oss:120b-cloud | qwen3.6:27b | 故事化表达、案例、脚本（第一批试切） |
| 山治 | gpt-oss:120b-cloud | qwen3.6:27b | 课堂话术、家长沟通、温度表达 |
| 布鲁克 | gpt-oss:20b-cloud | qwen3.6:27b | 总结、金句、复盘（第一批试切） |

### 4.2 第一批切换计划（保守策略）

不全面切换，先小步验证：

| # | Agent | 变更内容 | 风险等级 | 理由 |
|---|-------|---------|---------|------|
| 1 | 乌索普 | 继承 → gpt-oss:120b-cloud | 🟢 低 | 故事化表达，非敏感内容，适合试水 |
| 2 | 布鲁克 | 继承 → gpt-oss:20b-cloud | 🟢 低 | 总结复盘，轻量 Cloud 即可 |
| 3 | 索隆 | 继承 qwen3.6:27b → qwen3.6:35b | 🟢 低 | Local Only，纯本地升级，增强风控能力 |
| 4 | 弗兰奇 | 继承 qwen3.6:27b → qwen3-coder:30b | 🟢 低 | Local Only，代码专用模型 |

后续批次（待第一批验证通过后）：罗宾、娜美、山治逐步切换。

### 4.3 具体配置变更 diff（待确认）

以下为 `openclaw.json` 中需新增的 `agentOverrides` 结构：

```jsonc
// openclaw.json → agents.agentOverrides 新增（第一批）
{
  "agentOverrides": {
    "usopp": {
      "model": "ollamacloud/gpt-oss:120b-cloud",
      "fallbacks": ["ollama/qwen3.6:27b"]
    },
    "brook": {
      "model": "ollamacloud/gpt-oss:20b-cloud",
      "fallbacks": ["ollama/qwen3.6:27b"]
    },
    "zoro": {
      "model": "ollama/qwen3.6:35b"
    },
    "franky": {
      "model": "ollama/qwen3-coder:30b",
      "fallbacks": ["ollama/qwen3.6:27b"]
    }
  }
}
// ⚠️ 此为建议结构，实际语法需与 gateway config.schema.lookup 对齐后再应用
```

### 4.4 后续批次 diff（待第一批验证后执行）

| # | Agent | 变更内容 | 备注 |
|---|-------|---------|------|
| 5 | 罗宾 | 继承 → gpt-oss:120b-cloud | 课程资料整理，非敏感 |
| 6 | 娜美 | 继承 → gpt-oss:120b-cloud | 规划排期，非敏感 |
| 7 | 山治 | 继承 → gpt-oss:120b-cloud | 话术润色可走 Cloud；家长聊天原文仍走 Local |

```jsonc
// openclaw.json → agents.agentOverrides 新增（第二批）
{
  "robin": {
    "model": "ollamacloud/gpt-oss:120b-cloud",
    "fallbacks": ["ollama/qwen3.6:27b"]
  },
  "nami": {
    "model": "ollamacloud/gpt-oss:120b-cloud",
    "fallbacks": ["ollama/qwen3.6:27b"]
  },
  "sanji": {
    "model": "ollamacloud/gpt-oss:120b-cloud",
    "fallbacks": ["ollama/qwen3.6:27b"]
  }
}
```

---

## 五、敏感任务 Local-Only 检查

### 当前情况

所有 Agent 均继承全局默认模型，全部走本地 Ollama。✅ 从数据安全角度是安全的。

### 乔巴特殊处理

乔巴目前保持 qwen3.6:27b（Local），因为：
- 涉及学生/家长/成绩/心理/隐私内容时必须 Local Only
- 非敏感学习建议可后续试用 gpt-oss:120b-cloud
- 当前暂不切换，先观察其他 Agent Cloud 效果

### 切换 Cloud 后需注意

| 任务类型 | 涉及 Agent | 风险等级 | 建议 |
|----------|-----------|---------|------|
| 微信信息采集 | — | 🔴 | 必须 Local Only |
| 飞书/Telegram 私密配置 | 甚平 | 🔴 | 保持 Local Only |
| GitHub token / 密钥 | 弗兰奇 | 🔴 | 敏感操作强制走 qwen3-coder:30b (Local) |
| 学生隐私原文 | 乔巴 | 🔴 | 默认 Local，暂不切 Cloud |
| 本地文件清理 | 弗兰奇 | 🟡 | Local Only |
| Git 安全审计 | 索隆 | 🟡 | qwen3.6:35b (Local Only) |
| 系统配置修改 | 弗兰奇、甚平 | 🔴 | Local Only |
| 家长聊天原文分析 | 山治 | 🔴 | 原文走 Local，仅润色输出可走 Cloud |

---

## 六、风险与注意事项（修正版）

### ✅ 已确认无问题的项

| # | 原问题 | 状态 | 说明 |
|---|--------|------|------|
| 1 | qwen3.6:35b 未安装 | ✅ 已修复 | ollama list 确认已安装 |
| 2 | qwen3-coder:30b 未安装 | ✅ 已修复 | ollama list 确认已安装 |
| 3 | Cloud 模型 ID 有效性 | ✅ 已确认 | gpt-oss:120b-cloud、gpt-oss:20b-cloud、qwen3-coder:480b-cloud 均已注册 |

### ⚠️ 仍需注意的项

| # | 风险 | 影响 | 缓解措施 |
|---|------|------|---------|
| 1 | Cloud Free Tier 额度 | 高并发可能被限流 | concurrency=1，错峰调用 |
| 2 | agentOverrides schema | 建议 diff 语法可能不完全准确 | 需与 config.schema.lookup 对齐后再应用 |
| 3 | 无 Cloud fallback 实际测试 | Cloud 模型首次调用的稳定性未知 | 先试切乌索普+布鲁克，观察一周 |

---

## 七、执行策略

### 建议现在执行的修改（第一批）

| # | 操作 | 风险 | 是否需澄木老师确认 |
|---|------|------|------------------|
| 1 | 乌索普 → gpt-oss:120b-cloud | 🟢 低 | ✅ 是 |
| 2 | 布鲁克 → gpt-oss:20b-cloud | 🟢 低 | ✅ 是 |
| 3 | 索隆 → qwen3.6:35b | 🟢 极低（纯 Local） | ✅ 是 |
| 4 | 弗兰奇 → qwen3-coder:30b | 🟢 极低（纯 Local） | ✅ 是 |

### 暂不执行的项

- Cloud 全面切换（待第一批验证后）
- 乔巴切 Cloud（默认保持 Local）
- 重启服务
- Git 提交 / 打 tag

---

## 八、待澄木老师确认事项

| # | 事项 | 选项 | 默认建议 |
|---|------|------|---------|
| 1 | 第一批 diff 是否正确？ | 确认 / 修改 | 需澄木老师确认 |
| 2 | Cloud Free Tier 观察多久开始第二批切换？ | 1周 / 2周 | 1周 |
| 3 | 乔巴隐私任务如何判断？ | 手动标记 / 关键词匹配 | 先手动标记 |
| 4 | Cloud concurrency=1 是否接受？ | 是 / 动态调整 | 接受 |

---

## 九、Failover Cloud Mode（主备方案补充）

### 9.1 背景与定位

| 维度 | 主机 (Primary) | 备机 (Standby) |
|------|---------------|----------------|
| GPU | ✅ 强力显卡，可运行大模型 | ❌ 无强力显卡 |
| 主要角色 | Local + Cloud 混合推理 | Ollama Cloud 推理模式 |
| 本地模型 | 完整模型库（qwen3.6:27b / 35b） | 仅轻量模型，用于短文本/离线兜底 |
| 接管方式 | 正常运行 | 紧急切换后接管 xiaowuOS |

**核心原则：备机优先保证 xiaowuOS 能恢复运行，不追求本地大模型性能。**

### 9.2 两套模型 Profile

#### Profile A — primary（主机日常模式）

| Agent | 默认模型 | Fallback | 备注 |
|-------|---------|----------|------|
| 路飞 | qwen3.6:27b (Local) | — | 总控调度，不变 |
| 罗宾 | gpt-oss:120b-cloud | qwen3.6:27b | 课程资料/知识沉淀 |
| 娜美 | gpt-oss:120b-cloud | qwen3.6:27b | 规划排期 |
| 乔巴 | qwen3.6:27b (Local) | — | 学员诊断，隐私任务必走 Local，默认保持本地 |
| 乌索普 | gpt-oss:120b-cloud | qwen3.6:27b | 故事化表达 |
| 山治 | gpt-oss:120b-cloud | qwen3.6:27b | 话术润色 |
| 布鲁克 | gpt-oss:20b-cloud | qwen3.6:27b | 总结复盘 |
| 弗兰奇 | qwen3-coder:30b (Local) | — | 代码工程，敏感配置 Local Only |
| 索隆 | qwen3.6:35b (Local) | — | 终检风控，必须 Local Only |
| 甚平 | qwen3.6:27b (Local) | — | 系统健康检查，Local Only |

#### Profile B — standby-cloud（备机紧急接管模式）

| Agent | 默认模型 | Fallback | 备注 |
|-------|---------|----------|------|
| 路飞 | gpt-oss:20b-cloud | tinyllama (Local) | 总控调度切 Cloud |
| 罗宾 | gpt-oss:120b-cloud | tinyllama (Local) | 课程资料 |
| 娜美 | gpt-oss:120b-cloud | tinyllama (Local) | 规划排期 |
| 乔巴 | gpt-oss:120b-cloud | tinyllama (Local) | 学员诊断，隐私任务切 Local |
| 乌索普 | gpt-oss:120b-cloud | tinyllama (Local) | 故事化表达 |
| 山治 | gpt-oss:120b-cloud | tinyllama (Local) | 话术润色 |
| 布鲁克 | gpt-oss:20b-cloud | tinyllama (Local) | 总结复盘 |
| 弗兰奇 | qwen3-coder:480b-cloud | tinyllama (Local) | 代码工程切 Cloud，敏感操作仍 Local |
| 索隆 | gpt-oss:20b-cloud | tinyllama (Local) | ⚠️ 风控能力降级 |
| 甚平 | gpt-oss:20b-cloud | tinyllama (Local) | 系统检查可走 Cloud |

### 9.3 备机本地轻量模型建议

仅保留 1-2 个轻量模型作为离线兜底：

| 模型 | 大小 | 用途 |
|------|------|------|
| tinyllama:1b | ~600MB | 短文本、格式校验、系统提示 |
| qwen3.6:8b | ~5GB (可选) | 离线时基本推理能力 |

**不需要安装：** qwen3.6:27b / 35b、qwen3-coder 等重型模型。

### 9.4 敏感任务 Local-Only（备机不可放松）

即使切到备机 Cloud First，以下任务**仍然必须走本地轻量模型**：

| # | 任务类型 | 涉及 Agent | 风险等级 | 说明 |
|---|---------|-----------|---------|------|
| 1 | 微信信息采集 | — | 🔴 | 原文不可上云 |
| 2 | 飞书/Telegram 私密配置 | 甚平 | 🔴 | credentials、token、pairing 原文不可上云 |
| 3 | GitHub token / 密钥 | 弗兰奇 | 🔴 | 任何 secrets 操作必须 Local |
| 4 | 学生隐私原文 | 乔巴 | 🔴 | 原始聊天记录/诊断原文不可上云 |
| 5 | 本地文件清理 | — | 🟡 | 文件系统操作不依赖大模型 |
| 6 | Git 安全审计 | 索隆 | 🟡 | 审计判断走轻量 Local |
| 7 | 系统配置修改 | 弗兰奇/甚平 | 🔴 | 配置变更必须 Local |
| 8 | 家长聊天原文分析 | 山治 | 🔴 | 原文走 Local，仅润色输出可上云 |

> **关键：切换备机 ≠ 降低安全标准。敏感数据不上云是铁律。**

### 9.5 紧急切换检查清单

当主机不可用、需要切换到备机时，按以下顺序执行：

```text
[ ] 1. 确认 Ollama Cloud API Key 有效
     → ollama list --cloud 或测试 ping

[ ] 2. 验证 Cloud 模型可用性
     → gpt-oss:120b-cloud 可调用？
     → gpt-oss:20b-cloud 可调用？
     → qwen3-coder:480b-cloud 可调用？
     → Free Tier 额度是否充足？

[ ] 3. 检查备机本地轻量模型
     → tinyllama:1b 是否已拉取？
     → ollama pull tinyllama (如未安装)

[ ] 4. 加载 standby-cloud Profile
     → 切换 agentOverrides 到 Cloud 模式
     → 确认全局 fallback 指向本地轻量模型

[ ] 5. 验证 Agent 路由
     → 草帽团队 10 Agent 均能响应？
     → Telegram 网关是否正常连接？
     → 飞书通道是否正常？

[ ] 6. 确认 sensitive Local Only 规则生效
     → 学生隐私、token、密钥操作是否强制走本地？
     → Franky/索隆/甚平的安全限制是否保持？

[ ] 7. Telegram 网关连通性检查
     → bot token 是否正常？
     → 消息收发测试
     → 配对状态确认

[ ] 8. Cloud concurrency 限制确认
     → 备机 Cloud 调用频率是否合理？
     → 避免触发 Free Tier 速率限制

[ ] 9. 通知澄木老师切换完成
     → 报告当前运行状态
     → 说明降级影响（如索隆风控能力下降）
```

### 9.6 主机恢复后的回切流程

当主机恢复正常时：

```text
[ ] 1. 确认主机本地模型运行正常
[ ] 2. 加载 primary Profile（混合模式）
[ ] 3. 验证关键 Agent 响应
[ ] 4. 逐步从备机迁移流量
[ ] 5. 备机回退到待命状态
[ ] 6. 通知澄木老师回切完成
```

### 9.7 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| Cloud Free Tier 额度耗尽 | 所有 Cloud Agent 不可用 | Fallback 到本地轻量模型，功能降级但可用 |
| 备机网络不稳定 | Cloud 调用失败 | 必须有 Local 轻量模型兜底 |
| 索隆风控能力降级 | 安全审查质量下降 | 关键操作仍需人工二次确认 |
| Franky 代码质量变化 | qwen3-coder:480b vs 30b 差异 | 复杂代码需要额外人工审查 |
| Cloud concurrency 限制 | 多 Agent 同时调用被限流 | 错峰调度，concurrency=1 |

---

**报告结束**

