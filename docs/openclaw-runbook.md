# OpenClaw 运行手册

> xiaowuOS 中 OpenClaw 的运行管理指南

## 📋 系统概览

### 基本信息
- **项目名称**: xiaowuOS 小木同学操作系统
- **OpenClaw 版本**: 2026.5.28 (e932160)
- **运行时间**: 13h 46m (持续运行)
- **工作目录**: /home/john/.openclaw/workspace

### 服务状态
- **OpenClaw Gateway**: ✅ 运行中 (端口 18789)
- **自定义首页**: ✅ 运行中 (端口 8080)
- **Telegram**: ✅ 连接正常
- **默认模型**: zai/glm-4.5-flash (固定使用)

## 🚀 启动命令

### OpenClaw Gateway 启动
```bash
# 启动 OpenClaw Gateway
openclaw gateway --port 18789

# 或使用完整路径
/home/john/.nvm/versions/node/v24.16.0/bin/node /home/john/.nvm/versions/node/v24.16.0/lib/node_modules/openclaw/dist/index.js gateway --port 18789
```

### 自定义首页启动
```bash
# 启动自定义首页服务
cd /home/john/xiaowuOS
./scripts/start_homepage.sh

# 或直接运行
node /home/john/.openclaw/workspace/memory/test_homepage.js
```

### WSL 会话保持
```bash
# 启动 WSL 保持脚本
cd /home/john/xiaowuOS
./scripts/start_wsl_keepalive.sh
```

## 🛑 停止命令

### 停止 OpenClaw Gateway
```bash
# 查找进程
ps aux | grep openclaw | grep -v grep

# 终止进程
kill -TERM <PID>
```

### 停止自定义首页服务
```bash
# 查找进程
ps aux | grep test_homepage | grep -v grep

# 终止进程
kill -TERM <PID>
```

## 🔄 重启命令

### 重启 OpenClaw Gateway
```bash
# 1. 停止服务
kill -TERM <PID>

# 2. 等待进程完全停止
sleep 3

# 3. 重新启动
openclaw gateway --port 18789
```

### 重启自定义首页服务
```bash
# 1. 停止服务
kill -TERM <PID>

# 2. 等待进程完全停止
sleep 2

# 3. 重新启动
./scripts/start_homepage.sh
```

## 🔍 状态查看

### 查看系统状态
```bash
# 查看 OpenClaw Gateway 状态
curl -s http://127.0.0.1:18789/ | head -5

# 查看自定义首页状态
curl -s http://127.0.0.1:8080/ | head -5

# 查看端口占用
ss -tlnp | grep :18789
ss -tlnp | grep :8080
```

### 查看进程状态
```bash
# 查看 OpenClaw 进程
ps aux | grep openclaw | grep -v grep

# 查看自定义首页进程
ps aux | grep test_homepage | grep -v grep

# 查看所有相关进程
ps aux | grep -E "(openclaw|test_homepage|start_homepage)" | grep -v grep
```

### 查看系统资源
```bash
# 查看内存使用
free -h

# 查看CPU使用
top -p <PID>

# 查看磁盘使用
df -h
```

## 📊 监控指标

### 性能指标
- **内存使用**: 正常范围
- **CPU使用**: 正常范围
- **网络连接**: 正常
- **端口占用**: 正常

### 健康检查
```bash
# 检查 OpenClaw Gateway 健康状态
curl -s http://127.0.0.1:18789/api/status

# 检查自定义首页健康状态
curl -s http://127.0.0.1:8080/ | grep -o "xiaowuOS.*操作系统"

# 检查 Telegram 连接状态
curl -s http://127.0.0.1:18789/api/channels
```

## 🔧 配置管理

### 配置文件位置
- **主配置**: /home/john/xiaowuOS/config/
- **飞书配置**: /home/john/xiaowuOS/config/feishu-credentials.json
- **Telegram 配置**: /home/john/xiaowuOS/config/telegram-*.json
- **备份配置**: /home/john/xiaowuOS/config/backup/

### 日志文件位置
- **系统日志**: /home/john/xiaowuOS/logs/
- **OpenClaw 日志**: 系统日志
- **自定义首页日志**: 系统标准输出

## 🚨 故障排除

### 常见问题

#### 1. OpenClaw Gateway 无法启动
```bash
# 检查端口占用
netstat -tlnp | grep :18789

# 检查依赖服务
systemctl status openclaw-gateway.service

# 查看错误日志
journalctl -u openclaw-gateway.service -n 50
```

#### 2. 自定义首页无法访问
```bash
# 检查服务状态
ps aux | grep test_homepage | grep -v grep

# 检查端口占用
ss -tlnp | grep :8080

# 查看服务日志
tail -f /home/john/xiaowuOS/logs/wsl_start.log
```

#### 3. Telegram 连接问题
```bash
# 检查配置文件
cat /home/john/xiaowuOS/config/telegram-default-allowFrom.json

# 测试连接
curl -s http://127.0.0.1:18789/api/channels
```

### 解决方案

#### 服务重启
```bash
# 重启所有服务
./scripts/restart_all.sh

# 或手动重启
./scripts/start_wsl_keepalive.sh
./scripts/start_homepage.sh
openclaw gateway --port 18789
```

#### 配置修复
```bash
# 备份当前配置
cp -r /home/john/xiaowuOS/config /home/john/xiaowuOS/config_backup_$(date +%Y%m%d_%H%M%S)

# 恢复配置
cp -r /home/john/xiaowuOS/config_backup_*/config /home/john/xiaowuOS/
```

## 📞 技术支持

### 开发团队
- **项目负责人**: 小悟同学
- **技术协调**: 澄木老师 John

### 联系方式
- **紧急问题**: 立即通知
- **一般问题**: 记录到 known-issues.md
- **功能建议**: 添加到 TODO.md

### 文档资源
- **项目文档**: /home/john/xiaowuOS/docs/
- **迁移状态**: /home/john/xiaowuOS/docs/migration-status.md
- **运行手册**: /home/john/xiaowuOS/docs/openclaw-runbook.md

---

*文档生成完成，进入持续推进模式...*