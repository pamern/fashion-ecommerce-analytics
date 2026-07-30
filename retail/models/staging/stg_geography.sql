select
    cast(zip as integer) as zip,
    initcap(trim(city)) as city,
    lower(trim(region)) as region,
    trim(district) as district
from {{ source('raw', 'geography') }}
