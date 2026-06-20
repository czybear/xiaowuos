# xiaowuOS Service

xiaowuOS 服务端代码统一放在本目录。

当前能力：

- 使用 SQLite 保存课程数据
- 从 JSON / CSV / 后台 HTML 表格导入课程
- 提供只读课程 API，供 iOS App 后续读取
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
```

## 导入课程

支持三种输入：

- `.json`
- `.csv`
- `.html`，从后台复制或另存出的表格页面

示例：

```bash
python3 scripts/import_courses.py /path/to/courses.json
python3 scripts/import_courses.py /path/to/courses.csv
python3 scripts/import_courses.py /path/to/kecheng.html
```

## 科汛后台

课程后台地址：

```text
https://manage.keshij.cn/admin.php/kecheng/index.html
```

该页面当前会跳转登录页。自动导入需要以下任一方式：

- 后台导出 CSV / Excel / HTML 后交给导入脚本
- 提供一个有效后台登录态 Cookie 给 `scripts/fetch_keshij_courses.py`
- 后续接入正式后台 API

为了安全，服务端不会保存后台密码。
