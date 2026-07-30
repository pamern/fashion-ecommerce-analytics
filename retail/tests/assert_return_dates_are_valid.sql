select
    returns.return_id,
    returns.order_id,
    orders.order_date,
    returns.return_date
from {{ ref('stg_returns') }} as returns
inner join {{ ref('stg_orders') }} as orders
    on returns.order_id = orders.order_id
where returns.return_date < orders.order_date
