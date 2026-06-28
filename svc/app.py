from __future__ import annotations

import html
import hashlib
import json
import mimetypes
import os
import sqlite3
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse

from xiaowuos import database


HOST = os.environ.get("XIAOWUOS_HOST", "0.0.0.0")
PORT = int(os.environ.get("XIAOWUOS_PORT", "8765"))
BASE_DIR = Path(__file__).resolve().parent
WEB_ROOT = BASE_DIR / "web"
GESP_TRIAL_USERS_PATH = BASE_DIR / "data" / "gesp_trial_users.json"


class XiaowuRequestHandler(BaseHTTPRequestHandler):
    server_version = "xiaowuOSCourseAPI/0.1"

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"

        if path == "/gesp/mock":
            self.send_static_file(WEB_ROOT / "gesp-mock" / "index.html")
            return

        if path.startswith("/gesp/mock/"):
            relative = path.removeprefix("/gesp/mock/") or "index.html"
            self.send_static_file(WEB_ROOT / "gesp-mock" / relative)
            return

        if path == "/api/gesp/trial-summary":
            self.send_json(load_gesp_trial_summary())
            return

        if path == "/health":
            self.send_json({
                "ok": True,
                "service": "xiaowuOS svc",
                "dashboard": {
                    "ok": True,
                    "source": "/health",
                    "note": "统一健康检查接口，避免 dashboard.html/dashboard.json 差异",
                },
                "openclaw": {
                    "enabled": bool(os.environ.get("OPENCLAW_URL")),
                    "url": os.environ.get("OPENCLAW_URL", ""),
                },
            })
            return

        if path in {"/admin/invite-codes/new", "/admin/invites"}:
            self.send_invite_form()
            return

        if path == "/admin/students":
            self.send_student_admin_page(parse_qs(parsed.query))
            return

        if path == "/api/courses":
            courses = database.list_courses()
            self.send_json({"items": courses, "count": len(courses)})
            return

        if path == "/api/student-records":
            query = parse_qs(parsed.query)
            filters = {
                "q": (query.get("q") or [""])[0],
                "course_title": (query.get("course_title") or [""])[0],
                "status": (query.get("status") or [""])[0],
                "source": (query.get("source") or [""])[0],
            }
            records = database.list_student_records(filters)
            self.send_json({
                "items": records,
                "count": len(records),
                "courses": database.list_student_course_titles(),
                "statuses": database.list_student_statuses(),
            })
            return

        if path == "/api/auth/me":
            token = self.bearer_token()
            if not token:
                self.send_json({"error": "missing bearer token"}, status=401)
                return
            member = database.get_member_by_token(token)
            if member is None:
                self.send_json({"error": "invalid or expired token"}, status=401)
                return
            self.send_json({"member": member})
            return

        if path == "/api/admin/members":
            if not self.is_admin_request():
                self.send_json({"error": "admin token required"}, status=401)
                return
            query = parse_qs(parsed.query)
            status = (query.get("status") or [""])[0]
            members = database.list_members(status=status or None)
            self.send_json({"items": members, "count": len(members)})
            return

        if path == "/api/admin/invite-codes":
            if not self.is_admin_request():
                self.send_json({"error": "admin token required"}, status=401)
                return
            query = parse_qs(parsed.query)
            status = (query.get("status") or [""])[0]
            invites = database.list_invite_codes(status=status or None)
            self.send_json({"items": invites, "count": len(invites)})
            return

        if path == "/api/chat/conversations":
            conversations = database.list_chat_conversations()
            self.send_json({"items": conversations, "count": len(conversations)})
            return

        if path == "/api/ops/nodes":
            self.send_json({
                "items": [
                    {
                        "id": "xiaowuOSa",
                        "role": "primary",
                        "status": "online",
                        "api_url": os.environ.get("XIAOWUOSA_API_URL", "http://johnonlife.com:60030"),
                        "ollama_url": os.environ.get("XIAOWUOSA_OLLAMA_URL", ""),
                        "note": "主控节点，负责队列、OpenClaw、dashboard、调度和主要服务",
                    },
                    {
                        "id": "xiaowuOSb",
                        "role": "backup-worker",
                        "status": "standby",
                        "api_url": os.environ.get("XIAOWUOSB_API_URL", ""),
                        "ollama_url": os.environ.get("XIAOWUOSB_OLLAMA_URL", ""),
                        "note": "备份/辅助执行节点，与 a 同步",
                    },
                    {
                        "id": "xiaowuOSc",
                        "role": "external",
                        "status": "limited",
                        "api_url": os.environ.get("XIAOWUOSC_API_URL", ""),
                        "ollama_url": os.environ.get("XIAOWUOSC_OLLAMA_URL", ""),
                        "note": "外部/云端/补充节点；c 可访问 a/b，a/b 不能稳定访问 c",
                    },
                ],
                "count": 3,
            })
            return

        if path == "/api/ops/dashboard":
            self.send_json({
                "ok": True,
                "status": "online",
                "gateway": os.environ.get("XIAOWUOS_GATEWAY_URL", "http://johnonlife.com:60030"),
                "health_endpoint": "/health",
                "loop_guard": "dedupe_key + queued/running 状态防重复入队",
            })
            return

        if path == "/api/ops/ollama":
            self.send_json({
                "items": [
                    {
                        "node_id": "xiaowuOSa",
                        "status": "configured" if os.environ.get("XIAOWUOSA_OLLAMA_URL") else "missing_config",
                        "url": os.environ.get("XIAOWUOSA_OLLAMA_URL", ""),
                        "note": "必须配置 Windows IP，不使用 127.0.0.1 或 localhost",
                    },
                    {
                        "node_id": "xiaowuOSb",
                        "status": "configured" if os.environ.get("XIAOWUOSB_OLLAMA_URL") else "missing_config",
                        "url": os.environ.get("XIAOWUOSB_OLLAMA_URL", ""),
                        "note": "必须配置 Windows IP，不使用 127.0.0.1 或 localhost",
                    },
                ],
                "count": 2,
            })
            return

        if path == "/api/ops/tasks":
            tasks = database.list_ops_tasks()
            self.send_json({"items": tasks, "count": len(tasks)})
            return

        if path == "/api/ops/logs":
            logs = database.list_ops_logs()
            self.send_json({"items": logs, "count": len(logs)})
            return

        if path.startswith("/api/chat/conversations/") and path.endswith("/messages"):
            conversation_id = unquote(path.removeprefix("/api/chat/conversations/").removesuffix("/messages"))
            messages = database.list_chat_messages(conversation_id)
            self.send_json({"items": messages, "count": len(messages)})
            return

        if path.startswith("/api/courses/"):
            course_id = unquote(path.removeprefix("/api/courses/"))
            course = database.get_course(course_id)
            if course is None:
                self.send_json({"error": "course not found"}, status=404)
                return
            self.send_json(course)
            return

        if path.startswith("/api/student-records/"):
            record_id = unquote(path.removeprefix("/api/student-records/"))
            record = database.get_student_record(record_id)
            if record is None:
                self.send_json({"error": "student record not found"}, status=404)
                return
            self.send_json(record)
            return

        self.send_json({"error": "not found"}, status=404)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"

        if path in {"/admin/invite-codes/new", "/admin/invites"}:
            payload = self.read_form_body()
            if not self.is_admin_token(payload.get("admin_token", "")):
                self.send_html("<h1>需要管理员口令</h1>", status=401)
                return
            try:
                invite = database.create_invite_code(payload)
            except (ValueError, sqlite3.IntegrityError) as error:
                self.send_html(f"<h1>生成失败</h1><p>{html.escape(str(error))}</p>", status=400)
                return
            self.send_invite_form(invite=invite)
            return

        if path == "/api/auth/request-code":
            try:
                payload = self.read_json_body()
                result = database.request_official_account_code(payload)
            except ValueError as error:
                self.send_json({"error": str(error)}, status=400)
                return
            self.send_json(result, status=202)
            return

        if path == "/api/auth/register":
            try:
                payload = self.read_json_body()
                result = database.register_with_official_account_code(payload)
            except ValueError as error:
                self.send_json({"error": str(error)}, status=400)
                return
            except PermissionError as error:
                self.send_json({"error": str(error)}, status=401)
                return
            self.send_json(result, status=201)
            return

        if path == "/api/auth/login":
            try:
                payload = self.read_json_body()
                result = database.login_with_official_account_code(payload)
            except ValueError as error:
                self.send_json({"error": str(error)}, status=400)
                return
            except PermissionError as error:
                self.send_json({"error": str(error)}, status=403)
                return
            self.send_json(result, status=200)
            return

        if path == "/api/auth/invite-register":
            try:
                payload = self.read_json_body()
                result = database.register_with_invite(payload)
            except ValueError as error:
                self.send_json({"error": str(error)}, status=400)
                return
            except PermissionError as error:
                self.send_json({"error": str(error)}, status=403)
                return
            self.send_json(result, status=201)
            return

        if path == "/api/auth/device-login":
            try:
                payload = self.read_json_body()
                result = database.login_with_device(payload)
            except ValueError as error:
                self.send_json({"error": str(error)}, status=400)
                return
            except PermissionError as error:
                self.send_json({"error": str(error)}, status=403)
                return
            self.send_json(result, status=200)
            return

        if path == "/api/admin/invite-codes":
            if not self.is_admin_request():
                self.send_json({"error": "admin token required"}, status=401)
                return
            try:
                payload = self.read_json_body()
                invite = database.create_invite_code(payload)
            except (ValueError, sqlite3.IntegrityError) as error:
                self.send_json({"error": str(error)}, status=400)
                return
            self.send_json({"invite": invite}, status=201)
            return

        if path.startswith("/api/admin/members/") and path.endswith("/approve"):
            if not self.is_admin_request():
                self.send_json({"error": "admin token required"}, status=401)
                return
            member_id = unquote(path.removeprefix("/api/admin/members/").removesuffix("/approve"))
            try:
                member = database.review_member(member_id, approved=True)
            except LookupError as error:
                self.send_json({"error": str(error)}, status=404)
                return
            self.send_json({"member": member})
            return

        if path.startswith("/api/admin/members/") and path.endswith("/reject"):
            if not self.is_admin_request():
                self.send_json({"error": "admin token required"}, status=401)
                return
            member_id = unquote(path.removeprefix("/api/admin/members/").removesuffix("/reject"))
            try:
                member = database.review_member(member_id, approved=False)
            except LookupError as error:
                self.send_json({"error": str(error)}, status=404)
                return
            self.send_json({"member": member})
            return

        if path.startswith("/api/chat/conversations/") and path.endswith("/messages"):
            conversation_id = unquote(path.removeprefix("/api/chat/conversations/").removesuffix("/messages"))
            try:
                payload = self.read_json_body()
                message = database.create_chat_message(conversation_id, payload)
            except LookupError:
                self.send_json({"error": "conversation not found"}, status=404)
                return
            except ValueError as error:
                self.send_json({"error": str(error)}, status=400)
                return
            self.send_json(message, status=201)
            return

        if path == "/api/ops/tasks":
            payload = self.read_json_body()
            task = database.create_ops_task(payload)
            self.send_json(task, status=201)
            return

        if path == "/api/openclaw/messages":
            payload = self.read_json_body()
            message = str(payload.get("message") or "").strip()
            if not message:
                self.send_json({"error": "message is required"}, status=400)
                return
            target_node = str(payload.get("target_node") or "xiaowuOSa").strip()
            channel = str(payload.get("channel") or "xiaowuOS-app").strip()
            digest = hashlib.sha256(f"{target_node}:{channel}:{message}".encode("utf-8")).hexdigest()[:16]
            task_payload = {
                "title": f"OpenClaw 输入：{message[:24]}",
                "command": "openclaw.dispatch " + json.dumps({
                    "channel": channel,
                    "message": message,
                    "source": payload.get("source") or "xiaowuOS-app",
                }, ensure_ascii=False),
                "target_node": target_node,
                "source": payload.get("source") or "xiaowuOS-app",
                "dedupe_key": f"openclaw:{digest}",
            }
            task = database.create_ops_task(task_payload)
            self.send_json({
                "accepted": True,
                "channel": channel,
                "target_node": target_node,
                "task": task,
            }, status=202)
            return

        if path == "/api/gesp/trial-login":
            payload = self.read_json_body()
            username = str(payload.get("username") or "").strip()
            password = str(payload.get("password") or "").strip()
            system = str(payload.get("system") or "code").strip()
            account = authenticate_gesp_scratch_user(username, password) if system == "scratch" else authenticate_gesp_trial_user(username, password)
            if account is None:
                self.send_json({"error": "用户名或密码不正确"}, status=401)
                return
            language = account.get("language", "")
            if system == "code" and language not in {"C++", "Python"}:
                self.send_json({"error": "该账号不是 C++ / Python 编程模拟系统账号"}, status=403)
                return
            token_payload = f"{username}:{language}:{account.get('level', '')}:{int(time.time())}"
            token = hashlib.sha256(token_payload.encode("utf-8")).hexdigest()[:32]
            self.send_json({
                "token": token,
                "account": {
                    "username": username,
                    "name": account.get("name", ""),
                    "language": language,
                    "level": account.get("level", ""),
                    "system": system,
                },
            })
            return

        if path == "/api/ops/sync":
            payload = self.read_json_body()
            node_id = str(payload.get("node_id") or "xiaowuOSb")
            log = database.record_ops_action(f"手动触发同步：{node_id}", node_id=node_id)
            self.send_json({"accepted": True, "log": log}, status=202)
            return

        if path == "/api/ops/restart":
            payload = self.read_json_body()
            service = str(payload.get("service") or "dashboard")
            node_id = str(payload.get("node_id") or "xiaowuOSa")
            if service not in {"dashboard", "worker"}:
                self.send_json({"error": "service must be dashboard or worker"}, status=400)
                return
            log = database.record_ops_action(f"手动重启请求：{service}", node_id=node_id)
            self.send_json({"accepted": True, "service": service, "node_id": node_id, "log": log}, status=202)
            return

        self.send_json({"error": "not found"}, status=404)

    def log_message(self, format: str, *args: object) -> None:
        return

    def send_json(self, payload: dict | list, status: int = 200) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_html(self, body: str, status: int = 200) -> None:
        payload = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def send_static_file(self, file_path: Path) -> None:
        try:
            resolved = file_path.resolve()
            root = WEB_ROOT.resolve()
        except FileNotFoundError:
            self.send_json({"error": "not found"}, status=404)
            return

        if root not in resolved.parents and resolved != root:
            self.send_json({"error": "forbidden"}, status=403)
            return
        if not resolved.is_file():
            self.send_json({"error": "not found"}, status=404)
            return

        content_type = mimetypes.guess_type(str(resolved))[0] or "application/octet-stream"
        payload = resolved.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def send_invite_form(self, invite: dict | None = None) -> None:
        result = ""
        if invite is not None:
            result = f"""
            <section class='result'>
              <div>邀请码</div>
              <strong>{html.escape(invite.get('code', ''))}</strong>
              <p>{html.escape(invite.get('student_name') or invite.get('label') or '已生成')}</p>
            </section>
            """
        self.send_html(f"""
        <!doctype html>
        <html lang='zh-CN'>
        <head>
          <meta charset='utf-8'>
          <meta name='viewport' content='width=device-width, initial-scale=1'>
          <title>小悟同学邀请码</title>
          <style>
            body {{ margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif; background: #f6f6f8; color: #1f1f1f; }}
            main {{ max-width: 720px; margin: 0 auto; padding: 40px 18px; }}
            h1 {{ font-size: 34px; margin: 0 0 8px; }}
            p {{ color: #777; line-height: 1.6; }}
            form, .result {{ background: #fff; border-radius: 8px; padding: 22px; margin-top: 18px; }}
            label {{ display: block; font-size: 13px; color: #777; margin: 14px 0 7px; }}
            input, select, textarea {{ width: 100%; box-sizing: border-box; border: 0; background: #f0f0f4; border-radius: 8px; padding: 13px; font-size: 16px; }}
            textarea {{ min-height: 92px; resize: vertical; }}
            button {{ margin-top: 18px; width: 100%; border: 0; border-radius: 8px; padding: 15px; font-size: 17px; font-weight: 700; background: #ff9500; color: white; }}
            strong {{ display: block; font-size: 28px; letter-spacing: 1px; margin-top: 8px; }}
          </style>
        </head>
        <body>
          <main>
            <h1>小悟同学</h1>
            <p>生成邀请码，记录学员和设备信息。邀请码用于首次登录并绑定设备。</p>
            {result}
            <form method='post'>
              <label>管理员口令</label><input name='admin_token' value='dev-admin-token' autocomplete='off'>
              <label>手机号</label><input name='phone' inputmode='numeric' placeholder='学员手机号'>
              <label>学员姓名</label><input name='student_name' placeholder='学员姓名'>
              <label>手机串号 / 设备标识</label><input name='device_serial' placeholder='可先手动记录'>
              <label>渠道</label><select name='source'><option value='direct'>自招会员</option><option value='joint'>联招会员</option><option value='channel'>渠道会员</option><option value='school'>校区会员</option><option value='staff'>内部会员</option></select>
              <label>备注</label><textarea name='note' placeholder='课程、家长、来源等'></textarea>
              <button type='submit'>生成邀请码</button>
            </form>
          </main>
        </body>
        </html>
        """)

    def send_student_admin_page(self, query: dict[str, list[str]]) -> None:
        filters = {
            "q": (query.get("q") or [""])[0],
            "course_title": (query.get("course_title") or [""])[0],
            "status": (query.get("status") or [""])[0],
            "source": (query.get("source") or [""])[0],
        }
        records = database.list_student_records(filters)
        courses = database.list_student_course_titles()
        statuses = database.list_student_statuses()

        def selected(value: str, current: str) -> str:
            return " selected" if value == current else ""

        course_options = "".join(
            f"<option value='{html.escape(course)}'{selected(course, filters['course_title'])}>{html.escape(course)}</option>"
            for course in courses
        )
        status_options = "".join(
            f"<option value='{html.escape(status)}'{selected(status, filters['status'])}>{html.escape(status)}</option>"
            for status in statuses
        )
        rows = "".join(self.student_row_html(record) for record in records)
        self.send_html(f"""
        <!doctype html>
        <html lang='zh-CN'>
        <head>
          <meta charset='utf-8'>
          <meta name='viewport' content='width=device-width, initial-scale=1'>
          <title>小悟同学学员管理</title>
          <style>
            body {{ margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif; background: #f6f6f8; color: #1f1f1f; }}
            main {{ max-width: 1180px; margin: 0 auto; padding: 34px 18px; }}
            h1 {{ font-size: 34px; margin: 0 0 6px; }}
            p {{ color: #777; line-height: 1.6; }}
            form {{ display: grid; grid-template-columns: 1.2fr 1.6fr 1fr auto auto; gap: 10px; margin: 22px 0; }}
            input, select, button, a.button {{ box-sizing: border-box; border: 0; border-radius: 8px; padding: 12px 13px; font-size: 15px; }}
            input, select {{ background: #fff; }}
            button, a.button {{ background: #ff9500; color: white; font-weight: 700; text-decoration: none; text-align: center; }}
            a.secondary {{ background: #e9e9ee; color: #333; }}
            table {{ width: 100%; border-collapse: collapse; background: #fff; border-radius: 8px; overflow: hidden; }}
            th, td {{ text-align: left; padding: 13px 12px; border-bottom: 1px solid #eee; vertical-align: top; font-size: 14px; }}
            th {{ color: #777; font-weight: 600; background: #fbfbfd; }}
            tr:last-child td {{ border-bottom: 0; }}
            .muted {{ color: #888; font-size: 12px; }}
            .actions span {{ display: inline-block; color: #ff9500; margin-right: 10px; white-space: nowrap; }}
            @media (max-width: 760px) {{
              form {{ grid-template-columns: 1fr; }}
              table, thead, tbody, tr, th, td {{ display: block; }}
              thead {{ display: none; }}
              tr {{ margin-bottom: 12px; border-radius: 8px; background: #fff; overflow: hidden; }}
              td {{ border-bottom: 1px solid #eee; }}
              td:before {{ content: attr(data-label); display: block; color: #888; font-size: 12px; margin-bottom: 4px; }}
            }}
          </style>
        </head>
        <body>
          <main>
            <h1>学员管理</h1>
            <p>参考课时记，先保留学员列表、课程班级、课时、积分、绑定状态和最近上课时间。当前共 {len(records)} 条。</p>
            <form method='get'>
              <input name='q' value='{html.escape(filters['q'])}' placeholder='搜索学员 / 班级 / 状态'>
              <select name='course_title'><option value=''>全部班级</option>{course_options}</select>
              <select name='status'><option value=''>全部绑定状态</option>{status_options}</select>
              <button type='submit'>筛选</button>
              <a class='button secondary' href='/admin/students'>重置</a>
            </form>
            <table>
              <thead>
                <tr><th>学员</th><th>班级</th><th>绑定状态</th><th>最新上课</th><th>课时 / 积分</th><th>操作</th></tr>
              </thead>
              <tbody>{rows}</tbody>
            </table>
          </main>
        </body>
        </html>
        """)

    def student_row_html(self, record: dict) -> str:
        return f"""
        <tr>
          <td data-label='学员'><strong>{html.escape(record.get('student_name') or '未命名')}</strong><div class='muted'>{html.escape(record.get('phone') or '')}</div></td>
          <td data-label='班级'>{html.escape(record.get('course_title') or '')}</td>
          <td data-label='绑定状态'>{html.escape(record.get('status') or '')}</td>
          <td data-label='最新上课'>{html.escape(record.get('record_time') or '')}</td>
          <td data-label='课时 / 积分'>{html.escape(record.get('remark') or '')}</td>
          <td data-label='操作' class='actions'><span>编辑</span><span>缴费</span><span>调班</span><span>打卡记录</span><span>请假记录</span></td>
        </tr>
        """

    def read_form_body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}
        body = self.rfile.read(length).decode("utf-8")
        values = parse_qs(body, keep_blank_values=True)
        payload = {key: value[-1] if value else "" for key, value in values.items()}
        payload["label"] = payload.get("student_name") or payload.get("phone") or "邀请码"
        payload["max_uses"] = 1
        payload["member_level"] = "course"
        return payload

    def read_json_body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}
        body = self.rfile.read(length).decode("utf-8")
        payload = json.loads(body or "{}")
        if not isinstance(payload, dict):
            raise ValueError("JSON body must be an object")
        return payload

    def bearer_token(self) -> str:
        authorization = self.headers.get("Authorization", "")
        prefix = "Bearer "
        if not authorization.startswith(prefix):
            return ""
        return authorization[len(prefix):].strip()

    def is_admin_request(self) -> bool:
        return self.is_admin_token(self.headers.get("X-Admin-Token", ""))

    def is_admin_token(self, token: str) -> bool:
        expected = os.environ.get("XIAOWUOS_ADMIN_TOKEN", "dev-admin-token")
        return token == expected


def main() -> None:
    database.init_db()
    database.seed_default_chat()
    db_path = Path(database.DB_PATH).resolve()
    display_host = "127.0.0.1" if HOST == "0.0.0.0" else HOST
    print(f"xiaowuOS svc listening on http://{display_host}:{PORT}")
    if HOST == "0.0.0.0":
        print(f"LAN access: http://<your-mac-lan-ip>:{PORT}")
    print(f"SQLite database: {db_path}")
    ThreadingHTTPServer((HOST, PORT), XiaowuRequestHandler).serve_forever()


def load_gesp_trial_users() -> list[dict]:
    if not GESP_TRIAL_USERS_PATH.exists():
        return []
    payload = json.loads(GESP_TRIAL_USERS_PATH.read_text(encoding="utf-8"))
    items = payload.get("items", [])
    return items if isinstance(items, list) else []


def load_gesp_trial_summary() -> dict:
    users = load_gesp_trial_users()
    summary: dict[str, dict[str, int]] = {}
    for user in users:
        language = str(user.get("language") or "未知")
        level = str(user.get("level") or "未知")
        summary.setdefault(language, {})
        summary[language][level] = summary[language].get(level, 0) + 1
    return {
        "count": len(users),
        "summary": summary,
        "systems": [
            {"id": "code", "title": "C++、Python 编程模拟系统"},
            {"id": "scratch", "title": "图形化编程模拟系统"},
        ],
    }


def authenticate_gesp_trial_user(username: str, password: str) -> dict | None:
    if not username or not password:
        return None
    for user in load_gesp_trial_users():
        if user.get("username") == username and user.get("password") == password:
            return user
    return None


def authenticate_gesp_scratch_user(username: str, password: str) -> dict | None:
    scratch_code = os.environ.get("GESP_SCRATCH_TRIAL_CODE", "062234")
    if password != scratch_code:
        return None
    return {
        "username": username or scratch_code,
        "password": "",
        "name": "图形化试机用户",
        "language": "图形化",
        "level": "1",
    }


if __name__ == "__main__":
    main()
