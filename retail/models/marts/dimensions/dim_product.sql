select
    row_number() over (order by product_id) as product_key,
    product_id,
    product_name,
    category,
    segment,
    size,
    color,
    price as list_price,
    cogs
from {{ ref('stg_products') }}
