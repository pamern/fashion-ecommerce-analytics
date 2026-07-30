select
    customer_id,
    reference_date,
    total_order_count,
    completed_order_count,
    returned_order_count,
    cancelled_order_count,
    latest_order_date,
    days_since_latest_order,
    cancellation_rate,
    is_repeat_customer
from {{ ref('int_customer_metrics') }}
where completed_order_count > total_order_count
   or returned_order_count > total_order_count
   or cancelled_order_count > total_order_count
   or is_repeat_customer <> (completed_order_count > 1)
   or (
       latest_order_date is not null
       and days_since_latest_order <> reference_date - latest_order_date
   )
   or abs(
       cancellation_rate
       - cancelled_order_count::double precision
           / nullif(total_order_count, 0)
   ) > 0.000001
   or (
       total_order_count = 0
       and cancellation_rate <> 0
   )
