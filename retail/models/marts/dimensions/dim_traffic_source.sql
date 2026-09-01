select
    row_number() over (order by traffic_source) as traffic_source_key,
    traffic_source
from {{ ref('stg_web_traffic') }}
group by traffic_source
