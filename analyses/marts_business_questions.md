# Marts Business Questions

This document explains what business questions each marts-layer table can answer and how the table is derived.

## `fct_orders`

**Business questions it answers**

- How many orders were placed?
- How much gross revenue, net revenue, and margin did orders generate?
- Which customers are driving order activity over time?
- What is the order-level base table for customer reporting?

**How the logic is written**

- The table is built in [`/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/facts/fct_orders.sql`](/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/facts/fct_orders.sql).
- It starts from `int_valid_orders`, which provides the basic order grain:
  - `order_id`
  - `customer_id`
  - `order_date`
  - `gross_revenue`
  - `net_revenue`
- It then joins in aggregated order margin from `int_order_margin`.
- `order_margin` is calculated by summing all item-level margins for each `order_id`.
- The final output is one row per order.

## `dim_customer`

**Business questions it answers**

- Who are the customers in the reporting layer?
- When did each customer first purchase?
- When did each customer most recently purchase?

**How the logic is written**

- The table is built in [`/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/dimensions/dim_customer.sql`](/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/dimensions/dim_customer.sql).
- It reads directly from `fct_orders`.
- For each `customer_id`, it calculates:
  - `first_ever_order_date` as the earliest `order_date`
  - `most_recent_order_date` as the latest `order_date`
- The final output is one row per customer.

## `dim_date`

**Business questions it answers**

- What date attributes should reports use for filtering and grouping?
- How do we standardize calendar reporting by day, month, and year?

**How the logic is written**

- The table is built in [`/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/dimensions/dim_date.sql`](/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/dimensions/dim_date.sql).
- It reads the minimum and maximum `order_date` from `fct_orders`.
- From those bounds, it generates a continuous date series and extends it to 365 days past the latest order date.
- It derives standard reporting fields such as:
  - `date_key`
  - `month_start_date`
  - `month_end_date`
  - `month_of_year`
  - `year_number`
- The final output is one row per calendar date.

## `mart_customer_metrics_monthly`

**Business questions it answers**

- How is each customer performing at the end of each month?
- What are each customer’s lifetime orders, revenue, and margin as of a given month-end?
- How active was each customer in the last 30, 90, and 365 days relative to a month-end snapshot?
- Which customers are currently active or inactive?

**How the logic is written**

- The table is built in [`/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/customer/mart_customer_metrics_monthly.sql`](/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/customer/mart_customer_metrics_monthly.sql), which publishes the output of `int_customer_metrics_monthly`.
- The intermediate model combines:
  - `int_customer_month_spine` for the monthly snapshot framework
  - `fct_orders` for actual order activity and financial values
- The grain is one row per `customer_id` per `snapshot_month_end_date`.
- Lifetime metrics are calculated by including all orders with `order_date` on or before the snapshot month-end.
- Trailing window metrics are calculated relative to the snapshot month-end, not the current date:
  - last 30 days
  - last 90 days
  - last 365 days
- The table includes:
  - lifetime orders, gross revenue, net revenue, and margin
  - trailing order counts
  - trailing net revenue and margin
  - activity flags based on whether the customer had at least one order in each window

## `mart_customer_segments_monthly`

**Business questions it answers**

- Which customers are new, repeat, high frequency, or high value at each month-end?
- How does customer segmentation change over time by reporting month?
- Which customer groups should the business focus on for retention and growth?

**How the logic is written**

- The table is built in [`/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/customer/mart_customer_segments_monthly.sql`](/Users/howeijian/dbt_jaffle/jaffle_elt/models/marts/customer/mart_customer_segments_monthly.sql), which publishes the output of `int_customer_segment_rules_monthly`.
- It starts from `int_customer_metrics_monthly`, so every segment is based on the monthly customer snapshot.
- The segmentation flags are calculated as follows:
  - `is_new_first_ever_customer`: the customer’s first-ever order happened within 30 days of the snapshot month-end
  - `is_repeat_customer`: the customer placed more than one order in the trailing 365-day window
  - `is_high_frequency_customer`: the customer falls in the top 20% of `orders_last_90d` within the same snapshot month-end
  - `is_high_value_customer`: the customer falls in the top 20% of `lifetime_net_revenue` within the same snapshot month-end
- The final output is one row per `customer_id` per `snapshot_month_end_date`.

## Recommended Reporting Usage

- Use `fct_orders` for order-level trend analysis.
- Use `dim_customer` and `dim_date` as the shared lookup tables for joins and filters.
- Use `mart_customer_metrics_monthly` for monthly KPI tracking and customer activity reporting.
- Use `mart_customer_segments_monthly` for customer segmentation, retention, and lifecycle reporting.
