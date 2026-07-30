with source_dates as (
    select signup_date as full_date
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
        min(full_date) as start_date,
        max(full_date) as end_date
    from source_dates
    where full_date is not null
),

date_spine as (
    select generate_series(
        start_date,
        end_date,
        interval '1 day'
    )::date as full_date
    from date_bounds
)

select
    to_char(full_date, 'YYYYMMDD')::integer as date_key,
    full_date,
    extract(day from full_date)::integer as day,
    extract(month from full_date)::integer as month,
    extract(quarter from full_date)::integer as quarter,
    extract(year from full_date)::integer as year,
    trim(to_char(full_date, 'Day')) as day_of_week,
    extract(isodow from full_date) in (6, 7) as is_weekend
from date_spine
