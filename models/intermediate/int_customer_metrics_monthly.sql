with
spine as (
    select *
    from {{ ref('int_customer_monthly_snapshot_spine') }}
)

select
    s.customer_id,
    s.snapshot_month_end_date,
    s.snapshot_month_key,
    min(case when o.order_date <= s.snapshot_month_end_date then o.order_date end) as first_ever_order_date,
    max(case when o.order_date <= s.snapshot_month_end_date then o.order_date end) as most_recent_order_date,
    datediff(
        day,
        max(case when o.order_date <= s.snapshot_month_end_date then o.order_date end),
        s.snapshot_month_end_date
    ) as days_since_last_order,
    count(distinct case when o.order_date <= s.snapshot_month_end_date then o.order_id end) as lifetime_orders,
    sum(case when o.order_date <= s.snapshot_month_end_date then o.gross_revenue else 0 end) as lifetime_gross_revenue,
    sum(case when o.order_date <= s.snapshot_month_end_date then o.net_revenue else 0 end) as lifetime_net_revenue,
    count(distinct case when o.order_date between dateadd(day, -30, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.order_id end) as orders_last_30d,
    count(distinct case when o.order_date between dateadd(day, -90, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.order_id end) as orders_last_90d,
    count(distinct case when o.order_date between dateadd(day, -365, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.order_id end) as orders_last_365d,
    sum(case when o.order_date between dateadd(day, -30, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.net_revenue else 0 end) as net_revenue_last_30d,
    sum(case when o.order_date between dateadd(day, -90, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.net_revenue else 0 end) as net_revenue_last_90d,
    sum(case when o.order_date between dateadd(day, -365, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.net_revenue else 0 end) as net_revenue_last_365d,
    count(distinct case when o.order_date between dateadd(day, -30, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.order_id end) > 0 as is_active_last_30d,
    count(distinct case when o.order_date between dateadd(day, -90, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.order_id end) > 0 as is_active_last_90d,
    count(distinct case when o.order_date between dateadd(day, -365, s.snapshot_month_end_date) and s.snapshot_month_end_date then o.order_id end) > 0 as is_active_last_365d
from spine as s
left join {{ ref('fct_orders') }} as o
    on s.customer_id = o.customer_id
group by 1, 2, 3
