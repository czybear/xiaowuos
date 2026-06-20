from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


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
