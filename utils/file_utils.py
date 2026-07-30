"""File and DataFrame I/O helpers."""

from pathlib import Path

import pandas as pd


def list_csv_files(directory: Path) -> list[Path]:
    """Return the CSV files in a directory."""
    if not directory.exists():
        raise FileNotFoundError(f"Directory does not exist: {directory}")

    csv_files = sorted(directory.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in: {directory}")
    return csv_files


def read_csv(file_path: Path, **kwargs) -> pd.DataFrame:
    """Read a CSV file with sensible defaults."""
    options = {"low_memory": False}
    options.update(kwargs)
    return pd.read_csv(file_path, **options)


def get_file_size(file_path: Path) -> float:
    """Return a file's size in megabytes."""
    return round(file_path.stat().st_size / (1024 * 1024), 2)


def _ensure_directory_exists(directory: Path) -> None:
    """Create a directory and its parents when needed."""
    directory.mkdir(parents=True, exist_ok=True)


def save_dataframe(
    dataframe: pd.DataFrame,
    output_path: Path,
    index: bool = False,
) -> None:
    """Save a DataFrame as CSV."""
    _ensure_directory_exists(output_path.parent)
    dataframe.to_csv(output_path, index=index)
