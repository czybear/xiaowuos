#!/bin/bash

# xiaowuOS 自定义首页启动脚本
# 用途: 启动自定义首页服务

echo "启动 xiaowuOS 自定义首页服务..."
echo "时间: $(date)"

# 检查是否已经有服务在运行
if ss -tlnp | grep -q :8080; then
    echo "警告: 端口 8080 已被占用，请先停止现有服务"
    exit 1
fi

# 启动服务
cd /home/john/xiaowuOS
node /home/john/.openclaw/workspace/memory/test_homepage.js &

# 等待服务启动
sleep 2

# 检查服务状态
if ss -tlnp | grep -q :8080; then
    echo "✅ 自定义首页服务已成功启动"
    echo "访问地址: http://127.0.0.1:8080/"
    echo "进程ID: $(pgrep -f "test_homepage.js")"
else
    echo "❌ 自定义首页服务启动失败"
    exit 1
fi

echo "启动完成时间: $(date)"