select
    order_id,
    to_char(order_date, 'YYYYMMDD')::integer as order_date_key,
    to_char(ship_date, 'YYYYMMDD')::integer as ship_date_key,
    to_char(delivery_date, 'YYYYMMDD')::integer as delivery_date_key,
    customer_id as customer_key,
    zip as geography_key,
    order_status,
    device_type,
    order_source,
    payment_method,
    payment_value,
    shipping_fee,
    installments,
    delivery_days
from {{ ref('int_orders_enriched') }}
