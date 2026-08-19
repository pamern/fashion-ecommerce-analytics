with reference_date as (
    select max(order_date) as reference_date
    from {{ ref('stg_orders') }}
),

order_totals as (
    select
        customer_id,
        order_id,
        order_date,
        sum(quantity) as quantity,
        sum(net_sales) as revenue
    from {{ ref('int_order_items_enriched') }}
    where is_fulfilled_order
    group by customer_id, order_id, order_date
),

purchase_metrics as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(*) as total_orders,
        sum(quantity) as total_quantity,
        sum(revenue) as total_revenue,
        avg(revenue) as average_order_value
    from order_totals
    group by customer_id
),

customer_metrics as (
    select
        customers.customer_id,
        customers.signup_date,
        customers.gender,
        customers.age_group,
        customers.acquisition_channel,
        geography.city,
        geography.district,
        geography.region,
        purchases.first_order_date,
        purchases.last_order_date,
        case
            when purchases.last_order_date is not null
                then reference_date.reference_date - purchases.last_order_date
        end as days_since_last_purchase,
        case
            when purchases.last_order_date is null then 'prospect'
            when reference_date.reference_date - purchases.last_order_date <= 30
                then 'active'
            when reference_date.reference_date - purchases.last_order_date <= 90
                then 'at_risk'
            else 'churned'
        end as customer_status,
        coalesce(purchases.total_orders, 0) as total_orders,
        coalesce(purchases.total_quantity, 0) as total_quantity,
        coalesce(purchases.total_revenue, 0) as total_revenue,
        coalesce(purchases.average_order_value, 0) as average_order_value,
        coalesce(purchases.total_orders, 0) >= 2 as is_repeat_customer
    from {{ ref('stg_customers') }} as customers
    left join {{ ref('stg_geography') }} as geography
        on customers.zip = geography.zip
    cross join reference_date
    left join purchase_metrics as purchases
        on customers.customer_id = purchases.customer_id
)

select
    metrics.customer_id as customer_key,
    metrics.customer_id,
    metrics.signup_date,
    metrics.gender,
    metrics.age_group,
    metrics.acquisition_channel,
    metrics.city,
    metrics.district,
    metrics.region,
    metrics.first_order_date,
    metrics.last_order_date,
    metrics.days_since_last_purchase,
    metrics.customer_status,
    metrics.total_orders,
    metrics.total_quantity,
    metrics.total_revenue,
    metrics.average_order_value,
    metrics.is_repeat_customer,
    customer_segments.rfm_segment
from customer_metrics as metrics
left join {{ ref('int_customer_segement') }} as customer_segments
    on metrics.customer_id = customer_segments.customer_id
