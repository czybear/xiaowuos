from __future__ import annotations

from pathlib import Path
import argparse
import os
import sys
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from xiaowuos import database
from xiaowuos.importers import load_student_records


STUDENT_RECORD_URL = "https://manage.keshij.cn/admin.php/stu_record/index.html"


def fetch_html(url: str, cookie: str) -> str:
    request = Request(
        url,
        headers={
            "Cookie": cookie,
            "User-Agent": "xiaowuOS-student-record-importer/0.1",
        },
    )
    with urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch student records from keshij admin with an existing session cookie.")
    parser.add_argument("--url", default=STUDENT_RECORD_URL)
    parser.add_argument("--cookie", default=os.environ.get("KESHIJ_COOKIE", ""))
    parser.add_argument("--save-html", default="")
    args = parser.parse_args()

    if not args.cookie:
        raise SystemExit("Missing cookie. Set KESHIJ_COOKIE or pass --cookie.")

    html = fetch_html(args.url, args.cookie)
    if "base/login" in html or "登录" in html[:2000]:
        raise SystemExit("The session appears to be logged out. Please refresh the backend cookie.")

    html_path = Path(args.save_html or "/tmp/keshij-student-records.html")
    html_path.write_text(html, encoding="utf-8")

    database.init_db()
    records = load_student_records(html_path)
    count = database.upsert_student_records(records, source="keshij-stu-record")
    print(f"imported {count} student records from {args.url}")


if __name__ == "__main__":
    main()
