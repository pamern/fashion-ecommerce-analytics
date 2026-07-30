with source_totals as (
    select
        order_id,
        product_id,
        sum(quantity) as quantity,
        sum(unit_price * quantity) as gross_sales,
        sum(discount_amount) as discount_amount
    from {{ ref('stg_order_items') }}
    group by order_id, product_id
),

intermediate_totals as (
    select
        order_id,
        product_id,
        quantity,
        gross_sales,
        discount_amount
    from {{ ref('int_order_items_enriched') }}
)

select
    coalesce(source.order_id, intermediate.order_id) as order_id,
    coalesce(source.product_id, intermediate.product_id) as product_id,
    source.quantity as source_quantity,
    intermediate.quantity as intermediate_quantity,
    source.gross_sales as source_gross_sales,
    intermediate.gross_sales as intermediate_gross_sales,
    source.discount_amount as source_discount_amount,
    intermediate.discount_amount as intermediate_discount_amount
from source_totals as source
full outer join intermediate_totals as intermediate
    on source.order_id = intermediate.order_id
    and source.product_id = intermediate.product_id
where source.order_id is null
   or intermediate.order_id is null
   or source.quantity <> intermediate.quantity
   or abs(source.gross_sales - intermediate.gross_sales) > 0.01
   or abs(source.discount_amount - intermediate.discount_amount) > 0.01
