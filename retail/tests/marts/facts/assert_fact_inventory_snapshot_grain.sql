select
    snapshot_date_key,
    product_key,
    count(*) as row_count
from {{ ref('fact_inventory_snapshot') }}
group by snapshot_date_key, product_key
having count(*) > 1
