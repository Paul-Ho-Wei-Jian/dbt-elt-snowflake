select
    customer_id,
    min(order_date) as first_ever_order_date,
    max(order_date) as most_recent_order_date
from {{ ref('fct_orders') }}
group by 1
