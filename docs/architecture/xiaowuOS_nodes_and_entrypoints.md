# xiaowuOS 三节点架构 · 命名规范与入口规划

**版本：** V1.0  
**创建日期：** 2026-06-16  
**负责人：** 路飞（总控）  
**状态：** 文档规划阶段，未修改核心服务

---

## 一、总入口

| 项目 | 值 |
|------|-----|
| **统一域名** | `johnonlife.com` |
| **FRP Server** | `johnonlife.com:7000` |
| **FRP 端口范围** | `60022–60066` |

所有外网访问统一通过 `johnonlife.com` + FRP 映射端口实现。

---

## 二、三节点命名规范

| 节点代号 | 角色 | 定位 | 运行内容 |
|----------|------|------|----------|
| **xiaowuOSa** | 主机 (Primary) | 日常运行 | OpenClaw / Gateway / Telegram / 草帽团队 / 课程生产 |
| **xiaowuOSb** | 备机一 (Standby-1) | WSL 热备，准实时同步 | rsync 拉取、可手动接管 |
| **xiaowuOSc** | 备机二 (Cold-Backup) | 冷备快照 | 每日/每周加密快照，历史回滚 |

### 命名原则

1. **统一前缀：** `xiaowuOS` + 小写字母后缀（a/b/c）
2. **不缩写：** 禁止使用 xOSa、wuOSb 等缩写形式
3. **字母含义：** a=primary, b=standby-1, c=cold-backup
4. **可扩展：** 后续如需 d/e 节点，按字母序追加

### 旧名称兼容

| 旧名称 | 新名称 | 处理方式 |
|--------|--------|----------|
| `xiaowuOS` (SSH Host) | `xiaowuOSa` | **保留为别名**，不删除，待所有脚本迁移后再清理 |

> ⚠️ **过渡期原则：** SSH Config 中同时保留 `Host xiaowuOS` 和 `Host xiaowuOSa`，前者作为后者的兼容别名。所有新脚本使用 `xiaowuOSa`，但旧脚本不因名称变更而破坏。

---

## 三、FRP 端口规划

### 已分配

| 端口 | 节点 | 服务 | 状态 | 备注 |
|------|------|------|------|------|
| **60022** | xiaowuOSa | SSH (TCP) | ✅ 已配置 | `wsl-ubuntu-ssh` |
| **60024** | xiaowuOSb | SSH (TCP) | ⏳ 待配置 | — |
| **60026** | xiaowuOSc | SSH (TCP) | ✅ 已配置 | 冷备节点 FRP |
| **60030** | xiaowuOSa | Dashboard (HTTP) | ✅ 已配置 | `xiaowuos-dashboard` |

### 规划预留

| 端口 | 用途 | 状态 | 备注 |
|------|------|------|------|
| **60031** | xiaowuOSb Dashboard | ⏳ 预留 | 待备机部署后配置 |
| **60040–60049** | 各节点状态服务/监控 | ⏳ 预留 | heartbeat、healthcheck 等 |
| **60060–60066** | 测试/临时服务 | ⏳ 预留 | 短生命周期，用完即收 |

### xiaowuOSc（冷备）

- **FRP SSH 端口：** `60026` ✅ 已分配
- **SSH + FRP/frpc：** systemd 自启动
- **macOS 免密访问：** 已配置
- 冷备节点基础环境已完成，待规划快照策略

---

## 四、SSH Host 规划

```ini
# ===== xiaowuOSa (主节点) =====
Host xiaowuOSa
    HostName <待配置>
    Port <待配置>
    User <待配置>
    # FRP 隧道通过 johnonlife.com:60022

# ===== 兼容别名（过渡期保留）=====
Host xiaowuOS
    ProxyJump xiaowuOSa
    # 仅作为向后兼容，新脚本请使用 xiaowuOSa

# ===== xiaowuOSb (第一备机) =====
Host xiaowuOSb
    HostName <已配置>
    Port <已配置>
    User <已配置>
    # FRP 隧道通过 johnonlife.com:60024（待开通）

# ===== xiaowuOSc (冷备节点) — 已就位 =====
Host xiaowuOSc
    HostName johnonlife.com
    Port 60026
    User <待确认>
    # FRP SSH 已上线，基础环境已完成
```

> ⚠️ **当前状态：** `xiaowuOSb` 已配置；`xiaowuOSa` 和 `xiaowuOSc` 待补充。旧别名 `xiaowuOS` 保留不删除。

---

## 五、Dashboard 访问规划

### 各节点 Dashboard

| 节点 | 本地地址 | FRP 外网地址 | 状态 |
|------|----------|-------------|------|
| xiaowuOSa | `http://127.0.0.1:18790` | `http://johnonlife.com:60030/dashboard.html` | ✅ 已上线 |
| xiaowuOSb | — | `http://johnonlife.com:60031/dashboard.html` | ⏳ 待部署 |
| xiaowuOSc | — | 暂不配置 | ❌ 冷备不需 Dashboard |

### Dashboard 展示内容规划（V2.0+）

| 模块 | 当前状态 | V2 目标 |
|------|----------|---------|
| 系统总览 | ✅ 静态数据 | 接入真实 Gateway/磁盘/内存数据 |
| 草帽团队 | ✅ 10人卡片 | 实时忙闲 + 模型分配自动同步 |
| 任务队列 | ✅ 今日 P1 列表 | 与 OpenClaw sessions/cron 联动 |
| 主备状态 | ⚠️ 手动更新 | FRP/rsync/failover 自动探测 |
| 模型状态 | ✅ 静态列出 | Ollama API + Cloud provider 实时查询 |

---

## 六、主备同步关系

```
┌─────────────┐     rsync (5min)     ┌─────────────┐
│  xiaowuOSa  │ ──────────────────→  │  xiaowuOSb  │
│  (主机)      │                     │  (热备-WSL)  │
│  Primary    │   ←── 手动 failover ─┘             │
└──────┬──────┘                                   │
       │                                          │
       │ 每日快照                                  │
       ↓                                          │
┌─────────────┐                                   │
│  xiaowuOSc  │                                   │
│  (冷备)      │ 加密归档 · 历史版本 · 长期回滚     │
└─────────────┘                                   │
```

| 同步方向 | 频率 | 方式 | 内容 |
|----------|------|------|------|
| a → b | 5 分钟 | rsync cron | `.openclaw/` + `xiaowuOS/projects` + `xiaowuOS/outputs` |
| a → c | 每日/每周 | 加密 tar.gz | 关键配置 + 备份快照 |
| b → a | 手动 | failover 脚本 | 备机接管时反向同步 |

---

## 七、xiaowuOSc 冷备定位

### 核心目标（狡兔三窟第三窟）

1. **防误删** — 当 a/b 双机同时发生误删除时，可从 c 恢复
2. **防配置污染** — 保存"干净"的历史版本配置快照
3. **防主备双异常** — a+b 同时故障时的最终防线
4. **历史版本保留** — 定期快照，支持任意时间点回滚
5. **长期归档** — 不依赖实时性，侧重完整性和可恢复性

### 不做的事

- ❌ 不跑 OpenClaw / Gateway
- ❌ 不参与准实时 rsync
- ✅ 提供 FRP SSH 常开端口 `60026`
- ❌ 不作为日常工作环境

---

## 八、主备脚本命名过渡方案

### PRIMARY_HOST 迁移路径

| 阶段 | PRIMARY_HOST 值 | 状态 |
|------|----------------|------|
| **当前** | `xiaowuOS` (旧别名) | ✅ 工作正常 |
| **下一阶段** | `xiaowuOSa` | ⏳ 待迁移，需澄木老师确认 |
| **最终阶段** | `xiaowuOSa` + 删除旧别名 `xiaowuOS` | ❌ 不在本次范围 |

### 过渡期操作清单

- [ ] SSH Config 中增加 `Host xiaowuOSa` 条目
- [ ] 保留 `Host xiaowuOS` 作为兼容别名
- [ ] 新增脚本统一使用 `xiaowuOSa`
- [ ] 现有 rsync/failover 脚本中的 `PRIMARY_HOST` 保持不动
- [ ] 待所有脚本验证无误后，再执行 PRIMARY_HOST → xiaowuOSa 切换
- [ ] 删除旧别名需单独审批

---

## 九、端口使用总表

| 端口 | 节点 | 服务 | 协议 | 状态 |
|------|------|------|------|------|
| 60022 | xiaowuOSa | SSH | TCP | ✅ |
| 60024 | xiaowuOSb | SSH | TCP | ⏳ |
| 60026 | xiaowuOSc | SSH | TCP | ✅ |
| 60030 | xiaowuOSa | Dashboard | HTTP | ✅ |
| 60031 | xiaowuOSb | Dashboard | HTTP | ⏳ |
| 60040-60049 | — | 状态服务预留 | — | ⏳ |
| 60050-60059 | — | 未分配 | — | 🔒 |
| 60060-60066 | — | 测试预留 | — | ⏳ |

---

## 十、修订记录

| 日期 | 版本 | 变更内容 | 负责人 |
|------|------|----------|--------|
| 2026-06-16 | V1.0 | 初始架构文档，三节点命名规范 | 路飞 |
| 2026-06-16 | V1.1 | xiaowuOSc 基础环境就位：SSH/frpc systemd 自启动，FRP 端口 60026，macOS 免密已配置，dashboard.json 更新三节点状态 | 路飞 |

---

*本文档为规划性质。修改核心配置前需澄木老师确认。*
