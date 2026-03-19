select
    {{ surrogate_key(["id", "sku", "name"]) }} as supply_row_key,
    cast(id as varchar) as supply_id,
    cast(name as varchar) as supply_name,
    cast(cost as number(38, 2)) as supply_cost,
    cast(perishable as boolean) as is_perishable,
    cast(sku as varchar) as product_id
from {{ ref('raw_supplies') }}
