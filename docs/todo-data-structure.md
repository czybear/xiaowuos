# 飞书日历待办事项数据结构

**文档时间**: 2026-06-06 05:15:57 GMT+8  
**负责人**: 小悟同学  
**用途**: 飞书日历 / 日程管理功能数据结构定义

**实现状态**: ✅ 数据结构定义完成
**开发状态**: ✅ 基础模块开发完成
**测试状态**: ❌ 权限配置中  

---

## 📋 待办事项数据结构

### 1. 日程 (Event) 结构

根据飞书API文档，日程数据结构如下：

**实现状态**: ✅ 已在 feishu-calendar.js 中实现

```json
{
  "event_id": "ev-xxxxxxxxxxxx",
  "calendar_id": "calendar_xxxxxxxxxx",
  "summary": "日程标题",
  "description": "日程描述",
  "start_time": {
    "timestamp": 1717564800,
    "timezone": "Asia/Shanghai"
  },
  "end_time": {
    "timestamp": 1717568400,
    "timezone": "Asia/Shanghai"
  },
  "visibility": "default",
  "attendees": [
    {
      "user_id": "ou_xxxxxxxxxx",
      "name": "参与者姓名",
      "email": "participant@example.com",
      "is_organizer": false,
      "status": "accepted"
    }
  ],
  "organizer": {
    "user_id": "ou_xxxxxxxxxx",
    "name": "组织者姓名",
    "email": "organizer@example.com"
  },
  "location": {
    "location_id": "loc_xxxxxxxxxx",
    "name": "会议室A",
    "address": "北京市朝阳区xxx街道xxx号"
  },
  "reminders": [
    {
      "minutes": 15,
      "type": "popup"
    }
  ],
  "status": "confirmed",
  "created_at": "2024-06-06T10:00:00Z",
  "updated_at": "2024-06-06T10:00:00Z"
}
```

### 2. 日历 (Calendar) 结构

**实现状态**: ✅ 已在 feishu-calendar.js 中实现

```json
{
  "calendar_id": "calendar_xxxxxxxxxx",
  "summary": "日历名称",
  "description": "日历描述",
  "owner": {
    "user_id": "ou_xxxxxxxxxx",
    "name": "所有者姓名",
    "email": "owner@example.com"
  },
  "timezone": "Asia/Shanghai",
  "access_level": "owner",
  "color": "#1E88E5",
  "created_at": "2024-06-06T10:00:00Z",
  "updated_at": "2024-06-06T10:00:00Z"
}
```

### 3. 待办事项 (Todo) 结构

飞书日历没有单独的待办事项API，但可以通过日程实现类似功能：

**实现状态**: 🔄 计划通过日程实现待办事项功能

```json
{
  "todo_id": "todo_xxxxxxxxxx",
  "summary": "待办事项标题",
  "description": "待办事项描述",
  "status": "pending", // pending, completed, cancelled
  "priority": "medium", // low, medium, high
  "due_date": {
    "timestamp": 1717564800,
    "timezone": "Asia/Shanghai"
  },
  "reminder": {
    "minutes": 30,
    "type": "popup"
  },
  "created_at": "2024-06-06T10:00:00Z",
  "updated_at": "2024-06-06T10:00:00Z"
}
```

---

## 🔧 API接口定义

### 1. 获取日历列表

**实现状态**: ✅ 已在 feishu-calendar.js 中实现
**测试状态**: ❌ 需要配置权限

```javascript
// 请求
GET /open-apis/calendar/v4/calendars

// 响应
{
  "code": 0,
  "msg": "success",
  "data": {
    "calendars": [
      {
        "calendar_id": "calendar_xxxxxxxxxx",
        "summary": "我的日历",
        "description": "个人日程管理",
        "owner": {
          "user_id": "ou_xxxxxxxxxx",
          "name": "用户名",
          "email": "user@example.com"
        },
        "timezone": "Asia/Shanghai",
        "access_level": "owner",
        "color": "#1E88E5",
        "created_at": "2024-06-06T10:00:00Z",
        "updated_at": "2024-06-06T10:00:00Z"
      }
    ]
  }
}
```

### 2. 创建日程

**实现状态**: ✅ 已在 feishu-calendar.js 中实现
**测试状态**: ❌ 需要配置权限

```javascript
// 请求
POST /open-apis/calendar/v4/calendars/{calendar_id}/events

// 请求体
{
  "summary": "会议",
  "description": "项目讨论会议",
  "start_time": {
    "timestamp": 1717564800,
    "timezone": "Asia/Shanghai"
  },
  "end_time": {
    "timestamp": 1717568400,
    "timezone": "Asia/Shanghai"
  },
  "visibility": "default",
  "attendees": [],
  "reminders": []
}

// 响应
{
  "code": 0,
  "msg": "success",
  "data": {
    "event_id": "ev-xxxxxxxxxxxx",
    "calendar_id": "calendar_xxxxxxxxxx",
    "summary": "会议",
    "description": "项目讨论会议",
    "start_time": {
      "timestamp": 1717564800,
      "timezone": "Asia/Shanghai"
    },
    "end_time": {
      "timestamp": 1717568400,
      "timezone": "Asia/Shanghai"
    },
    "visibility": "default",
    "attendees": [],
    "organizer": {
      "user_id": "ou_xxxxxxxxxx",
      "name": "用户名",
      "email": "user@example.com"
    },
    "created_at": "2024-06-06T10:00:00Z",
    "updated_at": "2024-06-06T10:00:00Z"
  }
}
```

### 3. 获取日程列表

**实现状态**: ✅ 已在 feishu-calendar.js 中实现
**测试状态**: ❌ 需要配置权限

```javascript
// 请求
GET /open-apis/calendar/v4/calendars/{calendar_id}/events?start_time=1717564800&end_time=1717651200

// 响应
{
  "code": 0,
  "msg": "success",
  "data": {
    "events": [
      {
        "event_id": "ev-xxxxxxxxxxxx",
        "calendar_id": "calendar_xxxxxxxxxx",
        "summary": "会议",
        "description": "项目讨论会议",
        "start_time": {
          "timestamp": 1717564800,
          "timezone": "Asia/Shanghai"
        },
        "end_time": {
          "timestamp": 1717568400,
          "timezone": "Asia/Shanghai"
        },
        "visibility": "default",
        "attendees": [],
        "organizer": {
          "user_id": "ou_xxxxxxxxxx",
          "name": "用户名",
          "email": "user@example.com"
        },
        "created_at": "2024-06-06T10:00:00Z",
        "updated_at": "2024-06-06T10:00:00Z"
      }
    ],
    "has_more": false,
    "page_token": null
  }
}
```

### 4. 更新日程

**实现状态**: ✅ 已在 feishu-calendar.js 中实现
**测试状态**: ❌ 需要配置权限

```javascript
// 请求
PUT /open-apis/calendar/v4/calendars/{calendar_id}/events/{event_id}

// 请求体
{
  "summary": "更新后的会议标题",
  "description": "更新后的会议描述",
  "start_time": {
    "timestamp": 1717564800,
    "timezone": "Asia/Shanghai"
  },
  "end_time": {
    "timestamp": 1717568400,
    "timezone": "Asia/Shanghai"
  },
  "visibility": "default",
  "attendees": []
}

// 响应
{
  "code": 0,
  "msg": "success",
  "data": {
    "event_id": "ev-xxxxxxxxxxxx",
    "calendar_id": "calendar_xxxxxxxxxx",
    "summary": "更新后的会议标题",
    "description": "更新后的会议描述",
    "start_time": {
      "timestamp": 1717564800,
      "timezone": "Asia/Shanghai"
    },
    "end_time": {
      "timestamp": 1717568400,
      "timezone": "Asia/Shanghai"
    },
    "visibility": "default",
    "attendees": [],
    "organizer": {
      "user_id": "ou_xxxxxxxxxx",
      "name": "用户名",
      "email": "user@example.com"
    },
    "updated_at": "2024-06-06T10:00:00Z"
  }
}
```

### 5. 删除日程

**实现状态**: ✅ 已在 feishu-calendar.js 中实现
**测试状态**: ❌ 需要配置权限

```javascript
// 请求
DELETE /open-apis/calendar/v4/calendars/{calendar_id}/events/{event_id}

// 响应
{
  "code": 0,
  "msg": "success",
  "data": {}
}
```

---

## 📊 状态码说明

| 状态码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1 | 参数错误 |
| 2 | 权限不足 |
| 3 | 资源不存在 |
| 4 | 请求频率限制 |
| 5 | 服务器内部错误 |

---

## 🚨 错误处理

### 常见错误
1. **权限不足 (code: 2)**
   - 原因：未配置相关权限
   - 解决：配置相应的API权限
   - **当前状态**: ❌ 权限未配置

2. **资源不存在 (code: 3)**
   - 原因：日历ID或事件ID不存在
   - 解决：检查ID是否正确
   - **当前状态**: ⚠️ 待权限配置后测试

3. **请求频率限制 (code: 4)**
   - 原因：请求过于频繁
   - 解决：降低请求频率
   - **当前状态**: ⚠️ 待权限配置后测试

4. **参数错误 (code: 1)**
   - 原因：请求参数不正确
   - 解决：检查参数格式和内容
   - **当前状态**: ⚠️ 待权限配置后测试

### 已实现错误处理
- ✅ 日志记录功能
- ✅ 权限检查脚本
- ✅ 自动重试机制
- ✅ 状态监控

### 测试脚本
- ✅ feishu-calendar-test.js: 完整测试脚本
- ✅ feishu-calendar-minimal.js: 最小化脚本
- ✅ feishu-permission-check.js: 权限检查脚本

---

*数据结构文档更新完成*

**最后更新**: 2026-06-06 05:15:57
**版本**: v0.1.1
**维护者**: 小悟同学