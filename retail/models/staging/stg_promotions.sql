select
    trim(promo_id) as promo_id,
    trim(promo_name) as promo_name,
    lower(trim(promo_type)) as promo_type,
    cast(discount_value as double precision) as discount_value,
    cast(start_date as date) as start_date,
    cast(end_date as date) as end_date,
    lower(nullif(trim(applicable_category), '')) as applicable_category,
    lower(trim(promo_channel)) as promo_channel,
    stackable_flag = 1 as is_stackable,
    cast(min_order_value as integer) as min_order_value
from {{ source('raw', 'promotions') }}
