select
    coalesce(expected.order_id, actual.order_id) as order_id
from {{ ref('int_orders_enriched') }} as expected
full outer join {{ ref('fact_order') }} as actual
    on expected.order_id = actual.order_id
where expected.order_id is null
   or actual.order_id is null
   or expected.order_status is distinct from actual.order_status
   or expected.shipping_fee is distinct from actual.shipping_fee
   or expected.installments is distinct from actual.installments
   or expected.delivery_days is distinct from actual.delivery_days
