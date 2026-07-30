with date_range as (
    select
        min(full_date) as min_date,
        max(full_date) as max_date,
        count(*) as actual_day_count
    from {{ ref('dim_date') }}
)

select *
from date_range
where actual_day_count <> max_date - min_date + 1
