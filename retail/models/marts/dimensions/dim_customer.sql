select
    row_number() over (order by customer_id) as customer_key,
    customer_id,
    signup_date,
    gender,
    age_group,
    acquisition_channel,
    zip
from {{ ref('stg_customers') }}
