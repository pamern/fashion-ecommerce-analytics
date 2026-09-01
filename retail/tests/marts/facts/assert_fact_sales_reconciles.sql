with expected as (
    select
        order_id,
        product_id,
        quantity,
        gross_sales,
        discount_amount,
        net_sales,
        cogs_amount
    from {{ ref('int_order_items_enriched') }}
    where is_completed_order
)

select
    coalesce(expected.order_id, actual.order_id) as order_id,
    coalesce(expected.product_id, actual.product_id) as product_id
from expected
full outer join {{ ref('fact_sales') }} as actual
    on expected.order_id = actual.order_id
    and expected.product_id = actual.product_id
where expected.order_id is null
   or actual.order_id is null
   or expected.quantity <> actual.quantity
   or abs(expected.gross_sales - actual.gross_sales) > 0.01
   or abs(expected.discount_amount - actual.discount_amount) > 0.01
   or abs(expected.net_sales - actual.net_sales) > 0.01
   or abs(expected.cogs_amount - actual.cogs_amount) > 0.01
