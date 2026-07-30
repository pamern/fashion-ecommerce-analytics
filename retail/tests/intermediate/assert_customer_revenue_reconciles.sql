with expected_metrics as (
    select
        customer_id,
        sum(quantity) as lifetime_order_quantity,
        sum(gross_sales) as lifetime_gross_sales,
        sum(net_sales) as lifetime_net_sales,
        sum(gross_profit) as lifetime_gross_profit
    from {{ ref('int_order_items_enriched') }}
    where is_completed_order
    group by customer_id
)

select
    customers.customer_id,
    customers.lifetime_order_quantity,
    expected.lifetime_order_quantity as expected_order_quantity,
    customers.lifetime_gross_sales,
    expected.lifetime_gross_sales as expected_gross_sales,
    customers.lifetime_net_sales,
    expected.lifetime_net_sales as expected_net_sales,
    customers.lifetime_gross_profit,
    expected.lifetime_gross_profit as expected_gross_profit
from {{ ref('int_customer_metrics') }} as customers
left join expected_metrics as expected
    on customers.customer_id = expected.customer_id
where customers.lifetime_order_quantity
        <> coalesce(expected.lifetime_order_quantity, 0)
   or abs(
       customers.lifetime_gross_sales
       - coalesce(expected.lifetime_gross_sales, 0)
   ) > 0.01
   or abs(
       customers.lifetime_net_sales
       - coalesce(expected.lifetime_net_sales, 0)
   ) > 0.01
   or abs(
       customers.lifetime_gross_profit
       - coalesce(expected.lifetime_gross_profit, 0)
   ) > 0.01
