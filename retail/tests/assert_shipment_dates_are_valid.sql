select
    shipments.order_id,
    orders.order_date,
    shipments.ship_date,
    shipments.delivery_date
from {{ ref('stg_shipments') }} as shipments
inner join {{ ref('stg_orders') }} as orders
    on shipments.order_id = orders.order_id
where shipments.ship_date < orders.order_date
   or shipments.delivery_date < shipments.ship_date
