"""Reusable validation helpers for pandas DataFrames."""

from collections.abc import Sequence

import pandas as pd


class ValidationError(ValueError):
    """Raised when a DataFrame fails a validation rule."""


def _validate_not_empty(dataframe: pd.DataFrame) -> None:
    """Ensure the DataFrame contains at least one row."""
    if dataframe.empty:
        raise ValidationError("DataFrame is empty.")


def _validate_required_columns(
    dataframe: pd.DataFrame,
    required_columns: Sequence[str],
) -> None:
    """Ensure all required columns exist."""
    missing = sorted(set(required_columns) - set(dataframe.columns))
    if missing:
        raise ValidationError(f"Missing required columns: {missing}")


def _validate_no_nulls(
    dataframe: pd.DataFrame,
    columns: Sequence[str],
) -> None:
    """Ensure selected columns contain no null values."""
    _validate_required_columns(dataframe, columns)
    null_counts = dataframe[list(columns)].isna().sum()
    invalid = null_counts[null_counts > 0].to_dict()

    if invalid:
        raise ValidationError(f"Null values found: {invalid}")


def _validate_unique(
    dataframe: pd.DataFrame,
    columns: Sequence[str],
) -> None:
    """Ensure selected columns uniquely identify each row."""
    _validate_required_columns(dataframe, columns)
    duplicate_count = int(dataframe.duplicated(subset=list(columns)).sum())

    if duplicate_count:
        raise ValidationError(
            f"Found {duplicate_count} duplicate row(s) for columns: {list(columns)}"
        )


def validate_dataframe(
    dataframe: pd.DataFrame,
    *,
    required_columns: Sequence[str] = (),
    non_null_columns: Sequence[str] = (),
    unique_columns: Sequence[str] = (),
) -> None:
    """Run the common structural and data-quality checks."""
    _validate_not_empty(dataframe)
    _validate_required_columns(dataframe, required_columns)

    if non_null_columns:
        _validate_no_nulls(dataframe, non_null_columns)
    if unique_columns:
        _validate_unique(dataframe, unique_columns)
