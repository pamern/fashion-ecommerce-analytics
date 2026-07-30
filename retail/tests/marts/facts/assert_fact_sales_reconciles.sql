with expected as (
    select
        order_id,
        product_id as product_key,
        quantity,
        gross_sales,
        discount_amount,
        net_sales,
        cogs_amount,
        gross_profit
    from {{ ref('int_order_items_enriched') }}
    where is_completed_order
)

select
    coalesce(expected.order_id, actual.order_id) as order_id,
    coalesce(expected.product_key, actual.product_key) as product_key
from expected
full outer join {{ ref('fact_sales') }} as actual
    on expected.order_id = actual.order_id
    and expected.product_key = actual.product_key
where expected.order_id is null
   or actual.order_id is null
   or expected.quantity <> actual.quantity
   or abs(expected.gross_sales - actual.gross_sales) > 0.01
   or abs(expected.discount_amount - actual.discount_amount) > 0.01
   or abs(expected.net_sales - actual.net_sales) > 0.01
   or abs(expected.cogs_amount - actual.cogs_amount) > 0.01
   or abs(expected.gross_profit - actual.gross_profit) > 0.01
