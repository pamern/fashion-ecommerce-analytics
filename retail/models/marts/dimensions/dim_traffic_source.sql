select
    md5(traffic_source) as traffic_source_key,
    traffic_source
from {{ ref('stg_web_traffic') }}
group by traffic_source
