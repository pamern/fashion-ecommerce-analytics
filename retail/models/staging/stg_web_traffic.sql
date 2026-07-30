select
    cast(date as date) as traffic_date,
    cast(sessions as integer) as sessions,
    cast(unique_visitors as integer) as unique_visitors,
    cast(page_views as integer) as page_views,
    cast(bounce_rate as double precision) as bounce_rate,
    cast(avg_session_duration_sec as double precision)
        as avg_session_duration_seconds,
    lower(trim(traffic_source)) as traffic_source
from {{ source('raw', 'web_traffic') }}
