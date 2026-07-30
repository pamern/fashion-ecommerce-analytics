with order_sales as (
    select
        order_id,
        sum(quantity) as order_quantity,
        sum(gross_sales) as gross_sales,
        sum(net_sales) as net_sales,
        sum(gross_profit) as gross_profit
    from {{ ref('int_order_items_enriched') }}
    group by order_id
),

orders as (
    select
        orders.order_id,
        orders.order_date,
        orders.customer_id,
        orders.order_status,
        orders.is_completed_order,
        orders.is_returned_order,
        order_sales.order_quantity,
        order_sales.gross_sales,
        order_sales.net_sales,
        order_sales.gross_profit
    from {{ ref('int_orders_enriched') }} as orders
    left join order_sales
        on orders.order_id = order_sales.order_id
),

data_reference as (
    select max(order_date) as reference_date
    from orders
),

customer_orders as (
    select
        customer_id,
        count(distinct order_id) as total_order_count,
        count(distinct order_id) filter (
            where is_completed_order
        ) as completed_order_count,
        count(distinct order_id) filter (
            where is_returned_order
        ) as returned_order_count,
        count(distinct order_id) filter (
            where order_status = 'cancelled'
        ) as cancelled_order_count,
        min(order_date) as first_order_date,
        max(order_date) as latest_order_date,
        min(order_date) filter (
            where is_completed_order
        ) as first_completed_order_date,
        max(order_date) filter (
            where is_completed_order
        ) as latest_completed_order_date,
        sum(order_quantity) filter (
            where is_completed_order
        ) as lifetime_order_quantity,
        sum(gross_sales) filter (
            where is_completed_order
        ) as lifetime_gross_sales,
        sum(net_sales) filter (
            where is_completed_order
        ) as lifetime_net_sales,
        sum(gross_profit) filter (
            where is_completed_order
        ) as lifetime_gross_profit,
        avg(net_sales) filter (
            where is_completed_order
        ) as average_order_value
    from orders
    group by customer_id
)

select
    customers.customer_id,
    customers.signup_date,
    customers.gender,
    customers.age_group,
    customers.acquisition_channel,
    data_reference.reference_date,
    coalesce(customer_orders.total_order_count, 0) as total_order_count,
    coalesce(customer_orders.completed_order_count, 0)
        as completed_order_count,
    coalesce(customer_orders.returned_order_count, 0)
        as returned_order_count,
    coalesce(customer_orders.cancelled_order_count, 0)
        as cancelled_order_count,
    customer_orders.first_order_date,
    customer_orders.latest_order_date,
    customer_orders.first_completed_order_date,
    customer_orders.latest_completed_order_date,
    data_reference.reference_date
        - customer_orders.latest_order_date
        as days_since_latest_order,
    data_reference.reference_date
        - customers.signup_date
        as customer_tenure_days,
    coalesce(
        customer_orders.cancelled_order_count::double precision
            / nullif(customer_orders.total_order_count, 0),
        0
    ) as cancellation_rate,
    coalesce(customer_orders.lifetime_order_quantity, 0)
        as lifetime_order_quantity,
    coalesce(customer_orders.lifetime_gross_sales, 0)
        as lifetime_gross_sales,
    coalesce(customer_orders.lifetime_net_sales, 0)
        as lifetime_net_sales,
    coalesce(customer_orders.lifetime_gross_profit, 0)
        as lifetime_gross_profit,
    coalesce(customer_orders.average_order_value, 0)
        as average_order_value,
    coalesce(customer_orders.completed_order_count, 0) > 1
        as is_repeat_customer
from {{ ref('stg_customers') }} as customers
cross join data_reference
left join customer_orders
    on customers.customer_id = customer_orders.customer_id
