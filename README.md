# jaffle_elt

`jaffle_elt` is a dbt project for Snowflake that turns seeded ecommerce source data into a small reporting layer focused on orders, customer history, and monthly customer segmentation.

## Motivation

This project solves a common reporting problem: raw transactional tables are hard to use directly for monthly customer reporting. Analysts and downstream tools usually need:

- a clean order fact table
- shared date and customer dimensions
- a stable monthly customer snapshot
- reusable customer segment flags such as new, repeat, high frequency, and high value

The SQL in this repo keeps that logic explicit and layered so developers can trace each metric from source seed to final mart.

## Business Logic And Value

Business logic: deriving customer metrics over time

- `int_order_margin` converts order items, product prices, and supply costs into margin-ready order detail, giving analysts a more realistic view of customer value than revenue alone.
- `int_customer_metrics_monthly` rolls customer activity forward into monthly snapshot metrics, making it easy to track recency, order frequency, and revenue trends over time.
- `int_customer_segment_rules_monthly` applies consistent rules on top of those metrics to classify customers into actionable segments such as new, repeat, high frequency, and high value.

Final output: customer segmentation for decision-making

This logic turns raw transactions into a decision-ready customer layer. Teams can use the final marts to identify who should be retained, reactivated, rewarded, or monitored, without having to rebuild the same metric definitions in every dashboard or analysis.

## Installation

These steps assume you already have access to Snowflake and a working `~/.dbt/profiles.yml` entry named `jaffle_elt`.

1. Clone the repository and move into the project folder.

```bash
cd ~/dbt_jaffle/jaffle_elt
```

2. Create and activate a virtual environment.

```bash
python3 -m venv .venv
source .venv/bin/activate
```

3. Install dbt for Snowflake.

```bash
pip install dbt-core dbt-snowflake
```

4. Confirm dbt can read your profile and connect to Snowflake.

```bash
dbt debug
```

Notes:
- The project currently runs with `dbt-core 1.9.1` and the Snowflake adapter installed in this environment.
- There is no `packages.yml`, so `dbt deps` is not required.
- Seed files are stored locally in [`~/dbt_jaffle/jaffle_elt/seeds`](~/dbt_jaffle/jaffle_elt/seeds) and loaded into Snowflake by dbt.

## Usage

The normal workflow is:

1. Validate the project compiles.

```bash
dbt parse
```

2. Load the CSV seeds into Snowflake.

```bash
dbt seed
```

3. Build models and run tests.

```bash
dbt build
```

Useful targeted commands:

```bash
dbt build --select marts
dbt run --select fct_orders dim_customer dim_date
dbt test --select mart_customer_metrics_monthly mart_customer_segments_monthly
```

What gets built:
- `staging` schema: cleaned source-aligned views
- `intermediate` schema: reusable business logic views
- `marts` schema: final fact, dimension, and reporting tables

Schema behavior is controlled in [`~/dbt_jaffle/jaffle_elt/dbt_project.yml`](~/dbt_jaffle/jaffle_elt/dbt_project.yml), and schema naming is normalized by [`~/dbt_jaffle/jaffle_elt/macros/generate_schema_name.sql`](~/dbt_jaffle/jaffle_elt/macros/generate_schema_name.sql).

## Examples

Build the full project:

```bash
cd ~/dbt_jaffle/jaffle_elt
dbt build
```

Expected high-level outcome:
- seed tables created from `raw_orders.csv`, `raw_items.csv`, `raw_products.csv`, and `raw_supplies.csv`
- final marts tables created:
  - `fct_orders`
  - `dim_customer`
  - `dim_date`
  - `mart_customer_metrics_monthly`
  - `mart_customer_segments_monthly`

Example developer questions this project answers:
- What are the order-level gross revenue, net revenue, and margin values?
- What is each customer's first and most recent order date?
- What was a customer's lifetime value and recent activity at a given month-end?
- Which customers are new, repeat, high frequency, or high value in a given month?

Helpful supporting docs:
- [`~/dbt_jaffle/jaffle_elt/analyses/marts_erd.md`](~/dbt_jaffle/jaffle_elt/analyses/marts_erd.md)
- [`~/dbt_jaffle/jaffle_elt/analyses/marts_business_questions.md`](~/dbt_jaffle/jaffle_elt/analyses/marts_business_questions.md)
- [`~/dbt_jaffle/jaffle_elt/analyses/custom_calculations.md`](~/dbt_jaffle/jaffle_elt/analyses/custom_calculations.md)

## Repository Structure

```text
jaffle_elt/
├── analyses/
├── macros/
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
│       ├── facts/
│       ├── dimensions/
│       └── customer/
├── seeds/
├── tests/
└── dbt_project.yml
```

Key folders:

- [`~/dbt_jaffle/jaffle_elt/models/staging`](~/dbt_jaffle/jaffle_elt/models/staging): renames and recasts raw seeded data into stable source models.
- [`~/dbt_jaffle/jaffle_elt/models/intermediate`](~/dbt_jaffle/jaffle_elt/models/intermediate): contains reusable business logic such as margin calculations, monthly customer spine generation, and customer metric aggregation.
- [`~/dbt_jaffle/jaffle_elt/models/marts`](~/dbt_jaffle/jaffle_elt/models/marts): publishes final reporting tables.
- [`~/dbt_jaffle/jaffle_elt/seeds`](~/dbt_jaffle/jaffle_elt/seeds): local CSV inputs loaded into Snowflake by `dbt seed`.
- [`~/dbt_jaffle/jaffle_elt/macros/surrogate_key.sql`](~/dbt_jaffle/jaffle_elt/macros/surrogate_key.sql): helper macro for building deterministic row keys from multiple columns.

## High-Level SQL Logic

At a high level, the codebase follows this flow:

1. `stg_orders`, `stg_order_items`, `stg_products`, and `stg_supplies` standardize the seeded source files.
2. `int_valid_orders` defines the canonical order set used everywhere downstream.
3. `int_order_margin` combines items, products, and supply costs to estimate item-level and order-level margin inputs.
4. `fct_orders` joins canonical orders with aggregated margin.
5. `dim_customer` and `dim_date` are derived from `fct_orders` to support reporting joins and filters.
6. `int_customer_monthly_snapshot_spine` creates one row per customer per month-end from the customer's first order month onward.
7. `int_customer_metrics_monthly` joins the month spine to `fct_orders` and calculates lifetime and trailing-window metrics.
8. `int_customer_segment_rules_monthly` adds percentile-based segmentation flags.
9. `mart_customer_metrics_monthly` and `mart_customer_segments_monthly` publish the final reporting outputs.

This layering keeps the marts readable: most business logic is written once in the intermediate layer and then exposed through small final select statements in the marts layer.
