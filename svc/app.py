from __future__ import annotations

import json
import sqlite3
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
            self.send_json({"ok": True, "service": "xiaowuOS svc"})
            return

        if path == "/api/courses":
            courses = database.list_courses()
            self.send_json({"items": courses, "count": len(courses)})
            return

        if path.startswith("/api/courses/"):
            course_id = unquote(path.removeprefix("/api/courses/"))
            course = database.get_course(course_id)
            if course is None:
                self.send_json({"error": "course not found"}, status=404)
                return
            self.send_json(course)
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


def main() -> None:
    database.init_db()
    db_path = Path(database.DB_PATH).resolve()
    print(f"xiaowuOS svc listening on http://{HOST}:{PORT}")
    print(f"SQLite database: {db_path}")
    ThreadingHTTPServer((HOST, PORT), XiaowuRequestHandler).serve_forever()


if __name__ == "__main__":
    main()
