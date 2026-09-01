select
    returns.return_id,
    returns.order_id,
    to_char(returns.return_date, 'YYYYMMDD')::integer
        as return_date_key,
    returns.product_id,
    orders.customer_id,
    orders.zip,
    returns.return_quantity,
    returns.refund_amount as return_amount,
    returns.return_reason
from {{ ref('stg_returns') }} as returns
inner join {{ ref('stg_orders') }} as orders
    on returns.order_id = orders.order_id
