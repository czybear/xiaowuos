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
- 提供公众号验证码注册 / 登录 API
- 提供邀请码注册、渠道归属、首次设备绑定和认证设备自动登录 API
- 预留 OpenClaw 实时通道连接配置
- 预留科汛后台课程页抓取入口
- 提供 GESP 模拟考试练习网页
- 提供 GESP 试机账号登录与 C++/Python、图形化模拟考试复刻入口
- 提供 GESP 官方测试页面原型截图留档与本地复刻页面截图留档脚本

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
POST /api/auth/request-code
POST /api/auth/register
POST /api/auth/login
POST /api/auth/invite-register
POST /api/auth/device-login
GET /api/auth/me
GET /api/admin/members
POST /api/admin/members/{id}/approve
POST /api/admin/members/{id}/reject
GET /api/admin/invite-codes
POST /api/admin/invite-codes
GET /api/chat/conversations
GET /api/chat/conversations/{id}/messages
POST /api/chat/conversations/{id}/messages
POST /api/openclaw/messages
GET /gesp/mock
GET /api/gesp/trial-summary
POST /api/gesp/trial-login
```

## GESP 试机模拟系统

本服务内置一个 xiaowuOS 练习版 GESP 试机模拟系统，用于课堂练习和考前熟悉流程。页面包含：

- 试机账号登录
- C++、Python 编程模拟系统入口
- 图形化编程模拟系统入口
- 考试列表、考生信息、倒计时、题号导航
- 客观题、代码作答区、图形化舞台和积木作答区
- 本地评分与结果页

```text
http://127.0.0.1:8765/gesp/mock
```

导入试机账号：

```bash
python3 scripts/import_gesp_trial_users.py "/path/to/CCF GESP 2026年6月认证 - 试机用户.xlsx"
```

试机账号会写入 `data/gesp_trial_users.json`。该文件包含明文试机密码，已加入 `.gitignore`，不要提交到 GitHub。

图形化编程模拟系统入口参考：

```text
https://ccf.scratchoj.com/examv/#/
```

当前本地复刻版图形化试机码：

```text
用户名：062234
密码：062234
```

说明：这是 xiaowuOS 内部练习版，不代表 CCF/GESP 官方考试系统。当前题目为示例题，后续可接 SQLite 题库、导入真题资料或接在线评测服务。

页面原型留档：

```text
docs/gesp-reference/ 官方测试系统截图留档
docs/gesp-local/     xiaowuOS 本地复刻原型截图
```

截图脚本：

```bash
node scripts/capture_gesp_reference.js
node scripts/capture_gesp_logged_in.js
node scripts/capture_gesp_local.js
```

## OpenClaw App 输入通道

iOS App 的“联接小悟”先通过 API Gateway 将消息写入任务队列，worker 后续可消费 `openclaw.dispatch` 命令并转发给 xiaowuOSa / b / c 上的 OpenClaw。

```bash
curl -X POST http://127.0.0.1:8765/api/openclaw/messages \
  -H 'Content-Type: application/json' \
  -d '{"target_node":"xiaowuOSa","channel":"xiaowuOS-app","message":"帮我查看今天的任务队列"}'
```

## 邀请码注册与设备绑定

当前 V0.1 主线先不用短信验证码和公众号自动验证码。管理员先创建邀请码，邀请码携带渠道来源等信息；用户首次用邀请码注册时自动绑定当前设备。后续同一认证设备可以自动登录，非认证设备禁止登录。

管理员创建邀请码：

```bash
curl -X POST http://127.0.0.1:8765/api/admin/invite-codes \
  -H 'X-Admin-Token: dev-admin-token' \
  -H 'Content-Type: application/json' \
  -d '{"code":"JOHN2026","label":"澄木老师首批测试学员","phone":"18012345678","student_name":"小羽同学","source":"direct","member_level":"course","max_uses":1}'
```

用户首次注册并绑定设备：

```bash
curl -X POST http://127.0.0.1:8765/api/auth/invite-register \
  -H 'Content-Type: application/json' \
  -d '{"phone":"18012345678","display_name":"小羽同学","invite_code":"JOHN2026","device_id":"ipad4mia-device-id","device_name":"iPad4Mia","platform":"ios"}'
```

认证设备自动登录：

```bash
curl -X POST http://127.0.0.1:8765/api/auth/device-login \
  -H 'Content-Type: application/json' \
  -d '{"phone":"18012345678","device_id":"ipad4mia-device-id","device_name":"iPad4Mia","platform":"ios"}'
```

## 公众号验证码注册

这是保留方案，不再作为当前主线。当前先打通服务端闭环：验证码写入 SQLite，并在开发阶段返回 `dev_code` 方便测试。正式接入微信公众号后，验证码会通过公众号“陈忠勇John”发送，接口不再返回明文验证码。

会员注册后默认是 `pending_review`，必须管理员审核通过为 `active` 后才可以登录获取 token。

请求验证码：

```bash
curl -X POST http://127.0.0.1:8765/api/auth/request-code \
  -H 'Content-Type: application/json' \
  -d '{"phone":"13800138000","purpose":"register"}'
```

提交注册：

```bash
curl -X POST http://127.0.0.1:8765/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"phone":"13800138000","code":"000000","device_name":"iPad4Mia"}'
```

管理员查看待审核会员：

```bash
curl http://127.0.0.1:8765/api/admin/members?status=pending_review \
  -H 'X-Admin-Token: dev-admin-token'
```

管理员审核通过：

```bash
curl -X POST http://127.0.0.1:8765/api/admin/members/phone-13800138000/approve \
  -H 'X-Admin-Token: dev-admin-token'
```

审核通过后登录：

```bash
curl -X POST http://127.0.0.1:8765/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"phone":"13800138000","code":"000000","device_name":"iPad4Mia"}'
```

获取当前会员：

```bash
curl http://127.0.0.1:8765/api/auth/me \
  -H 'Authorization: Bearer <token>'
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

## 首批课时记数据导入建议

第一批学员数据先从课时记后台导入：

```text
https://manage.keshij.cn/admin.php/kecheng/index.html
```

推荐顺序：

1. 导入课程列表。
2. 导入学员记录。
3. 按手机号、学员姓名、渠道和备注生成邀请码。
4. 学员首次用手机号 + 邀请码登录时绑定设备。

如果后台支持导出 CSV，优先使用 CSV：

```bash
python3 scripts/import_courses.py /path/to/kecheng.csv --source-name keshij-admin
python3 scripts/import_student_records.py /path/to/stu_record.csv --source-name keshij-stu-record
```

如果后台只能复制表格，则把表格复制保存为 `.txt`：

```bash
python3 scripts/import_courses.py /path/to/kecheng.txt --source-name keshij-admin
python3 scripts/import_student_records.py /path/to/stu_record.txt --source-name keshij-stu-record
```

自动读取 Chrome 当前后台页面时，如果 Chrome 拦截 JavaScript Apple Events，需要在 Chrome 菜单栏打开：

```text
View > Developer > Allow JavaScript from Apple Events
```
