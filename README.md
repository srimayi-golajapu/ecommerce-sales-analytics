# E-commerce Sales Analytics

A complete PostgreSQL analytics project that turns 541,909 raw e-commerce transactions into clean, classified data and answers real commercial questions: how much the business earns, when and where it earns it, which products and customers drive revenue, and where cancellations leak money.

---

## Project Overview

An online gift retailer sells to a mix of retail and wholesale buyers across 38 countries, but its transaction export is messy: missing customer IDs, duplicate rows, cancelled orders, free giveaways, and accounting adjustments all sit mixed in with genuine sales.

This project builds the full analytical pipeline in SQL — from database setup and data cleaning through KPI reporting, product/customer/geographic analysis, and advanced window-function work — so every headline number can be traced back to an executable query against the cleaned dataset.

## Business Objectives

1. Establish trustworthy core KPIs (revenue, units, invoices, customers, AOV) after removing non-sale noise.
2. Understand monthly and daily revenue patterns, including seasonality and incomplete-period handling.
3. Compare market performance by country, including wholesale vs retail behaviour.
4. Quantify cancellation impact and identify what is actually being cancelled.
5. Identify hero products, dead stock, and products dangerously dependent on single orders.
6. Segment customers by value and loyalty; measure concentration risk.
7. Demonstrate production-grade SQL: CTEs, window functions, conditional aggregation, and ranking functions on real problems.

## Dataset

| Property | Value |
|---|---|
| Source | [UCI Online Retail Dataset](https://archive.ics.uci.edu/dataset/352/online+retail) |
| Records | 541,909 raw → **535,187** after cleaning |
| Grain | One row per invoice line item |
| Period | 2010-12-01 → 2011-12-09 (final month partial) |
| Columns | `invoice`, `stockcode`, `description`, `quantity`, `invoicedate`, `price`, `customer_id`, `country` |
| Coverage | 25,900 invoices · 4,070 stock codes · 38 countries |

**Data-quality challenges:** 24.9% of records have no `customer_id`; 5,268 exact duplicates; 1,454 missing descriptions; 10,624 negative-quantity lines (cancellations/adjustments); zero-price giveaways; negative-price bad-debt entries; non-product codes (`DOT` postage, `POST` shipping, `M` manual entry) embedded in the sales data.

## Tech Stack

- **PostgreSQL** (tested on PG 18)
- **SQL** — ANSI with PostgreSQL window functions and CTEs
- **GitHub** — version control & portfolio presentation

## Project Structure

```
ecommerce-sales-analytics/
├── dataset/
│   └── Online_Retail.csv          # Raw source data
├── sql/
│   ├── 01_database_setup.sql      # Table creation & import notes
│   ├── 02_data_exploration.sql    # Record counts + data-quality audit
│   ├── 03_data_cleaning.sql       # Nulls, duplicates, transaction classification
│   ├── 04_business_analysis.sql   # KPIs, monthly/daily trends, geography, cancellations
│   ├── 05_advanced_sql.sql        # Window functions, RFM, ABC, deciles, gaps
│   ├── 06_product_analysis.sql    # Product rankings, contribution, price bands
│   └── 07_customer_analysis.sql   # Value, loyalty, frequency, acquisition trends
└── docs/
    └── Analysis_Report.md         # Full findings with verified numbers
```

Run order matters: `01 → 02 → 03` build the tables; `04–07` analyse them and are re-runnable in any order.

## Data Cleaning

Three staged tables preserve every step:

```
ecommerce_sales            541,909 raw records
  │  remove 1,454 rows with NULL description
ecommerce_sales_clean      540,455
  │  remove 5,268 exact-duplicate copies (4,879 groups)
ecommerce_sales_final      535,187
  │  classify every row into one of five transaction types
ecommerce_sales_classified 535,187  ← analysis base table
```

Classification rules (`CASE` logic): `C`-prefixed invoice + negative quantity → **Cancellation**; other negative quantities → **Internal Adjustment**; negative price → **Accounting Adjustment**; zero price → **Free/Zero-Price Item**; everything else → **Sale**.

Missing customer IDs are **kept** for revenue analysis but always excluded from customer-level metrics — anonymous transactions are never presented as identified customers.

## Key KPIs

| KPI | Value |
|---|---|
| Total Revenue (sales only) | £10,642,110.80 |
| Total Units Sold | 5,572,416 |
| Sales Invoices | 19,960 |
| Identified Customers | 4,338 |
| Average Order Value | £533.17 |
| Cancellation Rate | 16.12% of orders (£893,979.73) |

## Business Analysis

- **Monthly:** November 2011 peaks at £1,503,867 (+30.63% MoM); September–November delivers ~31% of annual revenue. December 2011 is flagged as a partial month rather than reported as a collapse.
- **Daily:** 305 trading days, never Saturdays; strongest weekday Thursday; peak hours 09:00–15:00.
- **Geography:** UK = 84.59% of revenue; Netherlands/EIRE show wholesale patterns (~£3k+ per invoice, single-digit customer counts).
- **Products:** REGENCY CAKESTAND 3 TIER leads revenue; sub-£3 items produce ~56% of product revenue; ABC classes split 80/15/5.
- **Customers:** repeat buyers (65.6% of base) generate 93.09% of identified revenue; top decile holds 61.45%.

## Key Insights

1. **Q4 seasonality dominates** — the Sep→Nov ramp (+39.4%, +9.0%, +30.6% MoM) makes Q4 supply-chain readiness existential.
2. **Extreme market concentration** — one country supplies 84.59% of revenue.
3. **Customer concentration mirrors it** — losing two or three flagship accounts would be material to annual revenue.
4. **Retention outperforms acquisition** — new-customer counts declined through 2011 while the returning base grew to 1,341 actives in November.
5. **Cancellations are mostly process, not product** — fee reversals, manual adjustments, and one anomalous same-day-cancelled 80,995-unit bulk order dominate cancelled value.
6. **Cheap giftware carries the catalog** — items under £3 generate over half of product revenue.
7. **Some "successful" products are fragile** — several high-revenue SKUs draw nearly all their value from a single invoice.

## SQL Concepts Demonstrated

- `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`
- `GROUP BY`, `HAVING`
- Aggregate functions (`SUM`, `COUNT`, `AVG`, `MIN`, `MAX`)
- `CASE WHEN` (classification, bucketing, segmentation)
- Conditional aggregation (`COUNT/SUM ... FILTER`, pivot matrices)
- CTEs, including multi-level chains
- Subqueries (scalar, inline views, nested)
- Window functions: `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `NTILE()`
- `LAG()` / `LEAD()` / `FIRST_VALUE()` for time-intelligence
- Running totals with explicit window frames
- Percentage-of-total and cumulative-contribution patterns
- Date functions (`DATE_TRUNC`, `EXTRACT`, `TO_CHAR`, date arithmetic)
- NULL handling (`FILTER (WHERE ...)`, `NULLIF`, `COALESCE`)

## Business Recommendations

1. Investigate invoice pair 581483/C581484 (£168k placed and cancelled same day) — it distorts multiple metrics and may indicate process or fraud issues.
2. Assign account management to the top customer decile (~61% of identified revenue).
3. Launch a first-repeat incentive for the 1,493 one-time buyers.
4. Target the cancellation rate below 10% by separating genuine returns from fee/manual reversals.
5. Replicate the Dutch/EIRE wholesale playbook in France and Germany.
6. Ring-fence Q4 stock for ABC Class-A SKUs; a November stockout costs more than any other failure mode.
7. Capture customer IDs at checkout to recover visibility on 16.5% of anonymous revenue.

## Project Outcome

From a Data Analyst / Business Analyst perspective this project demonstrates:

- building a reproducible cleaning pipeline entirely in SQL, with documented, reversible decisions;
- refusing misleading numbers — partial months, phantom orders, and anonymous customers are qualified instead of hidden;
- translating query output into prioritised, quantified business actions;
- advanced-SQL fluency applied to segmentation, concentration, cohort timing, and anomaly detection rather than toy examples.

Every figure in [docs/Analysis_Report.md](docs/Analysis_Report.md) is generated by a query in `/sql`.

## Author

**Srimayi G**
