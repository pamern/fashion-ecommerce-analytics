select
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_amount,
    promo_id,
    secondary_promo_id,
    count(*) as row_count
from {{ ref('stg_order_items') }}
group by
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_amount,
    promo_id,
    secondary_promo_id
having count(*) > 1
