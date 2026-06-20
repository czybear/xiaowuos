from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable
from uuid import uuid4


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DB_PATH = DATA_DIR / "xiaowuos.sqlite3"
SCHEMA_PATH = ROOT / "xiaowuos" / "schema.sql"


def connect() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with connect() as conn:
        conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))


def upsert_courses(records: Iterable[dict], source: str) -> int:
    now = datetime.now(timezone.utc).isoformat()
    count = 0

    with connect() as conn:
        for record in records:
            external_id = str(record.get("external_id") or record.get("id") or record.get("title") or "").strip()
            title = str(record.get("title") or record.get("name") or "").strip()
            if not external_id and not title:
                continue
            if not external_id:
                external_id = title

            payload = {
                "external_id": external_id,
                "title": title or external_id,
                "category": record.get("category", ""),
                "teacher": record.get("teacher", "澄木老师"),
                "summary": record.get("summary", ""),
                "cover_url": record.get("cover_url", ""),
                "price": record.get("price", ""),
                "status": record.get("status", ""),
                "source": source,
                "raw_json": json.dumps(record.get("raw", record), ensure_ascii=False),
                "updated_at": now,
            }

            conn.execute(
                """
                INSERT INTO courses (
                    external_id, title, category, teacher, summary, cover_url,
                    price, status, source, raw_json, created_at, updated_at
                )
                VALUES (
                    :external_id, :title, :category, :teacher, :summary, :cover_url,
                    :price, :status, :source, :raw_json, :updated_at, :updated_at
                )
                ON CONFLICT(external_id) DO UPDATE SET
                    title = excluded.title,
                    category = excluded.category,
                    teacher = excluded.teacher,
                    summary = excluded.summary,
                    cover_url = excluded.cover_url,
                    price = excluded.price,
                    status = excluded.status,
                    source = excluded.source,
                    raw_json = excluded.raw_json,
                    updated_at = excluded.updated_at
                """,
                payload,
            )
            count += 1

        conn.commit()

    return count


def upsert_student_records(records: Iterable[dict], source: str) -> int:
    now = datetime.now(timezone.utc).isoformat()
    count = 0

    with connect() as conn:
        for record in records:
            external_id = str(record.get("external_id") or "").strip()
            if not external_id:
                continue

            payload = {
                "external_id": external_id,
                "student_name": record.get("student_name", ""),
                "phone": record.get("phone", ""),
                "course_title": record.get("course_title", ""),
                "teacher": record.get("teacher", "澄木老师"),
                "status": record.get("status", ""),
                "record_time": record.get("record_time", ""),
                "remark": record.get("remark", ""),
                "source": source,
                "raw_json": json.dumps(record.get("raw", record), ensure_ascii=False),
                "updated_at": now,
            }

            conn.execute(
                """
                INSERT INTO student_records (
                    external_id, student_name, phone, course_title, teacher,
                    status, record_time, remark, source, raw_json, created_at, updated_at
                )
                VALUES (
                    :external_id, :student_name, :phone, :course_title, :teacher,
                    :status, :record_time, :remark, :source, :raw_json, :updated_at, :updated_at
                )
                ON CONFLICT(external_id) DO UPDATE SET
                    student_name = excluded.student_name,
                    phone = excluded.phone,
                    course_title = excluded.course_title,
                    teacher = excluded.teacher,
                    status = excluded.status,
                    record_time = excluded.record_time,
                    remark = excluded.remark,
                    source = excluded.source,
                    raw_json = excluded.raw_json,
                    updated_at = excluded.updated_at
                """,
                payload,
            )
            count += 1

        conn.commit()

    return count


def list_courses() -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT external_id, title, category, teacher, summary, cover_url,
                   price, status, source, updated_at
            FROM courses
            ORDER BY updated_at DESC, title ASC
            """
        ).fetchall()
    return [dict(row) for row in rows]


def get_course(external_id: str) -> dict | None:
    with connect() as conn:
        row = conn.execute(
            """
            SELECT external_id, title, category, teacher, summary, cover_url,
                   price, status, source, raw_json, updated_at
            FROM courses
            WHERE external_id = ?
            """,
            (external_id,),
        ).fetchone()

    if row is None:
        return None

    course = dict(row)
    try:
        course["raw"] = json.loads(course.pop("raw_json") or "{}")
    except json.JSONDecodeError:
        course["raw"] = {}
    return course


def list_student_records() -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT external_id, student_name, phone, course_title, teacher,
                   status, record_time, remark, source, updated_at
            FROM student_records
            ORDER BY record_time DESC, updated_at DESC, student_name ASC
            """
        ).fetchall()
    return [dict(row) for row in rows]


def get_student_record(external_id: str) -> dict | None:
    with connect() as conn:
        row = conn.execute(
            """
            SELECT external_id, student_name, phone, course_title, teacher,
                   status, record_time, remark, source, raw_json, updated_at
            FROM student_records
            WHERE external_id = ?
            """,
            (external_id,),
        ).fetchone()

    if row is None:
        return None

    record = dict(row)
    try:
        record["raw"] = json.loads(record.pop("raw_json") or "{}")
    except json.JSONDecodeError:
        record["raw"] = {}
    return record


def seed_default_chat() -> None:
    now = datetime.now(timezone.utc).isoformat()
    with connect() as conn:
        existing = conn.execute("SELECT COUNT(*) FROM chat_conversations").fetchone()[0]
        if existing:
            return

        conn.execute(
            """
            INSERT INTO chat_conversations (
                id, title, kind, avatar_text, participants_json, openclaw_channel, created_at, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "teacher-room",
                "澄木老师答疑群",
                "group",
                "澄",
                json.dumps(
                    [
                        {"id": "teacher-chengmu", "name": "澄木老师", "role": "teacher"},
                        {"id": "student-demo", "name": "学员", "role": "student"},
                    ],
                    ensure_ascii=False,
                ),
                "openclaw://xiaowuos/teacher-room",
                now,
                now,
            ),
        )
        conn.execute(
            """
            INSERT INTO chat_messages (
                id, conversation_id, sender_id, sender_name, sender_role, body, message_type, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "welcome-teacher-room",
                "teacher-room",
                "teacher-chengmu",
                "澄木老师",
                "teacher",
                "欢迎来到小悟同学，这里会用于课程通知、作业交流和答疑。",
                "text",
                now,
            ),
        )
        conn.commit()


def list_chat_conversations() -> list[dict]:
    seed_default_chat()
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT
                c.id, c.title, c.kind, c.avatar_text, c.participants_json,
                c.openclaw_channel, c.updated_at,
                (
                    SELECT body FROM chat_messages m
                    WHERE m.conversation_id = c.id
                    ORDER BY m.created_at DESC
                    LIMIT 1
                ) AS last_message,
                (
                    SELECT created_at FROM chat_messages m
                    WHERE m.conversation_id = c.id
                    ORDER BY m.created_at DESC
                    LIMIT 1
                ) AS last_message_at
            FROM chat_conversations c
            ORDER BY COALESCE(last_message_at, c.updated_at) DESC
            """
        ).fetchall()

    conversations: list[dict] = []
    for row in rows:
        conversation = dict(row)
        conversation["participants"] = _decode_json_list(conversation.pop("participants_json"))
        conversations.append(conversation)
    return conversations


def list_chat_messages(conversation_id: str) -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT id, conversation_id, sender_id, sender_name, sender_role,
                   body, message_type, created_at
            FROM chat_messages
            WHERE conversation_id = ?
            ORDER BY created_at ASC
            """,
            (conversation_id,),
        ).fetchall()
    return [dict(row) for row in rows]


def create_chat_message(conversation_id: str, payload: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    message = {
        "id": str(payload.get("id") or uuid4()),
        "conversation_id": conversation_id,
        "sender_id": str(payload.get("sender_id") or "student-demo"),
        "sender_name": str(payload.get("sender_name") or "学员"),
        "sender_role": str(payload.get("sender_role") or "student"),
        "body": str(payload.get("body") or "").strip(),
        "message_type": str(payload.get("message_type") or "text"),
        "created_at": now,
    }
    if not message["body"]:
        raise ValueError("message body is required")

    with connect() as conn:
        conversation = conn.execute(
            "SELECT id FROM chat_conversations WHERE id = ?",
            (conversation_id,),
        ).fetchone()
        if conversation is None:
            raise LookupError("conversation not found")

        conn.execute(
            """
            INSERT INTO chat_messages (
                id, conversation_id, sender_id, sender_name, sender_role,
                body, message_type, created_at
            )
            VALUES (
                :id, :conversation_id, :sender_id, :sender_name, :sender_role,
                :body, :message_type, :created_at
            )
            """,
            message,
        )
        conn.execute(
            "UPDATE chat_conversations SET updated_at = ? WHERE id = ?",
            (now, conversation_id),
        )
        conn.commit()

    return message


def _decode_json_list(text: str) -> list[dict]:
    try:
        payload = json.loads(text or "[]")
    except json.JSONDecodeError:
        return []
    return payload if isinstance(payload, list) else []


def ops_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def list_ops_tasks() -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT id, title, command, target_node, status, source, dedupe_key,
                   created_at, updated_at
            FROM ops_tasks
            ORDER BY created_at DESC
            LIMIT 100
            """
        ).fetchall()
    return [dict(row) for row in rows]


def create_ops_task(payload: dict) -> dict:
    now = ops_now()
    title = str(payload.get("title") or payload.get("command") or "新任务").strip()
    command = str(payload.get("command") or "").strip()
    target_node = str(payload.get("target_node") or "xiaowuOSa").strip()
    dedupe_key = str(payload.get("dedupe_key") or f"{target_node}:{title}:{command}").strip()

    with connect() as conn:
        active_duplicate = conn.execute(
            """
            SELECT id, title, command, target_node, status, source, dedupe_key,
                   created_at, updated_at
            FROM ops_tasks
            WHERE dedupe_key = ? AND status IN ('queued', 'running')
            ORDER BY created_at DESC
            LIMIT 1
            """,
            (dedupe_key,),
        ).fetchone()
        if active_duplicate is not None:
            return dict(active_duplicate)

        task = {
            "id": str(uuid4()),
            "title": title,
            "command": command,
            "target_node": target_node,
            "status": "queued",
            "source": str(payload.get("source") or "ios"),
            "dedupe_key": dedupe_key,
            "created_at": now,
            "updated_at": now,
        }
        conn.execute(
            """
            INSERT INTO ops_tasks (
                id, title, command, target_node, status, source, dedupe_key,
                created_at, updated_at
            )
            VALUES (
                :id, :title, :command, :target_node, :status, :source,
                :dedupe_key, :created_at, :updated_at
            )
            """,
            task,
        )
        conn.execute(
            """
            INSERT INTO ops_logs (id, task_id, node_id, level, message, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (str(uuid4()), task["id"], target_node, "info", f"任务已入队：{title}", now),
        )
        conn.commit()
    return task


def list_ops_logs() -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT id, task_id, node_id, level, message, created_at
            FROM ops_logs
            ORDER BY created_at DESC
            LIMIT 200
            """
        ).fetchall()
    return [dict(row) for row in rows]


def record_ops_action(action: str, node_id: str = "xiaowuOSa", level: str = "info") -> dict:
    now = ops_now()
    log = {
        "id": str(uuid4()),
        "task_id": "",
        "node_id": node_id,
        "level": level,
        "message": action,
        "created_at": now,
    }
    with connect() as conn:
        conn.execute(
            """
            INSERT INTO ops_logs (id, task_id, node_id, level, message, created_at)
            VALUES (:id, :task_id, :node_id, :level, :message, :created_at)
            """,
            log,
        )
        conn.commit()
    return log
