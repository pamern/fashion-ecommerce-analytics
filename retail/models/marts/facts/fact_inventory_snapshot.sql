select
    md5(
        concat_ws(
            '|',
            snapshot_date::text,
            product_id::text
        )
    ) as inventory_snapshot_key,
    to_char(snapshot_date, 'YYYYMMDD')::integer as snapshot_date_key,
    product_id as product_key,
    stock_on_hand,
    units_received,
    units_sold,
    stockout_days,
    days_of_supply,
    fill_rate,
    sell_through_rate,
    is_stockout as stockout_flag,
    is_overstock as overstock_flag,
    requires_reorder as reorder_flag
from {{ ref('stg_inventory') }}
