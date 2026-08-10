select
    md5(
        concat_ws(
            '|',
            order_id::text,
            product_id::text
        )
    ) as sales_key,
    md5(order_id::text) as order_key,
    order_id,
    to_char(order_date, 'YYYYMMDD')::integer as date_key,
    product_id as product_key,
    customer_id as customer_key,
    zip as geography_key,
    quantity,
    average_unit_price as unit_price,
    discount_amount,
    gross_sales,
    net_sales,
    cogs_amount,
    gross_profit
from {{ ref('int_order_items_enriched') }}
where is_completed_order
