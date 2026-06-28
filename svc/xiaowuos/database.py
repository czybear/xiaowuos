from __future__ import annotations

import json
import hashlib
import secrets
import sqlite3
from datetime import datetime, timedelta, timezone
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
        _ensure_schema_migrations(conn)


def _ensure_schema_migrations(conn: sqlite3.Connection) -> None:
    existing_columns = {row[1] for row in conn.execute("PRAGMA table_info(invite_codes)").fetchall()}
    for column in ("phone", "student_name", "device_serial", "note"):
        if column not in existing_columns:
            conn.execute(f"ALTER TABLE invite_codes ADD COLUMN {column} TEXT NOT NULL DEFAULT ''")
    conn.commit()


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _utc_now_text() -> str:
    return _utc_now().isoformat()


def _hash_secret(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _normalize_phone(phone: object) -> str:
    return "".join(ch for ch in str(phone or "") if ch.isdigit())


def is_valid_phone(phone: str) -> bool:
    return len(phone) == 11 and phone.startswith("1") and phone.isdigit()


def _normalize_invite_code(code: object) -> str:
    return str(code or "").strip().upper().replace(" ", "").replace("-", "")


def _require_device_id(payload: dict) -> str:
    device_id = str(payload.get("device_id") or "").strip()
    if len(device_id) < 8:
        raise ValueError("device_id is required")
    return device_id


def create_invite_code(payload: dict) -> dict:
    now = _utc_now_text()
    raw_code = _normalize_invite_code(payload.get("code"))
    if not raw_code:
        raw_code = secrets.token_urlsafe(14).replace("_", "").replace("-", "")[:16].upper()

    invite = {
        "id": str(uuid4()),
        "code_hash": _hash_secret(raw_code),
        "label": str(payload.get("label") or ""),
        "phone": _normalize_phone(payload.get("phone")),
        "student_name": str(payload.get("student_name") or ""),
        "device_serial": str(payload.get("device_serial") or ""),
        "note": str(payload.get("note") or ""),
        "source": str(payload.get("source") or "direct"),
        "member_level": str(payload.get("member_level") or "course"),
        "course_tracks_json": json.dumps(payload.get("course_tracks") or [], ensure_ascii=False),
        "max_uses": max(1, int(payload.get("max_uses") or 1)),
        "used_count": 0,
        "status": "active",
        "expires_at": str(payload.get("expires_at") or ""),
        "created_at": now,
        "updated_at": now,
    }
    with connect() as conn:
        conn.execute(
            """
            INSERT INTO invite_codes (
                id, code_hash, label, phone, student_name, device_serial, note,
                source, member_level, course_tracks_json, max_uses, used_count,
                status, expires_at, created_at, updated_at
            )
            VALUES (
                :id, :code_hash, :label, :phone, :student_name, :device_serial, :note,
                :source, :member_level, :course_tracks_json, :max_uses, :used_count,
                :status, :expires_at, :created_at, :updated_at
            )
            """,
            invite,
        )
        conn.commit()

    result = serialize_invite_code(invite)
    result["code"] = raw_code
    return result


def list_invite_codes(status: str | None = None) -> list[dict]:
    params: tuple[str, ...] = ()
    where = ""
    if status:
        where = "WHERE status = ?"
        params = (status,)
    with connect() as conn:
        rows = conn.execute(
            f"""
            SELECT id, label, phone, student_name, device_serial, note, source,
                   member_level, course_tracks_json, max_uses, used_count, status,
                   expires_at, created_at, updated_at
            FROM invite_codes
            {where}
            ORDER BY created_at DESC
            LIMIT 200
            """,
            params,
        ).fetchall()
    return [serialize_invite_code(dict(row)) for row in rows]


def register_with_invite(payload: dict) -> dict:
    phone = _normalize_phone(payload.get("phone"))
    invite_code = _normalize_invite_code(payload.get("invite_code"))
    device_id = _require_device_id(payload)
    if not is_valid_phone(phone):
        raise ValueError("phone must be an 11 digit mainland China mobile number")
    if not invite_code:
        raise ValueError("invite_code is required")

    now = _utc_now_text()
    with connect() as conn:
        invite = conn.execute(
            """
            SELECT id, label, phone, student_name, device_serial, note, source,
                   member_level, course_tracks_json, max_uses, used_count, status,
                   expires_at, created_at, updated_at
            FROM invite_codes
            WHERE code_hash = ?
            LIMIT 1
            """,
            (_hash_secret(invite_code),),
        ).fetchone()
        if invite is None:
            raise PermissionError("invalid invite code")

        invite_dict = dict(invite)
        _validate_invite(invite_dict)

        existing = _get_member_row_by_phone(conn, phone)
        if existing is None:
            display_name = str(payload.get("display_name") or f"手机用户 {phone[-4:]}").strip()
            member = {
                "id": f"phone-{phone}",
                "phone": phone,
                "display_name": display_name,
                "avatar_initials": str(payload.get("avatar_initials") or "小悟")[:4],
                "provider": "invite_code",
                "member_level": invite_dict["member_level"],
                "source": invite_dict["source"],
                "vip_level": int(payload.get("vip_level") or 0),
                "growth_points": int(payload.get("growth_points") or 0),
                "status": "active",
                "joined_at": now,
                "updated_at": now,
            }
            conn.execute(
                """
                INSERT INTO members (
                    id, phone, display_name, avatar_initials, provider, member_level,
                    source, vip_level, growth_points, status, joined_at, updated_at
                )
                VALUES (
                    :id, :phone, :display_name, :avatar_initials, :provider, :member_level,
                    :source, :vip_level, :growth_points, :status, :joined_at, :updated_at
                )
                """,
                member,
            )
            conn.execute(
                """
                UPDATE invite_codes
                SET used_count = used_count + 1, updated_at = ?
                WHERE id = ?
                """,
                (now, invite_dict["id"]),
            )
            invite_dict["used_count"] = int(invite_dict["used_count"]) + 1
            invite_dict["updated_at"] = now
        else:
            member = dict(existing)
            if member["status"] != "active":
                raise PermissionError("member is not active")

        device = _upsert_member_device(conn, member["id"], payload, now)
        token, session = _create_session(conn, member["id"], payload, now)
        conn.commit()

    return {
        "token": token,
        "session": session,
        "member": serialize_member(member),
        "device": device,
        "invite": serialize_invite_code(invite_dict),
    }


def login_with_device(payload: dict) -> dict:
    phone = _normalize_phone(payload.get("phone"))
    device_id = _require_device_id(payload)
    if not is_valid_phone(phone):
        raise ValueError("phone must be an 11 digit mainland China mobile number")

    now = _utc_now_text()
    with connect() as conn:
        member_row = _get_member_row_by_phone(conn, phone)
        if member_row is None:
            raise PermissionError("member is not registered")
        member = dict(member_row)
        if member["status"] != "active":
            raise PermissionError("member is not active")

        device_hash = _hash_secret(device_id)
        device_row = conn.execute(
            """
            SELECT id, member_id, device_name, platform, status, first_seen_at, last_seen_at
            FROM member_devices
            WHERE member_id = ? AND device_id_hash = ?
            LIMIT 1
            """,
            (member["id"], device_hash),
        ).fetchone()
        if device_row is None:
            raise PermissionError("device is not approved for this member")

        device = dict(device_row)
        if device["status"] != "active":
            raise PermissionError("device is disabled")

        conn.execute(
            "UPDATE member_devices SET last_seen_at = ? WHERE id = ?",
            (now, device["id"]),
        )
        device["last_seen_at"] = now
        token, session = _create_session(conn, member["id"], payload, now)
        conn.commit()

    return {
        "token": token,
        "session": session,
        "member": serialize_member(member),
        "device": serialize_device(device),
    }


def _validate_invite(invite: dict) -> None:
    if invite["status"] != "active":
        raise PermissionError("invite code is not active")
    if int(invite["used_count"]) >= int(invite["max_uses"]):
        raise PermissionError("invite code has reached its usage limit")
    if invite.get("expires_at") and datetime.fromisoformat(invite["expires_at"]) < _utc_now():
        raise PermissionError("invite code expired")


def _upsert_member_device(
    conn: sqlite3.Connection,
    member_id: str,
    payload: dict,
    now: str,
) -> dict:
    device_id = _require_device_id(payload)
    device_hash = _hash_secret(device_id)
    existing = conn.execute(
        """
        SELECT id, member_id, device_name, platform, status, first_seen_at, last_seen_at
        FROM member_devices
        WHERE member_id = ? AND device_id_hash = ?
        LIMIT 1
        """,
        (member_id, device_hash),
    ).fetchone()
    if existing is not None:
        device = dict(existing)
        if device["status"] != "active":
            raise PermissionError("device is disabled")
        conn.execute("UPDATE member_devices SET last_seen_at = ? WHERE id = ?", (now, device["id"]))
        device["last_seen_at"] = now
        return serialize_device(device)

    device = {
        "id": str(uuid4()),
        "member_id": member_id,
        "device_id_hash": device_hash,
        "device_name": str(payload.get("device_name") or ""),
        "platform": str(payload.get("platform") or "ios"),
        "status": "active",
        "first_seen_at": now,
        "last_seen_at": now,
    }
    conn.execute(
        """
        INSERT INTO member_devices (
            id, member_id, device_id_hash, device_name, platform, status, first_seen_at, last_seen_at
        )
        VALUES (
            :id, :member_id, :device_id_hash, :device_name, :platform, :status,
            :first_seen_at, :last_seen_at
        )
        """,
        device,
    )
    return serialize_device(device)


def _create_session(conn: sqlite3.Connection, member_id: str, payload: dict, now: str) -> tuple[str, dict]:
    token = secrets.token_urlsafe(32)
    session = {
        "id": str(uuid4()),
        "member_id": member_id,
        "token_hash": _hash_secret(token),
        "device_name": str(payload.get("device_name") or ""),
        "created_at": now,
        "expires_at": (_utc_now() + timedelta(days=90)).isoformat(),
        "revoked_at": "",
    }
    conn.execute(
        """
        INSERT INTO auth_sessions (
            id, member_id, token_hash, device_name, created_at, expires_at, revoked_at
        )
        VALUES (
            :id, :member_id, :token_hash, :device_name, :created_at, :expires_at, :revoked_at
        )
        """,
        session,
    )
    return token, {
        "id": session["id"],
        "expires_at": session["expires_at"],
        "device_name": session["device_name"],
    }


def serialize_invite_code(invite: dict) -> dict:
    try:
        course_tracks = json.loads(invite.get("course_tracks_json") or "[]")
    except json.JSONDecodeError:
        course_tracks = []
    return {
        "id": invite["id"],
        "label": invite["label"],
        "phone": invite.get("phone", ""),
        "student_name": invite.get("student_name", ""),
        "device_serial": invite.get("device_serial", ""),
        "note": invite.get("note", ""),
        "source": invite["source"],
        "member_level": invite["member_level"],
        "course_tracks": course_tracks if isinstance(course_tracks, list) else [],
        "max_uses": int(invite["max_uses"]),
        "used_count": int(invite["used_count"]),
        "status": invite["status"],
        "expires_at": invite["expires_at"],
        "created_at": invite["created_at"],
        "updated_at": invite["updated_at"],
    }


def serialize_device(device: dict) -> dict:
    return {
        "id": device["id"],
        "member_id": device["member_id"],
        "device_name": device["device_name"],
        "platform": device["platform"],
        "status": device["status"],
        "first_seen_at": device["first_seen_at"],
        "last_seen_at": device["last_seen_at"],
    }


def request_official_account_code(payload: dict) -> dict:
    phone = _normalize_phone(payload.get("phone"))
    if not is_valid_phone(phone):
        raise ValueError("phone must be an 11 digit mainland China mobile number")

    now = _utc_now()
    code = str(secrets.randbelow(1_000_000)).zfill(6)
    record = {
        "id": str(uuid4()),
        "phone": phone,
        "code_hash": _hash_secret(code),
        "purpose": str(payload.get("purpose") or "register"),
        "attempts": 0,
        "consumed_at": "",
        "expires_at": (now + timedelta(minutes=10)).isoformat(),
        "created_at": now.isoformat(),
    }

    with connect() as conn:
        conn.execute(
            """
            INSERT INTO auth_verification_codes (
                id, phone, code_hash, purpose, attempts, consumed_at, expires_at, created_at
            )
            VALUES (
                :id, :phone, :code_hash, :purpose, :attempts, :consumed_at, :expires_at, :created_at
            )
            """,
            record,
        )
        conn.commit()

    return {
        "accepted": True,
        "phone": phone,
        "channel": "official_account",
        "official_account_name": "陈忠勇John",
        "expires_at": record["expires_at"],
        "dev_code": code,
        "note": "开发阶段返回 dev_code；正式版会通过公众号“陈忠勇John”发送并不再返回验证码。",
    }


def register_with_official_account_code(payload: dict) -> dict:
    phone = _normalize_phone(payload.get("phone"))
    code = str(payload.get("code") or "").strip()
    if not is_valid_phone(phone):
        raise ValueError("phone must be an 11 digit mainland China mobile number")
    if len(code) != 6 or not code.isdigit():
        raise ValueError("code must be 6 digits")

    now = _utc_now_text()
    with connect() as conn:
        _consume_verification_code(conn, phone, code, purpose="register", now=now)

        existing = _get_member_row_by_phone(conn, phone)
        if existing is None:
            display_name = str(payload.get("display_name") or f"手机用户 {phone[-4:]}").strip()
            member = {
                "id": f"phone-{phone}",
                "phone": phone,
                "display_name": display_name,
                "avatar_initials": str(payload.get("avatar_initials") or "小悟")[:4],
                "provider": "official_account_code",
                "member_level": str(payload.get("member_level") or "course"),
                "source": str(payload.get("source") or "direct"),
                "vip_level": int(payload.get("vip_level") or 0),
                "growth_points": int(payload.get("growth_points") or 0),
                "status": "pending_review",
                "joined_at": now,
                "updated_at": now,
            }
            conn.execute(
                """
                INSERT INTO members (
                    id, phone, display_name, avatar_initials, provider, member_level,
                    source, vip_level, growth_points, status, joined_at, updated_at
                )
                VALUES (
                    :id, :phone, :display_name, :avatar_initials, :provider, :member_level,
                    :source, :vip_level, :growth_points, :status, :joined_at, :updated_at
                )
                """,
                member,
            )
            conn.commit()
            return {
                "accepted": True,
                "review_required": True,
                "message": "注册已提交，等待管理员审核通过后即可登录。",
                "member": serialize_member(member),
            }

        member = dict(existing)
        conn.execute("UPDATE members SET updated_at = ? WHERE id = ?", (now, member["id"]))
        conn.commit()
        member["updated_at"] = now

    if member["status"] == "active":
        return {
            "accepted": True,
            "review_required": False,
            "message": "会员已审核通过，可继续登录。",
            "member": serialize_member(member),
        }
    if member["status"] == "rejected":
        raise PermissionError("registration was rejected by admin")

    return {
        "accepted": True,
        "review_required": True,
        "message": "注册已提交，仍在等待管理员审核。",
        "member": serialize_member(member),
    }


def login_with_official_account_code(payload: dict) -> dict:
    phone = _normalize_phone(payload.get("phone"))
    code = str(payload.get("code") or "").strip()
    if not is_valid_phone(phone):
        raise ValueError("phone must be an 11 digit mainland China mobile number")
    if len(code) != 6 or not code.isdigit():
        raise ValueError("code must be 6 digits")

    now = _utc_now_text()
    code_hash = _hash_secret(code)

    with connect() as conn:
        _consume_verification_code(conn, phone, code, purpose="login", now=now)
        existing = _get_member_row_by_phone(conn, phone)
        if existing is None:
            raise PermissionError("member is not registered")

        member = dict(existing)
        if member["status"] == "pending_review":
            raise PermissionError("member is waiting for admin approval")
        if member["status"] == "rejected":
            raise PermissionError("member registration was rejected")
        if member["status"] != "active":
            raise PermissionError("member is not active")

        token = secrets.token_urlsafe(32)
        session = {
            "id": str(uuid4()),
            "member_id": member["id"],
            "token_hash": _hash_secret(token),
            "device_name": str(payload.get("device_name") or ""),
            "created_at": now,
            "expires_at": (_utc_now() + timedelta(days=90)).isoformat(),
            "revoked_at": "",
        }
        conn.execute(
            """
            INSERT INTO auth_sessions (
                id, member_id, token_hash, device_name, created_at, expires_at, revoked_at
            )
            VALUES (
                :id, :member_id, :token_hash, :device_name, :created_at, :expires_at, :revoked_at
            )
            """,
            session,
        )
        conn.commit()

    return {
        "token": token,
        "session": {
            "id": session["id"],
            "expires_at": session["expires_at"],
            "device_name": session["device_name"],
        },
        "member": serialize_member(member),
    }


def _get_member_row_by_phone(conn: sqlite3.Connection, phone: str) -> sqlite3.Row | None:
    return conn.execute(
        """
        SELECT id, phone, display_name, avatar_initials, provider, member_level,
               source, vip_level, growth_points, status, joined_at, updated_at
        FROM members
        WHERE phone = ?
        """,
        (phone,),
    ).fetchone()


def _consume_verification_code(
    conn: sqlite3.Connection,
    phone: str,
    code: str,
    purpose: str,
    now: str,
) -> None:
    code_hash = _hash_secret(code)
    allowed_purposes = ("register", "login") if purpose == "login" else ("register",)
    placeholders = ",".join("?" for _ in allowed_purposes)
    code_row = conn.execute(
        f"""
        SELECT id, attempts, expires_at
        FROM auth_verification_codes
        WHERE phone = ? AND code_hash = ? AND consumed_at = '' AND purpose IN ({placeholders})
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (phone, code_hash, *allowed_purposes),
    ).fetchone()
    if code_row is None:
        conn.execute(
            """
            UPDATE auth_verification_codes
            SET attempts = attempts + 1
            WHERE phone = ? AND consumed_at = ''
            """,
            (phone,),
        )
        conn.commit()
        raise PermissionError("invalid verification code")

    if code_row["attempts"] >= 5:
        raise PermissionError("too many verification attempts")

    if datetime.fromisoformat(code_row["expires_at"]) < _utc_now():
        raise PermissionError("verification code expired")

    conn.execute(
        "UPDATE auth_verification_codes SET consumed_at = ? WHERE id = ?",
        (now, code_row["id"]),
    )


def list_members(status: str | None = None) -> list[dict]:
    params: tuple[str, ...] = ()
    where = ""
    if status:
        where = "WHERE status = ?"
        params = (status,)

    with connect() as conn:
        rows = conn.execute(
            f"""
            SELECT id, phone, display_name, avatar_initials, provider, member_level,
                   source, vip_level, growth_points, status, joined_at, updated_at
            FROM members
            {where}
            ORDER BY updated_at DESC
            LIMIT 200
            """,
            params,
        ).fetchall()
    return [serialize_member(dict(row)) for row in rows]


def review_member(member_id: str, approved: bool) -> dict:
    now = _utc_now_text()
    new_status = "active" if approved else "rejected"
    with connect() as conn:
        conn.execute(
            "UPDATE members SET status = ?, updated_at = ? WHERE id = ?",
            (new_status, now, member_id),
        )
        row = conn.execute(
            """
            SELECT id, phone, display_name, avatar_initials, provider, member_level,
                   source, vip_level, growth_points, status, joined_at, updated_at
            FROM members
            WHERE id = ?
            """,
            (member_id,),
        ).fetchone()
        conn.commit()

    if row is None:
        raise LookupError("member not found")
    return serialize_member(dict(row))


def get_member_by_token(token: str) -> dict | None:
    token_hash = _hash_secret(token.strip())
    with connect() as conn:
        row = conn.execute(
            """
            SELECT m.id, m.phone, m.display_name, m.avatar_initials, m.provider,
                   m.member_level, m.source, m.vip_level, m.growth_points,
                   m.status, m.joined_at, m.updated_at
            FROM auth_sessions s
            JOIN members m ON m.id = s.member_id
            WHERE s.token_hash = ? AND s.revoked_at = '' AND s.expires_at > ?
            LIMIT 1
            """,
            (token_hash, _utc_now_text()),
        ).fetchone()
    return serialize_member(dict(row)) if row is not None else None


def serialize_member(member: dict) -> dict:
    return {
        "id": member["id"],
        "phone": member["phone"],
        "display_name": member["display_name"],
        "avatar_initials": member["avatar_initials"],
        "provider": member["provider"],
        "member_level": member["member_level"],
        "source": member["source"],
        "vip_level": int(member["vip_level"]),
        "growth_points": int(member["growth_points"]),
        "status": member["status"],
        "joined_at": member["joined_at"],
        "updated_at": member["updated_at"],
    }


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


def list_student_records(filters: dict[str, str] | None = None) -> list[dict]:
    filters = filters or {}
    where: list[str] = []
    params: list[str] = []

    query = str(filters.get("q") or "").strip()
    if query:
        where.append("(student_name LIKE ? OR course_title LIKE ? OR status LIKE ? OR remark LIKE ?)")
        like = f"%{query}%"
        params.extend([like, like, like, like])

    course_title = str(filters.get("course_title") or "").strip()
    if course_title:
        where.append("course_title = ?")
        params.append(course_title)

    status = str(filters.get("status") or "").strip()
    if status:
        where.append("status = ?")
        params.append(status)

    source = str(filters.get("source") or "").strip()
    if source:
        where.append("source = ?")
        params.append(source)

    where_sql = f"WHERE {' AND '.join(where)}" if where else ""
    with connect() as conn:
        rows = conn.execute(
            f"""
            SELECT external_id, student_name, phone, course_title, teacher,
                   status, record_time, remark, source, updated_at
            FROM student_records
            {where_sql}
            ORDER BY record_time DESC, updated_at DESC, student_name ASC
            """,
            params,
        ).fetchall()
    return [dict(row) for row in rows]


def list_student_course_titles() -> list[str]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT DISTINCT course_title
            FROM student_records
            WHERE course_title <> ''
            ORDER BY course_title ASC
            """
        ).fetchall()
    return [str(row[0]) for row in rows]


def list_student_statuses() -> list[str]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT DISTINCT status
            FROM student_records
            WHERE status <> ''
            ORDER BY status ASC
            """
        ).fetchall()
    return [str(row[0]) for row in rows]


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
