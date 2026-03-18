select
    customer_id,
    snapshot_month_end_date,
    count(*) as row_count
from {{ ref('int_customer_month_spine') }}
group by 1, 2
having count(*) > 1
