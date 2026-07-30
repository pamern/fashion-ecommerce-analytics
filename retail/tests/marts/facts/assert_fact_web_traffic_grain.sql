select
    date_key,
    traffic_source_key,
    count(*) as row_count
from {{ ref('fact_web_traffic') }}
group by date_key, traffic_source_key
having count(*) > 1
