with bounds as (
    select
        coalesce(min(order_date), current_date) as min_date,
        greatest(coalesce(max(order_date), current_date), current_date) as max_date
    from {{ ref('fct_orders') }}
),

date_seed as (
    select
        dateadd(day, seq4(), b.min_date) as date_day,
        b.max_date
    from bounds as b,
        table(generator(rowcount => 20000))
)

select
    date_day,
    to_number(to_char(date_day, 'YYYYMMDD')) as date_key,
    date_trunc('month', date_day) as month_start_date,
    last_day(date_day) as month_end_date,
    month(date_day) as month_of_year,
    year(date_day) as year_number
from date_seed
where date_day <= dateadd(day, 365, max_date)
