select
    cast(customer_id as bigint) as customer_id,
    cast(zip as integer) as zip,
    initcap(trim(city)) as city,
    cast(signup_date as date) as signup_date,
    lower(trim(gender)) as gender,
    trim(age_group) as age_group,
    lower(trim(acquisition_channel)) as acquisition_channel
from {{ source('raw', 'customers') }}
