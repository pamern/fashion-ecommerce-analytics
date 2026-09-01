with applied_promotions as (
    select
        order_id,
        product_id,
        promo_id,
        1 as promotion_sequence
    from {{ ref('stg_order_items') }}
    where promo_id is not null

    union all

    select
        order_id,
        product_id,
        secondary_promo_id as promo_id,
        2 as promotion_sequence
    from {{ ref('stg_order_items') }}
    where secondary_promo_id is not null
),

deduplicated_promotions as (
    select
        order_id,
        product_id,
        promo_id,
        min(promotion_sequence) as promotion_sequence
    from applied_promotions
    group by order_id, product_id, promo_id
),

fulfilled_promotions as (
    select promotions.*
    from deduplicated_promotions as promotions
    inner join {{ ref('stg_orders') }} as orders
        on promotions.order_id = orders.order_id
    where orders.order_status = 'delivered'
)

select
    sales.sales_key,
    promotions.promo_id
from fulfilled_promotions as promotions
inner join {{ ref('fact_sales') }} as sales
    on promotions.order_id = sales.order_id
    and promotions.product_id = sales.product_id
