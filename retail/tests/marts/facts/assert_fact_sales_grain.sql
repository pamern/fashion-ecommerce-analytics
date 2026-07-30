select
    order_id,
    product_key,
    count(*) as row_count
from {{ ref('fact_sales') }}
group by order_id, product_key
having count(*) > 1
