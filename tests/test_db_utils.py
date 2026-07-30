from unittest.mock import MagicMock

import pandas as pd
import pytest
from sqlalchemy.exc import SQLAlchemyError

from utils import db_utils


@pytest.fixture
def db_config() -> dict[str, str]:
    return {
        "host": "localhost",
        "port": "5432",
        "database": "analytics",
        "user": "postgres",
        "password": "secret",
    }


def test_build_database_url(
    monkeypatch: pytest.MonkeyPatch,
    db_config: dict[str, str],
) -> None:
    monkeypatch.setattr(db_utils, "DB_CONFIG", db_config)

    assert (
        db_utils._build_database_url()
        == "postgresql+psycopg://postgres:secret@localhost:5432/analytics"
    )


def test_build_database_url_rejects_missing_config(
    monkeypatch: pytest.MonkeyPatch,
    db_config: dict[str, str],
) -> None:
    db_config["password"] = ""
    monkeypatch.setattr(db_utils, "DB_CONFIG", db_config)

    with pytest.raises(ValueError, match="password"):
        db_utils._build_database_url()


def test_get_engine(
    monkeypatch: pytest.MonkeyPatch,
    db_config: dict[str, str],
) -> None:
    engine = MagicMock()
    create_engine = MagicMock(return_value=engine)
    monkeypatch.setattr(db_utils, "DB_CONFIG", db_config)
    monkeypatch.setattr(db_utils, "create_engine", create_engine)

    result = db_utils.get_engine(echo=True)

    assert result is engine
    create_engine.assert_called_once_with(
        "postgresql+psycopg://postgres:secret@localhost:5432/analytics",
        echo=True,
        pool_pre_ping=True,
    )


def test_connection_returns_true() -> None:
    engine = MagicMock()

    assert db_utils.test_connection(engine) is True

    statement = engine.connect.return_value.__enter__.return_value.execute.call_args.args[0]
    assert str(statement) == "SELECT 1"


def test_connection_returns_false_on_sqlalchemy_error() -> None:
    engine = MagicMock()
    engine.connect.side_effect = SQLAlchemyError("connection failed")

    assert db_utils.test_connection(engine) is False


def test_get_connection_yields_transaction_connection() -> None:
    engine = MagicMock()
    expected = engine.begin.return_value.__enter__.return_value

    with db_utils.get_connection(engine) as connection:
        assert connection is expected

    engine.begin.assert_called_once_with()


def test_execute_sql_uses_parameters() -> None:
    engine = MagicMock()
    connection = engine.begin.return_value.__enter__.return_value

    db_utils.execute_sql(
        engine,
        "DELETE FROM orders WHERE order_id = :order_id",
        {"order_id": 10},
    )

    statement, parameters = connection.execute.call_args.args
    assert str(statement) == "DELETE FROM orders WHERE order_id = :order_id"
    assert parameters == {"order_id": 10}


def test_read_sql(monkeypatch: pytest.MonkeyPatch) -> None:
    engine = MagicMock()
    expected = pd.DataFrame({"order_id": [1]})
    read_sql_query = MagicMock(return_value=expected)
    monkeypatch.setattr(db_utils.pd, "read_sql_query", read_sql_query)

    result = db_utils.read_sql(engine, "SELECT * FROM orders", {"limit": 1})

    assert result is expected
    call = read_sql_query.call_args.kwargs
    assert str(call["sql"]) == "SELECT * FROM orders"
    assert call["con"] is engine
    assert call["params"] == {"limit": 1}


@pytest.mark.parametrize("exists", [True, False])
def test_table_exists(
    monkeypatch: pytest.MonkeyPatch,
    exists: bool,
) -> None:
    engine = MagicMock()
    read_sql = MagicMock(
        return_value=pd.DataFrame({"table_exists": [exists]}),
    )
    monkeypatch.setattr(db_utils, "read_sql", read_sql)

    assert db_utils.table_exists(engine, "raw", "orders") is exists

    assert read_sql.call_args.args[0] is engine
    assert read_sql.call_args.args[2] == {
        "schema_name": "raw",
        "table_name": "orders",
    }


def test_write_dataframe() -> None:
    dataframe = MagicMock(spec=pd.DataFrame)
    engine = MagicMock()

    db_utils.write_dataframe(
        dataframe,
        engine,
        "orders",
        schema_name="staging",
        if_exists="replace",
        chunksize=500,
    )

    dataframe.to_sql.assert_called_once_with(
        name="orders",
        con=engine,
        schema="staging",
        if_exists="replace",
        index=False,
        chunksize=500,
        method="multi",
    )


def test_write_dataframe_rejects_invalid_if_exists() -> None:
    with pytest.raises(ValueError, match="if_exists"):
        db_utils.write_dataframe(
            pd.DataFrame(),
            MagicMock(),
            "orders",
            if_exists="invalid",
        )
