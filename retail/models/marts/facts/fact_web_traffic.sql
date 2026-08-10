select
    md5(
        concat_ws(
            '|',
            traffic_date::text,
            traffic_source
        )
    ) as web_traffic_key,
    to_char(traffic_date, 'YYYYMMDD')::integer as date_key,
    md5(traffic_source) as traffic_source_key,
    sessions,
    unique_visitors,
    page_views,
    bounce_rate,
    avg_session_duration_seconds
from {{ ref('stg_web_traffic') }}
