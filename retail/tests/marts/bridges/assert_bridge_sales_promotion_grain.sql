select
    sales_key,
    promo_id,
    count(*) as row_count
from {{ ref('bridge_sales_promotion') }}
group by sales_key, promo_id
having count(*) > 1
