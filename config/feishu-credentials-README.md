# 飞书API配置文件说明

## 📋 文件信息
- **文件名**: feishu-credentials.json
- **位置**: `/home/john/xiaowuOS/config/feishu-credentials.json`
- **用途**: 存储飞书API认证凭证

## 🔧 配置字段

### 必需字段
- **app_id**: 飞书应用ID (格式: cli_xxxxxxxxxx 或 app_xxxxxxxxxx)
- **app_secret**: 飞书应用密钥 (16位以上字符串)
- **tenant_access_token**: 租户访问令牌 (自动获取)
- **expire**: 令牌过期时间 (秒)

### 可选字段
- **tenant_id**: 租户ID (已设置: ou_ad410b09c416be4b0279174f9c03920c)
- **created_at**: 创建时间
- **updated_at**: 更新时间
- **status**: 配置状态 (pending/active/expired)

## 🚀 配置步骤

### 1. 获取凭证
1. 访问 https://open.feishu.cn/
2. 创建应用并获取 App ID 和 App Secret
3. 填写到配置文件中

### 2. 更新配置
```bash
# 编辑配置文件
vim /home/john/xiaowuOS/config/feishu-credentials.json

# 更新 app_id 和 app_secret
{
  "app_id": "cli_xxxxxxxxxx",
  "app_secret": "xxxxxxxxxxxxxxxx",
  "tenant_access_token": "",
  "expire": 0,
  "tenant_id": "ou_ad410b09c416be4b0279174f9c03920c",
  "created_at": "2026-06-05T18:15:00Z",
  "updated_at": "2026-06-05T18:15:00Z",
  "status": "pending"
}
```

### 3. 验证配置
```bash
# 运行验证脚本
node /home/john/.openclaw/workspace/memory/feishu_credentials_validator.js
```

## 🔍 验证结果

### 成功状态
- ✅ 配置文件存在
- ✅ 配置文件格式正确
- ✅ API认证成功
- ✅ 日历API测试成功
- ✅ 状态: active

### 失败状态
- ❌ 配置文件不存在
- ❌ 配置文件格式错误
- ❌ API认证失败
- ❌ 日历API测试失败
- ❌ 状态: pending/expired

## 📞 技术支持

### 开发团队
- **项目负责人**: 小龙虾
- **技术协调**: 澄木老师 John

### 获取帮助
- **飞书开放平台**: https://open.feishu.cn/
- **开发者文档**: https://open.feishu.cn/document/
- **验证脚本**: `/home/john/.openclaw/workspace/memory/feishu_credentials_validator.js`

---

*生成时间: 2026-06-05 18:15*  
*版本: v1.0*  
*维护者: 小龙虾*