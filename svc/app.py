from __future__ import annotations

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

from xiaowuos import database


HOST = "127.0.0.1"
PORT = 8765


class XiaowuRequestHandler(BaseHTTPRequestHandler):
    server_version = "xiaowuOSCourseAPI/0.1"

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"

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

        if path == "/api/courses":
            courses = database.list_courses()
            self.send_json({"items": courses, "count": len(courses)})
            return

        if path == "/api/student-records":
            records = database.list_student_records()
            self.send_json({"items": records, "count": len(records)})
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

    def read_json_body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}
        body = self.rfile.read(length).decode("utf-8")
        payload = json.loads(body or "{}")
        if not isinstance(payload, dict):
            raise ValueError("JSON body must be an object")
        return payload


def main() -> None:
    database.init_db()
    database.seed_default_chat()
    db_path = Path(database.DB_PATH).resolve()
    print(f"xiaowuOS svc listening on http://{HOST}:{PORT}")
    print(f"SQLite database: {db_path}")
    ThreadingHTTPServer((HOST, PORT), XiaowuRequestHandler).serve_forever()


if __name__ == "__main__":
    main()
