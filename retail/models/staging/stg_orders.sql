select
    cast(order_id as bigint) as order_id,
    cast(order_date as date) as order_date,
    cast(customer_id as bigint) as customer_id,
    cast(zip as integer) as zip,
    lower(trim(order_status)) as order_status,
    lower(trim(payment_method)) as payment_method,
    lower(trim(device_type)) as device_type,
    lower(trim(order_source)) as order_source
from {{ source('raw', 'orders') }}
