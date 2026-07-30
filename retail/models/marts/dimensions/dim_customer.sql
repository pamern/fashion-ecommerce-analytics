select
    customer_id as customer_key,
    customer_id,
    signup_date,
    gender,
    age_group,
    acquisition_channel
from {{ ref('stg_customers') }}
