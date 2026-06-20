# xiaowuOS Service

xiaowuOS 服务端代码统一放在本目录。

当前能力：

- 使用 SQLite 保存课程数据
- 使用 SQLite 保存学员记录数据
- 从 JSON / CSV / 后台 HTML 表格导入课程
- 从 JSON / CSV / TSV / TXT / 后台 HTML 表格导入学员记录
- 提供只读课程 API，供 iOS App 后续读取
- 提供只读学员记录 API，供 iOS App 后续读取
- 提供即时通讯会话和消息 API
- 预留 OpenClaw 实时通道连接配置
- 预留科汛后台课程页抓取入口

## 快速开始

初始化数据库：

```bash
python3 scripts/init_db.py
```

启动只读 API：

```bash
python3 app.py
```

默认监听：

```text
http://127.0.0.1:8765
```

## API

```text
GET /health
GET /api/courses
GET /api/courses/{id}
GET /api/student-records
GET /api/student-records/{id}
GET /api/chat/conversations
GET /api/chat/conversations/{id}/messages
POST /api/chat/conversations/{id}/messages
```

## 即时通讯

当前即时通讯先使用 SQLite 保存消息，HTTP API 读写。后续接 OpenClaw 时，可以通过环境变量配置服务端地址：

```bash
OPENCLAW_URL=http://127.0.0.1:9000 python3 app.py
```

消息发送示例：

```bash
curl -X POST http://127.0.0.1:8765/api/chat/conversations/teacher-room/messages \
  -H 'Content-Type: application/json' \
  -d '{"sender_id":"student-demo","sender_name":"学员","sender_role":"student","body":"老师好"}'
```

## 导入课程

支持多种输入：

- `.json`
- `.csv`
- `.tsv`
- `.txt`，从后台表格复制出来的文本
- `.html`，从后台复制或另存出的表格页面

示例：

```bash
python3 scripts/import_courses.py /path/to/courses.json
python3 scripts/import_courses.py /path/to/courses.csv
python3 scripts/import_courses.py /path/to/courses.txt
python3 scripts/import_courses.py /path/to/kecheng.html
```

导入学员记录：

```bash
python3 scripts/import_student_records.py /path/to/stu_record.csv
python3 scripts/import_student_records.py /path/to/stu_record.txt
python3 scripts/import_student_records.py /path/to/stu_record.html
```

## 科汛后台

课程后台地址：

```text
https://manage.keshij.cn/admin.php/kecheng/index.html
```

学员记录后台地址：

```text
https://manage.keshij.cn/admin.php/stu_record/index.html
```

该页面当前会跳转登录页。自动导入需要以下任一方式：

- 后台导出 CSV / Excel / HTML 后交给导入脚本
- 在后台课程列表全选复制，保存为 `.txt` 后交给导入脚本
- 提供一个有效后台登录态 Cookie 给 `scripts/fetch_keshij_courses.py`
- 后续接入正式后台 API

为了安全，服务端不会保存后台密码。
