with metrics as (
    select *
    from {{ ref('int_customer_metrics_monthly') }}
),

percentiles as (
    select
        metrics.*,
        cume_dist() over (
            partition by snapshot_month_end_date
            order by coalesce(orders_last_90d, 0)
        ) as order_count_percentile_90d,
        cume_dist() over (
            partition by snapshot_month_end_date
            order by coalesce(lifetime_net_revenue, 0)
        ) as revenue_percentile_lifetime
    from metrics
)

select
    customer_id,
    snapshot_month_end_date,
    snapshot_month_key,
    first_ever_order_date,
    most_recent_order_date,
    days_since_last_order,
    lifetime_orders,
    lifetime_gross_revenue,
    lifetime_net_revenue,
    orders_last_30d,
    orders_last_90d,
    orders_last_365d,
    net_revenue_last_30d,
    net_revenue_last_90d,
    net_revenue_last_365d,
    is_active_last_30d,
    is_active_last_90d,
    is_active_last_365d,
    datediff(day, first_ever_order_date, snapshot_month_end_date) <= 30 as is_new_first_ever_customer,
    orders_last_365d > 1 as is_repeat_customer,
    order_count_percentile_90d >= 0.80 as is_high_frequency_customer,
    revenue_percentile_lifetime >= 0.80 as is_high_value_customer
from percentiles
