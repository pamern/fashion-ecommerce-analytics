"""Create an inventory report for raw CSV files."""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from config.settings import PROCESSED_DATA_DIR, RAW_DATA_DIR
from utils.file_utils import get_file_size, list_csv_files, read_csv, save_dataframe

OUTPUT_PATH = PROCESSED_DATA_DIR / "data_inventory.csv"


def _inspect_file(file_path: Path) -> dict[str, int | float | str]:
    """Collect basic metadata for one CSV file."""
    dataframe = read_csv(file_path)
    row_count, column_count = dataframe.shape

    return {
        "file_name": file_path.name,
        "row_count": row_count,
        "column_count": column_count,
        "file_size_bytes": file_path.stat().st_size,
        "file_size_mb": get_file_size(file_path),
    }


def _build_inventory(raw_data_dir: Path) -> pd.DataFrame:
    """Build an inventory for every CSV file in a directory."""
    records = [_inspect_file(file_path) for file_path in list_csv_files(raw_data_dir)]
    return pd.DataFrame(records)


def main() -> None:
    """Generate and save the raw-data inventory report."""
    inventory = _build_inventory(RAW_DATA_DIR)
    save_dataframe(inventory, OUTPUT_PATH)

    print(f"Inventoried {len(inventory)} CSV files.")
    print(f"Report saved to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
