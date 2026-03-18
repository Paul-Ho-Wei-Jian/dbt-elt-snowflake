select
    customer_id,
    snapshot_month_end_date,
    count(*) as row_count
from {{ ref('mart_customer_segments_monthly') }}
group by 1, 2
having count(*) > 1
