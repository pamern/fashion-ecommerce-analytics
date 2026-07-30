select
    md5(promo_id) as promotion_key,
    promo_id,
    promo_name,
    promo_type,
    discount_value,
    start_date,
    end_date,
    applicable_category,
    promo_channel,
    is_stackable,
    min_order_value
from {{ ref('stg_promotions') }}
