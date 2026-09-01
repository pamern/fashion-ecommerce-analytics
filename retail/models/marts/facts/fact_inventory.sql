select
    row_number() over (order by snapshot_date, product_id) as inventory_key,
    to_char(snapshot_date, 'YYYYMMDD')::integer as shop_date_key,
    product_id,
    stock_on_hand,
    units_received,
    units_sold,
    stockout_days,
    days_of_supply,
    fill_rate,
    sell_through_rate,
    is_stockout as stockout_flag,
    requires_reorder as reorder_flag
from {{ ref('stg_inventory') }}
