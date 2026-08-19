with reference_date as (
    select max(order_date) as reference_date
    from {{ ref('stg_orders') }}
),

fulfilled_order_items as (
    select
        items.customer_id,
        items.order_id,
        items.order_date,
        items.product_id,
        products.category,
        products.segment,
        items.quantity,
        items.gross_sales,
        items.discount_amount,
        items.net_sales,
        items.cogs_amount,
        items.gross_profit
    from {{ ref('int_order_items_enriched') }} as items
    inner join {{ ref('stg_products') }} as products
        on items.product_id = products.product_id
    where items.is_fulfilled_order
),

order_totals as (
    select
        customer_id,
        order_id,
        order_date,
        count(*) as order_line_count,
        sum(quantity) as quantity,
        sum(net_sales) as revenue,
        sum(discount_amount) as discount,
        sum(cogs_amount) as cogs,
        sum(gross_profit) as profit
    from fulfilled_order_items
    group by customer_id, order_id, order_date
),

purchase_metrics as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(*) as total_orders,
        sum(order_line_count) as total_order_lines,
        sum(quantity) as total_quantity,
        sum(revenue) as total_revenue,
        sum(discount) as total_discount,
        sum(cogs) as total_cogs,
        sum(profit) as total_profit,
        avg(revenue) as average_order_value,
        avg(profit) as average_profit_per_order
    from order_totals
    group by customer_id
),

order_gaps as (
    select
        customer_id,
        order_date - lag(order_date) over (
            partition by customer_id
            order by order_date, order_id
        ) as days_between_orders
    from order_totals
),

average_order_gaps as (
    select
        customer_id,
        avg(days_between_orders)::double precision as avg_days_between_orders
    from order_gaps
    where days_between_orders is not null
    group by customer_id
),

category_preferences_ranked as (
    select
        customer_id,
        category,
        row_number() over (
            partition by customer_id
            order by sum(quantity) desc, category
        ) as category_rank
    from fulfilled_order_items
    group by customer_id, category
),

segment_preferences_ranked as (
    select
        customer_id,
        segment,
        row_number() over (
            partition by customer_id
            order by sum(quantity) desc, segment
        ) as segment_rank
    from fulfilled_order_items
    group by customer_id, segment
),

favorite_categories as (
    select customer_id, category as favorite_category
    from category_preferences_ranked
    where category_rank = 1
),

favorite_segments as (
    select customer_id, segment as favorite_segment
    from segment_preferences_ranked
    where segment_rank = 1
),

payment_preferences_ranked as (
    select
        orders.customer_id,
        orders.payment_method,
        row_number() over (
            partition by orders.customer_id
            order by count(*) desc, orders.payment_method
        ) as payment_rank
    from {{ ref('stg_orders') }} as orders
    where orders.order_status in ('delivered', 'returned')
    group by orders.customer_id, orders.payment_method
),

device_preferences_ranked as (
    select
        orders.customer_id,
        orders.device_type,
        row_number() over (
            partition by orders.customer_id
            order by count(*) desc, orders.device_type
        ) as device_rank
    from {{ ref('stg_orders') }} as orders
    where orders.order_status in ('delivered', 'returned')
    group by orders.customer_id, orders.device_type
),

source_preferences_ranked as (
    select
        orders.customer_id,
        orders.order_source,
        row_number() over (
            partition by orders.customer_id
            order by count(*) desc, orders.order_source
        ) as source_rank
    from {{ ref('stg_orders') }} as orders
    where orders.order_status in ('delivered', 'returned')
    group by orders.customer_id, orders.order_source
),

favorite_payments as (
    select customer_id, payment_method as favorite_payment_method
    from payment_preferences_ranked
    where payment_rank = 1
),

favorite_devices as (
    select customer_id, device_type as favorite_device
    from device_preferences_ranked
    where device_rank = 1
),

favorite_sources as (
    select customer_id, order_source as favorite_order_source
    from source_preferences_ranked
    where source_rank = 1
),

return_metrics as (
    select
        orders.customer_id,
        count(distinct returns.order_id) as total_return_orders,
        sum(returns.return_quantity) as returned_items,
        sum(returns.refund_amount) as refund_amount
    from {{ ref('stg_returns') }} as returns
    inner join {{ ref('stg_orders') }} as orders
        on returns.order_id = orders.order_id
    group by orders.customer_id
),

review_metrics as (
    select
        customer_id,
        count(*) as review_count,
        avg(rating)::double precision as average_rating
    from {{ ref('stg_reviews') }}
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
        coalesce(purchases.last_order_date - purchases.first_order_date, 0)
            as customer_lifetime_days,
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
        coalesce(purchases.total_order_lines, 0) as total_order_lines,
        coalesce(purchases.total_quantity, 0) as total_quantity,
        coalesce(purchases.total_revenue, 0) as total_revenue,
        coalesce(purchases.total_discount, 0) as total_discount,
        coalesce(purchases.total_cogs, 0) as total_cogs,
        coalesce(purchases.total_profit, 0) as total_profit,
        coalesce(purchases.average_order_value, 0) as average_order_value,
        coalesce(purchases.average_profit_per_order, 0)
            as average_profit_per_order,
        coalesce(purchases.total_orders, 0) >= 2 as is_repeat_customer,
        coalesce(
            purchases.total_profit::double precision
                / nullif(purchases.total_revenue, 0),
            0
        ) as gross_margin_rate,
        case
            when purchases.total_orders >= 2 then
                purchases.total_orders * 30.0
                    / greatest(
                        reference_date.reference_date
                            - purchases.first_order_date,
                        1
                    )
        end as orders_per_30_days,
        gaps.avg_days_between_orders,
        categories.favorite_category,
        segments.favorite_segment,
        payments.favorite_payment_method,
        devices.favorite_device,
        sources.favorite_order_source,
        coalesce(returns.total_return_orders, 0) as total_return_orders,
        coalesce(
            returns.total_return_orders::double precision
                / nullif(purchases.total_orders, 0),
            0
        ) as return_order_rate,
        coalesce(returns.returned_items, 0) as returned_items,
        coalesce(
            returns.returned_items::double precision
                / nullif(purchases.total_quantity, 0),
            0
        ) as return_rate,
        coalesce(returns.refund_amount, 0) as refund_amount,
        coalesce(reviews.review_count, 0) as review_count,
        reviews.average_rating
    from {{ ref('stg_customers') }} as customers
    left join {{ ref('stg_geography') }} as geography
        on customers.zip = geography.zip
    cross join reference_date
    left join purchase_metrics as purchases
        on customers.customer_id = purchases.customer_id
    left join average_order_gaps as gaps
        on customers.customer_id = gaps.customer_id
    left join favorite_categories as categories
        on customers.customer_id = categories.customer_id
    left join favorite_segments as segments
        on customers.customer_id = segments.customer_id
    left join favorite_payments as payments
        on customers.customer_id = payments.customer_id
    left join favorite_devices as devices
        on customers.customer_id = devices.customer_id
    left join favorite_sources as sources
        on customers.customer_id = sources.customer_id
    left join return_metrics as returns
        on customers.customer_id = returns.customer_id
    left join review_metrics as reviews
        on customers.customer_id = reviews.customer_id
),

rfm_scored as (
    select
        customer_id,
        ntile(5) over (order by days_since_last_purchase desc, customer_id)
            as recency,
        ntile(5) over (order by total_orders, customer_id) as frequency,
        ntile(5) over (order by total_revenue, customer_id)
            as monetary
    from customer_metrics
    where total_orders > 0
)

select
    metrics.customer_id as customer_key,
    metrics.*,
    coalesce(rfm.recency, 0) as recency,
    coalesce(rfm.frequency, 0) as frequency,
    coalesce(rfm.monetary, 0) as monetary,
    concat(
        coalesce(rfm.recency, 0),
        coalesce(rfm.frequency, 0),
        coalesce(rfm.monetary, 0)
    ) as rfm_score,
    case
        when rfm.customer_id is null then 'prospect'
        when rfm.recency >= 4 and rfm.frequency >= 4
            and rfm.monetary >= 4 then 'champions'
        when rfm.recency >= 3 and rfm.frequency >= 4 then 'loyal_customers'
        when rfm.recency >= 3 and rfm.frequency >= 3
            then 'potential_loyalists'
        when rfm.recency >= 4 and rfm.frequency <= 2 then 'promising'
        when rfm.recency <= 2 and rfm.frequency >= 3 then 'at_risk'
        when rfm.recency <= 2 and rfm.frequency <= 2 then 'hibernating'
        else 'needs_attention'
    end as rfm_segment,
    customer_segments.segment_name
from customer_metrics as metrics
left join rfm_scored as rfm
    on metrics.customer_id = rfm.customer_id
left join {{ ref('int_customer_segement') }} as customer_segments
    on metrics.customer_id = customer_segments.customer_id
