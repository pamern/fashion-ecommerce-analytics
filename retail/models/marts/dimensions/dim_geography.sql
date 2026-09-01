select
    row_number() over (order by zip) as geography_key,
    zip,
    city,
    district,
    region
from {{ ref('stg_geography') }}
