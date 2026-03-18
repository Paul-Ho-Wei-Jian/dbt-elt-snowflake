with supply_cost_by_product as (
    select
        product_id,
        sum(coalesce(supply_cost, 0)) as item_cost
    from {{ ref('stg_supplies') }}
    group by 1
)

select
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    coalesce(oi.quantity, 0) as quantity,
    coalesce(p.unit_price, 0) * coalesce(oi.quantity, 0) as item_gross_revenue,
    coalesce(sc.item_cost, 0) * coalesce(oi.quantity, 0) as item_cost,
    (coalesce(p.unit_price, 0) - coalesce(sc.item_cost, 0)) * coalesce(oi.quantity, 0) as item_margin
from {{ ref('stg_order_items') }} as oi
inner join {{ ref('int_valid_orders') }} as vo
    on oi.order_id = vo.order_id
left join {{ ref('stg_products') }} as p
    on oi.product_id = p.product_id
left join supply_cost_by_product as sc
    on oi.product_id = sc.product_id
