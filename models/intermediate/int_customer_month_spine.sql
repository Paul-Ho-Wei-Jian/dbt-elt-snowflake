with customer_bounds as (
    select
        customer_id,
        date_trunc('month', min(order_date)) as first_order_month
    from {{ ref('int_valid_orders') }}
    group by 1
),

month_seed as (
    select
        dateadd(month, seq4(), (select min(first_order_month) from customer_bounds)) as month_start_date
    from table(generator(rowcount => 2400))
),

month_series as (
    select
        last_day(month_start_date) as snapshot_month_end_date
    from month_seed
    where month_start_date <= date_trunc('month', current_date)
)

select
    cb.customer_id,
    ms.snapshot_month_end_date,
    to_number(to_char(ms.snapshot_month_end_date, 'YYYYMMDD')) as snapshot_month_key
from customer_bounds as cb
inner join month_series as ms
    on ms.snapshot_month_end_date >= last_day(cb.first_order_month)
