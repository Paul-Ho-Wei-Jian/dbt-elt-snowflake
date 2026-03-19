select
    cast(sku as varchar) as product_id,
    cast(name as varchar) as product_name,
    cast(type as varchar) as product_type,
    cast(price as number(38, 2)) as unit_price,
    cast(description as varchar) as product_description
from {{ ref('raw_products') }}
