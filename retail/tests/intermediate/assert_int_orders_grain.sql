select
    order_id,
    count(*) as row_count
from {{ ref('int_orders_enriched') }}
group by order_id
having count(*) > 1
