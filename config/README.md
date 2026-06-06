# xiaowuOS 配置文件说明

## 📁 配置文件目录结构

```
config/
├── README.md                    # 配置文件说明
├── feishu/                      # 飞书配置目录
│   └── dedup/                   # 飞书去重配置
├── feishu-default-allowFrom.json # 飞书默认允许来源
├── feishu-pairing.json         # 飞书配对信息
├── telegram-default-allowFrom.json # Telegram 默认允许来源
└── telegram-pairing.json       # Telegram 配对信息
```

## 🔧 配置文件说明

### 飞书配置
- **feishu-default-allowFrom.json**: 飞书应用默认允许的租户来源
- **feishu-pairing.json**: 飞书应用配对信息
- **feishu/dedup/**: 飞书去重配置目录

### Telegram 配置
- **telegram-default-allowFrom.json**: Telegram 默认允许的用户ID
- **telegram-pairing.json**: Telegram 应用配对信息

## 📋 配置状态

### 飞书配置状态
- **配置文件**: ✅ 已迁移
- **API 连接**: ✅ 可连通
- **认证状态**: ❌ 需要有效凭证
- **租户ID**: `ou_ad410b09c416be4b0279174f9c03920c`

### Telegram 配置状态
- **配置文件**: ✅ 已迁移
- **连接状态**: ✅ 正常运行
- **用户ID**: `8726424800`

## 🔒 权限说明

所有配置文件权限为 `600` (仅所有者可读写)，确保安全性。

## 📝 更新日志

### 2026-06-05
- ✅ 从 `macos-openclaw-backup/` 迁移配置文件到主目录
- ✅ 创建配置文件说明文档
- ✅ 保持原有权限和内容不变