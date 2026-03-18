select
    order_id,
    customer_id,
    order_date,
    gross_revenue,
    net_revenue
from {{ ref('stg_orders') }}
