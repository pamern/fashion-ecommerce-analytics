select
    row_number() over (order by order_id, product_id) as sales_key,
    order_id,
    to_char(order_date, 'YYYYMMDD')::integer as date_key,
    product_id,
    customer_id,
    zip,
    quantity,
    average_unit_price as unit_price,
    discount_amount,
    gross_sales,
    net_sales,
    cogs_amount
from {{ ref('int_order_items_enriched') }}
where is_completed_order
