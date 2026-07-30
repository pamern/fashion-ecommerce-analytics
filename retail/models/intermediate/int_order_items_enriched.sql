with order_items_aggregated as (
    select
        order_id,
        product_id,
        sum(quantity) as quantity,
        sum(unit_price * quantity) as gross_sales,
        sum(discount_amount) as discount_amount
    from {{ ref('stg_order_items') }}
    group by order_id, product_id
)

select
    order_items.order_id,
    order_items.product_id,
    orders.order_date,
    orders.customer_id,
    orders.zip,
    orders.order_status,
    orders.order_status = 'delivered' as is_completed_order,
    orders.order_status = 'returned' as is_returned_order,
    orders.order_status in ('delivered', 'returned') as is_fulfilled_order,
    order_items.quantity,
    order_items.gross_sales
        / nullif(order_items.quantity, 0)
        as average_unit_price,
    order_items.discount_amount,
    order_items.gross_sales,
    order_items.gross_sales - order_items.discount_amount as net_sales,
    order_items.quantity * products.cogs as cogs_amount,
    (
        order_items.gross_sales
        - order_items.discount_amount
        - order_items.quantity * products.cogs
    ) as gross_profit
from order_items_aggregated as order_items
inner join {{ ref('stg_orders') }} as orders
    on order_items.order_id = orders.order_id
inner join {{ ref('stg_products') }} as products
    on order_items.product_id = products.product_id
