# xiaowuOS - 小木同学操作系统

> 一个基于 OpenClaw 的智能个人助手系统

## 📋 项目概述

xiaowuOS 是一个基于 OpenClaw 框架构建的智能个人助手系统，旨在提供日程管理、任务跟踪、AI对话等功能。

### 🎯 核心功能
- **智能对话**: 基于 AI 模型的自然语言交互
- **日程管理**: 日程安排和提醒
- **任务跟踪**: 任务管理和进度跟踪
- **飞书集成**: 企业协作平台对接
- **飞书日历**: 日程管理和待办事项
- **Telegram 支持**: 多平台消息互通

## 📁 项目结构

```
xiaowuOS/
├── app/                 # 应用程序代码
├── config/             # 配置文件
│   ├── feishu-credentials.json    # 飞书凭证
│   ├── feishu-permission-setup.md # 飞书权限配置
│   └── feishu-calendar-permission-url.txt # 飞书日历权限链接
├── data/               # 数据存储
├── logs/               # 日志文件
├── scripts/            # 脚本文件
│   ├── feishu-calendar.js         # 飞书日历模块
│   ├── feishu-calendar-test.js    # 飞书日历测试脚本
│   ├── feishu-calendar-minimal.js  # 飞书日历最小化脚本
│   └── feishu-permission-check.js # 飞书权限检查脚本
├── modules/            # 模块文件
│   └── feishu-calendar.js         # 飞书日历模块
├── docs/               # 文档文件
│   ├── feishu-calendar-status.md   # 飞书日历状态报告
│   ├── todo-data-structure.md    # 待办事项数据结构
│   ├── feishu-calendar-progress-report.md # 进展报告
│   ├── feishu-calendar-completion-report.md # 完成报告
│   ├── feishu-calendar-updated-report.md # 更新进展报告
│   └── known-issues.md           # 已知问题
├── backups/            # 备份文件
├── macos-openclaw-backup/  # macOS OpenClaw 备份
├── 迁移状态报告_*.md   # 迁移进度报告
└── README.md           # 项目说明文档
```

## 🚀 快速开始

### 环境要求
- Node.js 24.16.0+
- OpenClaw 框架
- WSL2 环境 (Windows)

### 安装步骤
1. 克隆项目到本地
2. 安装依赖包
3. 配置环境变量
4. 启动服务

### 启动命令
```bash
# 启动 OpenClaw Gateway
openclaw gateway --port 18789

# 保持 WSL 会话
./scripts/start_wsl_keepalive.sh
```

## 🔧 配置说明

### 飞书集成
飞书 API 端点已配置，需要获取有效的 App ID 和 App Secret：
- API 端点: `https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal`
- 当前状态: ✅ 网络连通，✅ 认证配置完成
- 配置文件: `~/xiaowuOS/.env`
- 配置方法: 在飞书开放平台创建应用并获取凭证

### 飞书日历
飞书日历功能已开发完成，但需要配置相应权限：
- 权限链接: `https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth`
- 当前状态: ✅ 代码开发完成，❌ 权限未配置
- 所需权限: 至少配置以下权限之一
  - `calendar:calendar:readonly` (日历只读权限)
  - `calendar:calendar` (日历读写权限)
  - `calendar:calendar.calendar:readonly` (日历日历只读权限)
  - `calendar:calendar:read` (日历读取权限)

### 模型配置
- 默认模型: `zai/glm-4.5-flash`
- 备用模型: OpenAI Codex (暂不可用)
- 模型切换: 通过 OpenClaw 配置文件

## 📊 开发进度

### 总体进度: 35%
- **第一阶段**: 80% 完成 (Day 1-2)
- **第二阶段**: 10% 开始 (Day 3-5)
- **第三阶段**: 0% 开始 (Day 6-8)

### 已完成任务
1. ✅ 环境评估
2. ✅ 开发计划制定
3. ✅ 首页问题修复
4. ✅ 产品原型设计
5. ✅ 监控机制建立
6. ✅ 飞书日历模块开发
7. ✅ 飞书日历测试脚本开发
8. ✅ 飞书日历最小化脚本开发
9. ✅ 飞书权限检查脚本开发
10. ✅ 飞书日历文档编写

### 进行中任务
1. 🔄 Hermes agent 修复 (60%)
2. 🔄 自定义首页优化 (80%)
3. 🔄 飞书日历权限配置

### 待开始任务
1. ⏳ 飞书日历功能测试
2. ⏳ 基础框架搭建
3. ⏳ 核心功能实现
4. ⏳ 数据存储设计
5. ⏳ 第二阶段功能开发

## 🎯 开发规范

### 代码风格
- 使用 ES6+ 语法
- 遵循 TypeScript 规范
- 代码注释完整

### 提交规范
- 提交信息清晰明确
- 包含相关 issue 编号
- 遵循语义化版本

### 文档规范
- 所有新功能必须有文档
- README 及时更新
- API 文档完整

## 📞 联系方式

### 开发团队
- **项目负责人**: 小龙虾
- **项目协调**: 澄木老师 John
- **技术支持**: OpenClaw 团队

### 监控和报告
- **进度报告**: 每小时自动汇报
- **状态监控**: 实时监控系统状态
- **紧急联系**: 问题立即通知

## 📝 更新日志

### v0.1.1 (2026-06-06)
- ✅ 飞书日历模块开发完成
- ✅ 飞书日历测试脚本开发完成
- ✅ 飞书日历最小化脚本开发完成
- ✅ 飞书权限检查脚本开发完成
- ✅ 飞书日历文档编写完成
- ✅ 权限监控机制建立
- ✅ 已知问题文档创建

### v0.1.0 (2026-06-05)
- ✅ 初始版本发布
- ✅ 基础框架搭建
- ✅ OpenClaw 集成
- ✅ Telegram 支持
- ✅ 飞书 API 集成准备

## 📋 待办事项

### P0 优先级
- [ ] 修复 Hermes agent 性能问题
- [ ] 完成自定义首页优化
- [ ] 配置飞书日历权限

### P1 优先级
- [ ] 测试飞书日历功能
- [ ] 开始基础框架搭建
- [ ] 实现数据存储设计
- [ ] 完善日程管理功能

### P2 优先级
- [ ] 完善 Telegram 连接稳定性
- [ ] 准备第二阶段功能开发
- [ ] 更新项目文档

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [OpenClaw](https://github.com/openclaw/openclaw) - 框架支持
- [飞书开放平台](https://open.feishu.cn/) - 企业协作支持
- [Telegram](https://telegram.org/) - 消息平台支持

---

*最后更新: 2026-06-06*  
*版本: v0.1.1*  
*维护者: 小悟同学*