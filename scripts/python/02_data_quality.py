"""Profile the quality of every column in the raw CSV files."""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from config.settings import PROCESSED_DATA_DIR, RAW_DATA_DIR
from utils.file_utils import list_csv_files, read_csv, save_dataframe

OUTPUT_PATH = PROCESSED_DATA_DIR / "data_quality.csv"


def _percentage(count: int, total: int) -> float:
    """Return a percentage while handling an empty dataset."""
    return round(count / total * 100, 2) if total else 0.0


def _profile_column(
    file_name: str,
    dataframe: pd.DataFrame,
    column_name: str,
) -> dict[str, int | float | str]:
    """Calculate quality metrics for one column."""
    column = dataframe[column_name]
    row_count = len(dataframe)
    null_count = int(column.isna().sum())
    non_null_count = row_count - null_count
    unique_count = int(column.nunique(dropna=True))

    return {
        "file_name": file_name,
        "column_name": column_name,
        "data_type": str(column.dtype),
        "row_count": row_count,
        "non_null_count": non_null_count,
        "null_count": null_count,
        "null_percentage": _percentage(null_count, row_count),
        "unique_count": unique_count,
        "duplicate_value_count": non_null_count - unique_count,
    }


def _profile_file(file_path: Path) -> list[dict[str, int | float | str]]:
    """Profile every column in one CSV file."""
    dataframe = read_csv(file_path)
    return [
        _profile_column(file_path.name, dataframe, column_name)
        for column_name in dataframe.columns
    ]


def _build_quality_report(raw_data_dir: Path) -> pd.DataFrame:
    """Build a column-level quality report for all raw CSV files."""
    records = [
        record
        for file_path in list_csv_files(raw_data_dir)
        for record in _profile_file(file_path)
    ]
    return pd.DataFrame(records)


def main() -> None:
    """Generate and save the raw-data quality report."""
    report = _build_quality_report(RAW_DATA_DIR)
    save_dataframe(report, OUTPUT_PATH)

    file_count = report["file_name"].nunique()
    print(f"Profiled {len(report)} columns across {file_count} CSV files.")
    print(f"Report saved to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
