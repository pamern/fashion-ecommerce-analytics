select
    date_key,
    traffic_source_key,
    sessions,
    unique_visitors,
    page_views
from {{ ref('fact_web_traffic') }}
where unique_visitors > sessions
   or sessions > page_views
