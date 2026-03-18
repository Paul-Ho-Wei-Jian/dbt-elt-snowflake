select
    cast(id as varchar) as order_id,
    cast(customer as varchar) as customer_id,
    cast(ordered_at as date) as order_date,
    cast(order_total / 100.0 as number(38, 2)) as gross_revenue,
    cast(subtotal / 100.0 as number(38, 2)) as net_revenue
from {{ ref('raw_orders') }}
