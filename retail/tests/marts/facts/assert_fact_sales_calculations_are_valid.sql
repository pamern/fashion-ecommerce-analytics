select
    sales_key,
    order_id,
    product_key,
    quantity,
    unit_price,
    gross_sales,
    discount_amount,
    net_sales,
    cogs_amount,
    gross_profit
from {{ ref('fact_sales') }}
where abs(gross_sales - unit_price * quantity) > 0.01
   or abs(net_sales - (gross_sales - discount_amount)) > 0.01
   or abs(gross_profit - (net_sales - cogs_amount)) > 0.01
   or discount_amount > gross_sales
