select
    customer_id,
    snapshot_month_end_date,
    is_new_first_ever_customer,
    is_repeat_customer,
    is_high_frequency_customer,
    is_high_value_customer
from {{ ref('int_customer_segment_rules_monthly') }}
