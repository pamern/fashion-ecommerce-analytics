select
    traffic_date_key,
    traffic_source_key,
    count(*) as row_count
from {{ ref('fact_web_traffic') }}
group by traffic_date_key, traffic_source_key
having count(*) > 1
