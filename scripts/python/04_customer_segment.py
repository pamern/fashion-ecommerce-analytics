"""Score customers with the RFM K-Means model."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sqlalchemy import text

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from utils.db_utils import get_engine, read_sql

RFM_COLUMNS = ["recency", "frequency", "monetary"]
SEGMENT_NAMES = [
    "Low-Value Customers",
    "Mid-Value Customers",
    "High-Value Customers",
]
MODEL_VERSION = "rfm_kmeans_k3_v1"


def main() -> None:
    engine = get_engine()
    customer_rfm = read_sql(
        engine,
        """
        SELECT
            customer_id,
            days_since_last_purchase AS recency,
            total_orders AS frequency,
            total_revenue AS monetary
        FROM marts.mart_customer
        WHERE total_orders > 0
          AND days_since_last_purchase IS NOT NULL
        """,
    )

    features = customer_rfm[RFM_COLUMNS].copy()
    features[["frequency", "monetary"]] = np.log1p(features[["frequency", "monetary"]])
    scaled_rfm = StandardScaler().fit_transform(features)
    cluster_ids = KMeans(n_clusters=3, n_init=20, random_state=42).fit_predict(scaled_rfm)

    cluster_profiles = (
        pd.DataFrame(scaled_rfm, columns=RFM_COLUMNS)
        .assign(cluster_id=cluster_ids)
        .groupby("cluster_id")
        .mean()
    )
    cluster_value = (
        cluster_profiles["frequency"]
        + cluster_profiles["monetary"]
        - cluster_profiles["recency"]
    )
    cluster_order = cluster_value.sort_values().index
    segment_by_cluster = dict(zip(cluster_order, SEGMENT_NAMES))

    customer_segments = customer_rfm[["customer_id"]].assign(
        cluster_id=cluster_ids,
        segment_name=[segment_by_cluster[cluster_id] for cluster_id in cluster_ids],
        model_version=MODEL_VERSION,
        scored_at=pd.Timestamp.now(tz="UTC"),
    )

    with engine.begin() as connection:
        connection.execute(text("CREATE SCHEMA IF NOT EXISTS ds"))
        customer_segments.to_sql(
            "customer_segment",
            connection,
            schema="ds",
            if_exists="replace",
            index=False,
        )

    engine.dispose()


if __name__ == "__main__":
    main()
