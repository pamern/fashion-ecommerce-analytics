select
    cast(product_id as bigint) as product_id,
    trim(product_name) as product_name,
    lower(trim(category)) as category,
    lower(trim(segment)) as segment,
    upper(trim(size)) as size,
    lower(trim(color)) as color,
    cast(price as double precision) as price,
    cast(cogs as double precision) as cogs
from {{ source('raw', 'products') }}
