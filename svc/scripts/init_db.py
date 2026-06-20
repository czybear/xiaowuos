from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from xiaowuos import database


def main() -> None:
    database.init_db()
    print(f"initialized {database.DB_PATH}")


if __name__ == "__main__":
    main()
