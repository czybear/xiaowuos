from __future__ import annotations

from pathlib import Path
import argparse
import os
import sys
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from xiaowuos import database
from xiaowuos.importers import parse_html_table_records


COURSE_URL = "https://manage.keshij.cn/admin.php/kecheng/index.html"


def fetch_html(url: str, cookie: str) -> str:
    request = Request(
        url,
        headers={
            "Cookie": cookie,
            "User-Agent": "xiaowuOS-course-importer/0.1",
        },
    )
    with urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch course data from keshij admin with an existing session cookie.")
    parser.add_argument("--url", default=COURSE_URL)
    parser.add_argument("--cookie", default=os.environ.get("KESHIJ_COOKIE", ""))
    parser.add_argument("--save-html", default="")
    args = parser.parse_args()

    if not args.cookie:
        raise SystemExit("Missing cookie. Set KESHIJ_COOKIE or pass --cookie.")

    html = fetch_html(args.url, args.cookie)
    if "base/login" in html or "登录" in html[:2000]:
        raise SystemExit("The session appears to be logged out. Please refresh the backend cookie.")

    if args.save_html:
        Path(args.save_html).write_text(html, encoding="utf-8")

    database.init_db()
    records = parse_html_table_records(html)
    count = database.upsert_courses(records, source="keshij-admin")
    print(f"imported {count} courses from {args.url}")


if __name__ == "__main__":
    main()
