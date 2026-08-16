"""Export dimensional and fact marts from PostgreSQL to Parquet files."""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import Engine, inspect, text
from sqlalchemy.engine import Connection

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from utils.db_utils import get_engine

DEFAULT_SCHEMA = "marts"
SHARED_DRIVE = Path("/run/media/pamern/shared")
DEFAULT_OUTPUT_DIR = SHARED_DRIVE / "retail_dw" / "marts"
MART_PREFIXES = ("dim_", "fact_", "mart_")
LOGGER = logging.getLogger(__name__)


def get_mart_table_names(
    engine: Engine,
    schema_name: str = DEFAULT_SCHEMA,
) -> list[str]:
    """Return sorted dimension, fact, and reporting mart table names."""
    table_names = inspect(engine).get_table_names(schema=schema_name)
    return sorted(
        table_name
        for table_name in table_names
        if table_name.startswith(MART_PREFIXES)
    )


def _qualified_table_name(
    connection: Connection,
    schema_name: str,
    table_name: str,
) -> str:
    """Quote a schema-qualified table name for the current SQL dialect."""
    preparer = connection.dialect.identifier_preparer
    return (
        f"{preparer.quote_schema(schema_name)}."
        f"{preparer.quote_identifier(table_name)}"
    )


def export_table(
    connection: Connection,
    schema_name: str,
    table_name: str,
    output_dir: Path,
) -> tuple[Path, int]:
    """Export one database table to Parquet and return its path and row count."""
    qualified_name = _qualified_table_name(connection, schema_name, table_name)
    dataframe = pd.read_sql_query(
        sql=text(f"SELECT * FROM {qualified_name}"),
        con=connection,
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{table_name}.parquet"
    dataframe.to_parquet(
        output_path,
        engine="pyarrow",
        compression="snappy",
        index=False,
    )
    return output_path, len(dataframe)


def export_marts(
    engine: Engine,
    output_dir: Path = DEFAULT_OUTPUT_DIR,
    schema_name: str = DEFAULT_SCHEMA,
) -> dict[str, int]:
    """Export all mart tables and return row counts by table."""
    table_names = get_mart_table_names(engine, schema_name)
    if not table_names:
        raise RuntimeError(
            f"No mart tables found in schema {schema_name!r}"
        )

    row_counts: dict[str, int] = {}
    with engine.connect() as connection:
        for table_name in table_names:
            output_path, row_count = export_table(
                connection,
                schema_name,
                table_name,
                output_dir,
            )
            row_counts[table_name] = row_count
            LOGGER.info(
                "Exported %s.%s (%s rows) to %s",
                schema_name,
                table_name,
                row_count,
                output_path,
            )

    return row_counts


def parse_args() -> argparse.Namespace:
    """Parse command-line options."""
    parser = argparse.ArgumentParser(
        description="Export PostgreSQL marts to Parquet.",
    )
    parser.add_argument(
        "--schema",
        default=DEFAULT_SCHEMA,
        help=f"Source PostgreSQL schema (default: {DEFAULT_SCHEMA}).",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Destination directory (default: {DEFAULT_OUTPUT_DIR}).",
    )
    return parser.parse_args()


def main() -> None:
    """Run the mart export."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )
    args = parse_args()
    engine = get_engine()

    try:
        row_counts = export_marts(
            engine,
            output_dir=args.output_dir,
            schema_name=args.schema,
        )
    finally:
        engine.dispose()

    LOGGER.info(
        "Export complete: %s tables and %s rows written to %s",
        len(row_counts),
        sum(row_counts.values()),
        args.output_dir,
    )


if __name__ == "__main__":
    main()
