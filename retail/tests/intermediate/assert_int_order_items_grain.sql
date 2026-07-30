select
    order_id,
    product_id,
    count(*) as row_count
from {{ ref('int_order_items_enriched') }}
group by order_id, product_id
having count(*) > 1
