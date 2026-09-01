select
    shop_date_key,
    product_id,
    count(*) as row_count
from {{ ref('fact_inventory') }}
group by shop_date_key, product_id
having count(*) > 1
