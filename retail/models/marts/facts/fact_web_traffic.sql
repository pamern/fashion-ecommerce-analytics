select
    row_number() over (order by traffic_date, traffic_source) as web_traffic_key,
    to_char(traffic_date, 'YYYYMMDD')::integer as traffic_date_key,
    dense_rank() over (order by traffic_source) as traffic_source_key,
    sessions,
    unique_visitors,
    page_views,
    bounce_rate,
    avg_session_duration_seconds as avg_session_duration
from {{ ref('stg_web_traffic') }}
