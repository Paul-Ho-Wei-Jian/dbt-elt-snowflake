select
    customer_id,
    snapshot_month_end_date,
    count(*) as row_count
from {{ ref('int_customer_monthly_snapshot_spine') }}
group by 1, 2
having count(*) > 1
