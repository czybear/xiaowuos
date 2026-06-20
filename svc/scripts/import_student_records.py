from __future__ import annotations

from pathlib import Path
import argparse
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from xiaowuos import database
from xiaowuos.importers import load_student_records


def main() -> None:
    parser = argparse.ArgumentParser(description="Import xiaowuOS student records into SQLite.")
    parser.add_argument("source", help="Path to JSON, CSV, TSV, TXT, or HTML table export.")
    parser.add_argument("--source-name", default="keshij-stu-record", help="Source label stored in import metadata.")
    args = parser.parse_args()

    database.init_db()
    records = load_student_records(Path(args.source))
    count = database.upsert_student_records(records, source=args.source_name)
    print(f"imported {count} student records from {args.source}")


if __name__ == "__main__":
    main()
