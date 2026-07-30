select
    order_id,
    order_status,
    is_completed_order,
    is_returned_order,
    is_fulfilled_order
from {{ ref('int_orders_enriched') }}
where is_completed_order <> (order_status = 'delivered')
   or is_returned_order <> (order_status = 'returned')
   or is_fulfilled_order <> (
       order_status in ('delivered', 'returned')
   )
