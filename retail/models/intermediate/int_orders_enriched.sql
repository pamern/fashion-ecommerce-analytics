select
    orders.order_id,
    orders.order_date,
    shipments.ship_date,
    shipments.delivery_date,
    orders.customer_id,
    orders.zip,
    orders.order_status,
    orders.device_type,
    orders.order_source,
    coalesce(payments.payment_method, orders.payment_method)
        as payment_method,
    payments.payment_value,
    shipments.shipping_fee,
    payments.installments,
    shipments.delivery_date - orders.order_date as delivery_days,
    orders.order_status = 'delivered' as is_completed_order,
    orders.order_status = 'returned' as is_returned_order,
    orders.order_status in ('delivered', 'returned') as is_fulfilled_order
from {{ ref('stg_orders') }} as orders
left join {{ ref('stg_payments') }} as payments
    on orders.order_id = payments.order_id
left join {{ ref('stg_shipments') }} as shipments
    on orders.order_id = shipments.order_id
