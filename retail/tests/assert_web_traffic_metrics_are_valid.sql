select
    traffic_date,
    sessions,
    unique_visitors,
    page_views
from {{ ref('stg_web_traffic') }}
where unique_visitors > sessions
   or sessions > page_views
