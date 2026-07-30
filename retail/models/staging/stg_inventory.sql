select
    cast(snapshot_date as date) as snapshot_date,
    cast(product_id as bigint) as product_id,
    cast(stock_on_hand as integer) as stock_on_hand,
    cast(units_received as integer) as units_received,
    cast(units_sold as integer) as units_sold,
    cast(stockout_days as integer) as stockout_days,
    cast(days_of_supply as double precision) as days_of_supply,
    cast(fill_rate as double precision) as fill_rate,
    stockout_flag = 1 as is_stockout,
    overstock_flag = 1 as is_overstock,
    reorder_flag = 1 as requires_reorder,
    cast(sell_through_rate as double precision) as sell_through_rate,
    trim(product_name) as product_name,
    lower(trim(category)) as category,
    lower(trim(segment)) as segment,
    cast(year as integer) as year,
    cast(month as integer) as month
from {{ source('raw', 'inventory') }}
