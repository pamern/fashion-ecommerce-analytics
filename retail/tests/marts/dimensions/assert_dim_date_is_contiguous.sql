with date_range as (
    select
        min(date) as min_date,
        max(date) as max_date,
        count(*) as actual_day_count
    from {{ ref('dim_date') }}
)

select *
from date_range
where actual_day_count <> max_date - min_date + 1
