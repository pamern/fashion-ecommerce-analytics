select
    order_id,
    product_id,
    count(*) as row_count
from {{ ref('fact_sales') }}
group by order_id, product_id
having count(*) > 1
