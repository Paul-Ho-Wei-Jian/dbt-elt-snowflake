with order_margin_by_order as (
    select
        order_id,
        sum(item_margin) as order_margin
    from {{ ref('int_order_margin') }}
    group by 1
)

select
    vo.order_id,
    vo.customer_id,
    vo.order_date,
    coalesce(vo.gross_revenue, 0) as gross_revenue,
    coalesce(vo.net_revenue, 0) as net_revenue,
    coalesce(omb.order_margin, 0) as order_margin
from {{ ref('int_valid_orders') }} as vo
left join order_margin_by_order as omb
    on vo.order_id = omb.order_id
