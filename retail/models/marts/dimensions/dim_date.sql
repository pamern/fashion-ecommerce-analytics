with source_dates as (
    select signup_date as date
    from {{ ref('stg_customers') }}

    union all

    select order_date
    from {{ ref('stg_orders') }}

    union all

    select ship_date
    from {{ ref('stg_shipments') }}

    union all

    select delivery_date
    from {{ ref('stg_shipments') }}

    union all

    select return_date
    from {{ ref('stg_returns') }}

    union all

    select review_date
    from {{ ref('stg_reviews') }}

    union all

    select snapshot_date
    from {{ ref('stg_inventory') }}

    union all

    select traffic_date
    from {{ ref('stg_web_traffic') }}

    union all

    select start_date
    from {{ ref('stg_promotions') }}

    union all

    select end_date
    from {{ ref('stg_promotions') }}
),

date_bounds as (
    select
        min(date) as start_date,
        max(date) as end_date
    from source_dates
    where date is not null
),

date_spine as (
    select generate_series(
        start_date,
        end_date,
        interval '1 day'
    )::date as date
    from date_bounds
)

select
    to_char(date, 'YYYYMMDD')::integer as date_key,
    date,
    extract(day from date)::integer as day,
    extract(month from date)::integer as month,
    to_char(date, 'YYYY-MM') as year_month,
    extract(quarter from date)::integer as quarter,
    extract(year from date)::integer as year,
    trim(to_char(date, 'Day')) as day_of_week,
    extract(isodow from date) in (6, 7) as is_weekend
from date_spine
