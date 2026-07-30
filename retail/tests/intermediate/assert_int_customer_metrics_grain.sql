select
    customer_id,
    count(*) as row_count
from {{ ref('int_customer_metrics') }}
group by customer_id
having count(*) > 1
