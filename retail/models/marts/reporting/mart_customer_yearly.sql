{{ config(materialized='table') }}

WITH fulfilled_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date::date AS order_date,
        SUM(quantity) AS quantity,
        SUM(net_sales) AS revenue
    FROM {{ ref('int_order_items_enriched') }}
    WHERE is_fulfilled_order = TRUE
    GROUP BY
        customer_id,
        order_id,
        order_date::date
),

customer_first_order AS (
    SELECT
        customer_id,
        EXTRACT(YEAR FROM MIN(order_date))::int AS first_order_year
    FROM fulfilled_orders
    GROUP BY customer_id
),

data_bounds AS (
    SELECT
        MIN(order_date) AS min_order_date,
        MAX(order_date) AS max_order_date
    FROM fulfilled_orders
),

snapshot_bounds AS (
    SELECT
        CASE
            WHEN min_order_date > MAKE_DATE(EXTRACT(YEAR FROM min_order_date)::int, 1, 1)
                THEN EXTRACT(YEAR FROM min_order_date)::int + 1
            ELSE EXTRACT(YEAR FROM min_order_date)::int
        END AS first_snapshot_year,

        CASE
            WHEN max_order_date < MAKE_DATE(EXTRACT(YEAR FROM max_order_date)::int, 12, 31)
                THEN EXTRACT(YEAR FROM max_order_date)::int - 1
            ELSE EXTRACT(YEAR FROM max_order_date)::int
        END AS last_snapshot_year
    FROM data_bounds
),

snapshot_years AS (
    SELECT
        snapshot_year AS year,
        MAKE_DATE(snapshot_year, 12, 31) AS snapshot_date
    FROM snapshot_bounds
    CROSS JOIN LATERAL GENERATE_SERIES(
        first_snapshot_year,
        last_snapshot_year
    ) AS snapshot_year
),

customer_years AS (
    SELECT DISTINCT
        o.customer_id,
        y.year,
        y.snapshot_date
    FROM fulfilled_orders AS o
    CROSS JOIN snapshot_years AS y
    WHERE o.order_date <= y.snapshot_date
),

rfm_snapshot AS (
    SELECT
        cy.customer_id,
        cy.year,
        cy.snapshot_date,
        cy.snapshot_date - MAX(o.order_date) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.revenue) AS monetary,
        SUM(o.quantity) AS units_purchased
    FROM customer_years AS cy
    INNER JOIN fulfilled_orders AS o
        ON cy.customer_id = o.customer_id
        AND o.order_date <= cy.snapshot_date
    GROUP BY
        cy.customer_id,
        cy.year,
        cy.snapshot_date
),

rfm_features AS (
    SELECT
        customer_id,
        year,
        snapshot_date,
        recency,
        frequency,
        monetary,
        units_purchased,
        monetary / NULLIF(frequency, 0) AS average_order_value,
        LN(1 + frequency) AS log_frequency,
        LN(1 + monetary) AS log_monetary
    FROM rfm_snapshot
),

current_rfm AS (
    SELECT
        customer_id,
        rfm_segment,
        days_since_last_purchase AS recency,
        total_orders AS frequency,
        total_revenue AS monetary,
        LN(1 + total_orders) AS log_frequency,
        LN(1 + total_revenue) AS log_monetary
    FROM {{ ref('mart_customer') }}
    WHERE rfm_segment IS NOT NULL
),

scaler AS (
    SELECT
        AVG(recency) AS mean_recency,
        STDDEV_POP(recency) AS std_recency,
        AVG(log_frequency) AS mean_log_frequency,
        STDDEV_POP(log_frequency) AS std_log_frequency,
        AVG(log_monetary) AS mean_log_monetary,
        STDDEV_POP(log_monetary) AS std_log_monetary
    FROM current_rfm
),

current_scaled AS (
    SELECT
        c.customer_id,
        c.rfm_segment,
        (c.recency - s.mean_recency)
            / NULLIF(s.std_recency, 0) AS recency_scaled,
        (c.log_frequency - s.mean_log_frequency)
            / NULLIF(s.std_log_frequency, 0) AS frequency_scaled,
        (c.log_monetary - s.mean_log_monetary)
            / NULLIF(s.std_log_monetary, 0) AS monetary_scaled
    FROM current_rfm AS c
    CROSS JOIN scaler AS s
),

segment_centroids AS (
    SELECT
        rfm_segment,
        AVG(recency_scaled) AS centroid_recency,
        AVG(frequency_scaled) AS centroid_frequency,
        AVG(monetary_scaled) AS centroid_monetary
    FROM current_scaled
    GROUP BY rfm_segment
),

yearly_scaled AS (
    SELECT
        r.*,
        (r.recency - s.mean_recency)
            / NULLIF(s.std_recency, 0) AS recency_scaled,
        (r.log_frequency - s.mean_log_frequency)
            / NULLIF(s.std_log_frequency, 0) AS frequency_scaled,
        (r.log_monetary - s.mean_log_monetary)
            / NULLIF(s.std_log_monetary, 0) AS monetary_scaled
    FROM rfm_features AS r
    CROSS JOIN scaler AS s
),

segment_distance AS (
    SELECT
        y.customer_id,
        y.year,
        c.rfm_segment,
        POWER(y.recency_scaled - c.centroid_recency, 2)
        + POWER(y.frequency_scaled - c.centroid_frequency, 2)
        + POWER(y.monetary_scaled - c.centroid_monetary, 2) AS distance
    FROM yearly_scaled AS y
    CROSS JOIN segment_centroids AS c
),

yearly_segment_ranked AS (
    SELECT
        customer_id,
        year,
        rfm_segment,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, year
            ORDER BY distance
        ) AS rn
    FROM segment_distance
),

yearly_segment AS (
    SELECT
        customer_id,
        year,
        rfm_segment
    FROM yearly_segment_ranked
    WHERE rn = 1
),

orders_with_gap AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        quantity,
        revenue,
        order_date - LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS days_between_purchases
    FROM fulfilled_orders
),

annual_behavior AS (
    SELECT
        customer_id,
        EXTRACT(YEAR FROM order_date)::int AS year,
        COUNT(DISTINCT order_id) AS orders_in_year,
        SUM(revenue) AS revenue_in_year,
        SUM(quantity) AS units_in_year,
        SUM(revenue)
            / NULLIF(COUNT(DISTINCT order_id), 0) AS aov_in_year,

        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY days_between_purchases
        ) FILTER (
            WHERE days_between_purchases IS NOT NULL
        ) AS median_days_between_purchases

    FROM orders_with_gap
    GROUP BY
        customer_id,
        EXTRACT(YEAR FROM order_date)::int
),

combined AS (
    SELECT
        r.customer_id,
        r.year,
        f.first_order_year,
        s.rfm_segment AS segment,

        CASE
            WHEN s.rfm_segment = 'Low-Value Customers' THEN 1
            WHEN s.rfm_segment = 'Mid-Value Customers' THEN 2
            WHEN s.rfm_segment = 'High-Value Customers' THEN 3
        END AS segment_rank,

        r.recency,
        r.frequency,
        r.monetary,
        r.average_order_value,
        r.units_purchased,

        COALESCE(b.orders_in_year, 0) AS orders_in_year,
        COALESCE(b.revenue_in_year, 0) AS revenue_in_year,
        COALESCE(b.units_in_year, 0) AS units_in_year,
        b.aov_in_year,
        b.median_days_between_purchases

    FROM rfm_features AS r
    INNER JOIN yearly_segment AS s
        ON r.customer_id = s.customer_id
        AND r.year = s.year

    INNER JOIN customer_first_order AS f
        ON r.customer_id = f.customer_id

    LEFT JOIN annual_behavior AS b
        ON r.customer_id = b.customer_id
        AND r.year = b.year
),

with_previous AS (
    SELECT
        *,
        LAG(segment) OVER (
            PARTITION BY customer_id
            ORDER BY year
        ) AS previous_segment,

        LAG(segment_rank) OVER (
            PARTITION BY customer_id
            ORDER BY year
        ) AS previous_segment_rank,

        LAG(year) OVER (
            PARTITION BY customer_id
            ORDER BY year
        ) AS previous_year

    FROM combined
)

SELECT
    customer_id,
    first_order_year,
    year,
    previous_year,
    previous_segment,
    segment,
    previous_segment_rank,
    segment_rank,

    CASE
        WHEN previous_year IS NULL THEN NULL
        WHEN year - previous_year <> 1 THEN NULL
        WHEN segment_rank > previous_segment_rank THEN 'Upgrade'
        WHEN segment_rank < previous_segment_rank THEN 'Downgrade'
        ELSE 'Stay'
    END AS movement,

    recency,
    frequency,
    monetary,
    average_order_value,
    units_purchased,
    orders_in_year,
    revenue_in_year,
    units_in_year,
    aov_in_year,
    median_days_between_purchases

FROM with_previous