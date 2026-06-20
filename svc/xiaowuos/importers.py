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


def load_course_records(path: Path) -> list[dict]:
    suffix = path.suffix.lower()
    if suffix == ".json":
        return parse_json_records(path.read_text(encoding="utf-8"))
    if suffix == ".csv":
        return parse_csv_records(path)
    if suffix in {".html", ".htm"}:
        return parse_html_table_records(path.read_text(encoding="utf-8", errors="replace"))
    raise ValueError(f"Unsupported import file: {path}")


def parse_json_records(text: str) -> list[dict]:
    payload = json.loads(text)
    if isinstance(payload, dict):
        for key in ("items", "data", "list", "rows"):
            if isinstance(payload.get(key), list):
                payload = payload[key]
                break
    if not isinstance(payload, list):
        raise ValueError("JSON import expects a list, or an object containing items/data/list/rows.")
    return [normalize_record(item) for item in payload if isinstance(item, dict)]


def parse_csv_records(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return [normalize_record(row) for row in reader]


def parse_html_table_records(text: str) -> list[dict]:
    parser = TableParser()
    parser.feed(text)
    return [normalize_record(row) for row in parser.records()]


def normalize_record(raw: dict[str, Any]) -> dict:
    normalized: dict[str, Any] = {"raw": dict(raw)}

    for target, aliases in FIELD_ALIASES.items():
        normalized[target] = first_value(raw, aliases)

    if not normalized["external_id"]:
        normalized["external_id"] = normalized["title"]

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
