"""Database utility functions for PostgreSQL."""

from __future__ import annotations

from contextlib import contextmanager
from typing import Generator

import pandas as pd
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import Connection
from sqlalchemy.exc import SQLAlchemyError

from config.settings import DB_CONFIG


def _build_database_url() -> str:
    """Build a PostgreSQL SQLAlchemy connection URL."""
    required_keys = {"host", "port", "database", "user", "password"}
    missing_keys = [key for key in required_keys if not DB_CONFIG.get(key)]

    if missing_keys:
        raise ValueError(f"Missing database configuration values: {missing_keys}")

    return (
        "postgresql+psycopg://"
        f"{DB_CONFIG['user']}:{DB_CONFIG['password']}"
        f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}"
        f"/{DB_CONFIG['database']}"
    )


def get_engine(echo: bool = False) -> Engine:
    """Create and return a SQLAlchemy engine."""
    return create_engine(
        _build_database_url(),
        echo=echo,
        pool_pre_ping=True,
    )


def test_connection(engine: Engine) -> bool:
    """Test whether the database connection is working."""
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))

        return True
    except SQLAlchemyError:
        return False


@contextmanager
def get_connection(engine: Engine) -> Generator[Connection, None, None]:
    """Provide a transactional database connection."""
    with engine.begin() as connection:
        yield connection


def execute_sql(engine: Engine, sql: str, parameters: dict | None = None) -> None:
    """Execute a SQL statement inside a transaction."""
    with engine.begin() as connection:
        connection.execute(text(sql), parameters or {})


def read_sql(
    engine: Engine,
    sql: str,
    parameters: dict | None = None,
) -> pd.DataFrame:
    """Execute a query and return the result as a DataFrame."""
    return pd.read_sql_query(sql=text(sql), con=engine, params=parameters)


def table_exists(engine: Engine, schema_name: str, table_name: str) -> bool:
    """Check whether a table exists in PostgreSQL."""
    sql = """
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = :schema_name
              AND table_name = :table_name
        ) AS table_exists;
    """

    result = read_sql(
        engine,
        sql,
        {"schema_name": schema_name, "table_name": table_name},
    )

    return bool(result.loc[0, "table_exists"])


def write_dataframe(
    dataframe: pd.DataFrame,
    engine: Engine,
    table_name: str,
    schema_name: str = "raw",
    if_exists: str = "append",
    chunksize: int = 10_000,
) -> None:
    """Write a DataFrame to a PostgreSQL table."""
    valid_if_exists = {"fail", "replace", "append"}

    if if_exists not in valid_if_exists:
        raise ValueError(f"if_exists must be one of: {sorted(valid_if_exists)}")

    dataframe.to_sql(
        name=table_name,
        con=engine,
        schema=schema_name,
        if_exists=if_exists,
        index=False,
        chunksize=chunksize,
        method="multi",
    )
