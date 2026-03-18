select
    cast(id as varchar) as order_item_id,
    cast(order_id as varchar) as order_id,
    cast(sku as varchar) as product_id,
    cast(1 as number(38, 0)) as quantity
from {{ ref('raw_items') }}
