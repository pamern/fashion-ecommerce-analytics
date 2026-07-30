select
    cast(order_id as bigint) as order_id,
    cast(ship_date as date) as ship_date,
    cast(delivery_date as date) as delivery_date,
    cast(shipping_fee as double precision) as shipping_fee
from {{ source('raw', 'shipments') }}
