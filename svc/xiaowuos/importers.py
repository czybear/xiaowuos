from __future__ import annotations

import csv
import html
import json
from html.parser import HTMLParser
from pathlib import Path
from typing import Any


FIELD_ALIASES = {
    "external_id": ["id", "编号", "课程id", "课程ID", "ID"],
    "title": ["title", "name", "课程名称", "课程标题", "名称", "标题"],
    "category": ["category", "分类", "类别", "课程分类"],
    "teacher": ["teacher", "讲师", "老师", "授课老师", "教师"],
    "summary": ["summary", "简介", "课程简介", "描述", "说明"],
    "cover_url": ["cover", "cover_url", "封面", "图片", "缩略图"],
    "price": ["price", "价格", "售价", "课时费"],
    "status": ["status", "状态", "上架状态", "是否上架"],
}

STUDENT_RECORD_FIELD_ALIASES = {
    "external_id": ["id", "编号", "记录id", "记录ID", "ID", "报名ID", "订单ID"],
    "student_name": ["student_name", "name", "学员", "学员姓名", "学生", "学生姓名", "姓名", "孩子姓名"],
    "phone": ["phone", "mobile", "手机号", "手机", "联系电话", "家长手机", "家长手机号"],
    "course_title": ["course", "course_title", "课程", "课程名称", "报名课程", "购买课程", "班级", "班级名称"],
    "teacher": ["teacher", "老师", "讲师", "顾问", "负责老师", "班主任"],
    "status": ["status", "状态", "学习状态", "报名状态", "支付状态", "绑定状态", "学员状态"],
    "record_time": ["最新上课时间", "time", "record_time", "报名时间", "记录时间", "下单时间", "时间", "created_at", "创建时间"],
    "remark": ["remark", "备注", "说明", "跟进记录", "回访记录"],
}


def load_course_records(path: Path) -> list[dict]:
    suffix = path.suffix.lower()
    if suffix == ".json":
        return parse_json_records(path.read_text(encoding="utf-8"))
    if suffix == ".csv":
        return parse_csv_records(path)
    if suffix in {".tsv", ".txt"}:
        return parse_delimited_text_records(path)
    if suffix in {".html", ".htm"}:
        return parse_html_table_records(path.read_text(encoding="utf-8", errors="replace"))
    raise ValueError(f"Unsupported import file: {path}")


def load_student_records(path: Path) -> list[dict]:
    rows = load_raw_records(path)
    return [normalize_student_record(row) for row in rows]


def load_raw_records(path: Path) -> list[dict]:
    suffix = path.suffix.lower()
    if suffix == ".json":
        return parse_json_raw_records(path.read_text(encoding="utf-8"))
    if suffix == ".csv":
        return parse_csv_raw_records(path)
    if suffix in {".tsv", ".txt"}:
        return parse_delimited_text_raw_records(path)
    if suffix in {".html", ".htm"}:
        parser = TableParser()
        parser.feed(path.read_text(encoding="utf-8", errors="replace"))
        return parser.records()
    raise ValueError(f"Unsupported import file: {path}")


def parse_json_records(text: str) -> list[dict]:
    return [normalize_record(item) for item in parse_json_raw_records(text)]


def parse_json_raw_records(text: str) -> list[dict]:
    payload = json.loads(text)
    if isinstance(payload, dict):
        for key in ("items", "data", "list", "rows"):
            if isinstance(payload.get(key), list):
                payload = payload[key]
                break
    if not isinstance(payload, list):
        raise ValueError("JSON import expects a list, or an object containing items/data/list/rows.")
    return [item for item in payload if isinstance(item, dict)]


def parse_csv_records(path: Path) -> list[dict]:
    return [normalize_record(row) for row in parse_csv_raw_records(path)]


def parse_csv_raw_records(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return list(reader)


def parse_delimited_text_records(path: Path) -> list[dict]:
    return [normalize_record(row) for row in parse_delimited_text_raw_records(path)]


def parse_delimited_text_raw_records(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if len(lines) < 2:
        return []

    delimiter = "\t" if "\t" in lines[0] else ","
    reader = csv.DictReader(lines, delimiter=delimiter)
    return list(reader)


def parse_html_table_records(text: str) -> list[dict]:
    parser = TableParser()
    parser.feed(text)
    return [normalize_record(row) for row in parser.records()]


def normalize_record(raw: dict[str, Any]) -> dict:
    normalized: dict[str, Any] = {"raw": dict(raw)}

    for target, aliases in FIELD_ALIASES.items():
        normalized[target] = first_value(raw, aliases)

    class_name = first_value(raw, ["班级", "班级名称"])
    class_time = first_value(raw, ["上课时间", "时间"])
    course_type = first_value(raw, ["课程类型"])
    student_count = first_value(raw, ["学员数量"])
    lesson_cost = first_value(raw, ["课时消耗"])
    created_at = first_value(raw, ["创建时间"])

    if not normalized["external_id"]:
        parts = [normalized["title"], class_name, class_time]
        normalized["external_id"] = "|".join(part for part in parts if part)

    if class_name and not normalized["category"]:
        normalized["category"] = class_name

    details = []
    if class_time:
        details.append(f"上课时间：{class_time}")
    if lesson_cost:
        details.append(f"课时消耗：{lesson_cost}")
    if student_count:
        details.append(f"学员数量：{student_count}")
    if course_type:
        details.append(f"课程类型：{course_type}")
    if created_at:
        details.append(f"创建时间：{created_at}")
    if details and not normalized["summary"]:
        normalized["summary"] = "；".join(details)
    if course_type and not normalized["status"]:
        normalized["status"] = course_type

    if not normalized["teacher"]:
        normalized["teacher"] = "澄木老师"

    return normalized


def normalize_student_record(raw: dict[str, Any]) -> dict:
    normalized: dict[str, Any] = {"raw": dict(raw)}

    for target, aliases in STUDENT_RECORD_FIELD_ALIASES.items():
        normalized[target] = first_value(raw, aliases)

    total_lessons = first_value(raw, ["总课时"])
    remaining_lessons = first_value(raw, ["剩余课时"])
    remaining_points = first_value(raw, ["剩余积分"])
    birthday = first_value(raw, ["生日日期"])
    expires_at = first_value(raw, ["到期时间"])
    created_at = first_value(raw, ["创建时间"])

    if not normalized["remark"]:
        details = []
        if total_lessons:
            details.append(f"总课时：{total_lessons}")
        if remaining_lessons:
            details.append(f"剩余课时：{remaining_lessons}")
        if remaining_points:
            details.append(f"剩余积分：{remaining_points}")
        if birthday:
            details.append(f"生日日期：{birthday}")
        if expires_at:
            details.append(f"到期时间：{expires_at}")
        if created_at:
            details.append(f"创建时间：{created_at}")
        normalized["remark"] = "；".join(details)

    if not normalized["external_id"]:
        parts = [
            normalized["student_name"],
            normalized["phone"],
            normalized["course_title"],
            normalized["record_time"],
        ]
        normalized["external_id"] = "|".join(part for part in parts if part)

    if not normalized["external_id"]:
        normalized["external_id"] = json.dumps(raw, ensure_ascii=False, sort_keys=True)

    if not normalized["teacher"]:
        normalized["teacher"] = "澄木老师"

    return normalized


def first_value(raw: dict[str, Any], keys: list[str]) -> str:
    lowered = {str(key).strip().lower(): value for key, value in raw.items()}
    for key in keys:
        if key in raw and raw[key] not in (None, ""):
            return stringify(raw[key])
        lower_key = key.lower()
        if lower_key in lowered and lowered[lower_key] not in (None, ""):
            return stringify(lowered[lower_key])
    return ""


def stringify(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    return str(value).strip()


class TableParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_table = False
        self.in_cell = False
        self.current_cell: list[str] = []
        self.current_row: list[str] = []
        self.rows: list[list[str]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "table":
            self.in_table = True
        elif self.in_table and tag == "tr":
            self.current_row = []
        elif self.in_table and tag in {"td", "th"}:
            self.in_cell = True
            self.current_cell = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "table":
            self.in_table = False
        elif self.in_table and tag in {"td", "th"} and self.in_cell:
            cell = html.unescape("".join(self.current_cell)).strip()
            self.current_row.append(" ".join(cell.split()))
            self.in_cell = False
        elif self.in_table and tag == "tr" and self.current_row:
            self.rows.append(self.current_row)

    def handle_data(self, data: str) -> None:
        if self.in_cell:
            self.current_cell.append(data)

    def records(self) -> list[dict[str, str]]:
        if len(self.rows) < 2:
            return []

        headers = self.rows[0]
        records: list[dict[str, str]] = []
        for row in self.rows[1:]:
            if not any(row):
                continue
            record = {headers[index]: row[index] for index in range(min(len(headers), len(row)))}
            records.append(record)
        return records
