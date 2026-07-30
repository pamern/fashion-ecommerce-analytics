"""Load raw CSV files into PostgreSQL."""

from __future__ import annotations

import logging
import re
import sys
from pathlib import Path

import pandas as pd
from sqlalchemy.engine import Connection

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from config.settings import RAW_DATA_DIR
from utils.db_utils import get_engine
from utils.file_utils import list_csv_files, read_csv

DDL_PATH = PROJECT_ROOT / "scripts" / "sql" / "01_create_raw_tables.sql"
SCHEMA_NAME = "raw"
LOGGER = logging.getLogger(__name__)
VALID_IDENTIFIER = re.compile(r"^[a-z_][a-z0-9_]*$")


def _execute_ddl(connection: Connection, ddl_path: Path) -> None:
    """Create the raw schema and tables from a SQL file."""
    sql = ddl_path.read_text(encoding="utf-8")

    for statement in sql.split(";"):
        statement = statement.strip()
        if statement and statement.upper() not in {"BEGIN", "COMMIT"}:
            connection.exec_driver_sql(statement)


def _parse_dates(dataframe: pd.DataFrame) -> pd.DataFrame:
    """Convert source date columns to Python date values."""
    date_columns = [
        column
        for column in dataframe.columns
        if column.lower() == "date" or column.lower().endswith("_date")
    ]

    for column in date_columns:
        dataframe[column] = pd.to_datetime(
            dataframe[column],
            errors="raise",
        ).dt.date

    return dataframe


def _get_table_name(file_path: Path) -> str:
    """Return a safe table name derived from a CSV file name."""
    table_name = file_path.stem
    if not VALID_IDENTIFIER.fullmatch(table_name):
        raise ValueError(f"Invalid raw table name: {table_name}")
    return table_name


def _load_file(connection: Connection, file_path: Path) -> int:
    """Replace one raw table with data from its matching CSV file."""
    table_name = _get_table_name(file_path)
    dataframe = _parse_dates(read_csv(file_path))

    connection.exec_driver_sql(
        f'TRUNCATE TABLE {SCHEMA_NAME}."{table_name}"'
    )
    dataframe.to_sql(
        name=table_name,
        con=connection,
        schema=SCHEMA_NAME,
        if_exists="append",
        index=False,
        chunksize=10_000,
    )

    return len(dataframe)


def main() -> None:
    """Create raw tables and load all source CSV files."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    csv_files = list_csv_files(RAW_DATA_DIR)
    engine = get_engine()
    total_rows = 0

    try:
        with engine.begin() as connection:
            _execute_ddl(connection, DDL_PATH)

            for file_path in csv_files:
                row_count = _load_file(connection, file_path)
                total_rows += row_count
                LOGGER.info("Loaded %s rows into raw.%s", row_count, file_path.stem)
    finally:
        engine.dispose()

    LOGGER.info(
        "Loaded %s rows from %s CSV files into schema %s",
        total_rows,
        len(csv_files),
        SCHEMA_NAME,
    )


if __name__ == "__main__":
    main()
