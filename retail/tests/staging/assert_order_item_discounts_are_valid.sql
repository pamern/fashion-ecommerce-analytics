select
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_amount
from {{ ref('stg_order_items') }}
where discount_amount > unit_price * quantity
