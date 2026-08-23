# E-commerce Sales Analytics — Analysis Report

**Author:** Srimayi G
**Database:** PostgreSQL (`ecommerce_db`) · **Dataset:** UCI Online Retail
**Period covered:** 2010-12-01 → 2011-12-09

---

## 1. Project Overview

This project analyses a full year of online retail transactions using PostgreSQL. Raw transaction data was audited, cleaned, and classified into business-meaningful transaction types, then analysed across revenue KPIs, time trends, geography, products, and customers. Every number in this report is reproducible from the SQL files in `/sql`.

## 2. Business Problem

The retailer (a UK-based online gift wholesaler) holds a year of transaction data but has no consolidated view of:

- how much revenue the business actually generates after cancellations and adjustments,
- when and where revenue concentrates,
- which products and customers drive the business,
- how much money is lost to cancelled orders.

This project answers those questions with SQL only.

## 3. Dataset Overview

| Property | Value |
|---|---|
| Source | [UCI Machine Learning Repository – Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail) |
| Grain | One row = one invoice line item |
| Raw records | **541,909** |
| Columns | `invoice`, `stockcode`, `description`, `quantity`, `invoicedate`, `price`, `customer_id`, `country` |
| Date range | 2010-12-01 08:26 → **2011-12-09 12:50** (December 2011 is partial) |
| Distinct invoices | 25,900 |
| Distinct stock codes | 4,070 |
| Countries | 38 |
| Trading days | 305 (no Saturdays) |

### Data-quality issues found (exploration phase)

| Issue | Extent | Treatment |
|---|---|---|
| Missing `description` | 1,454 rows (0.27%) | Removed |
| Missing `customer_id` | 135,080 rows (24.9%) | Kept for sales analysis; excluded from customer analysis |
| Exact duplicate rows | 5,268 copies in 4,879 groups | Removed via `DISTINCT` |
| Negative quantities | 10,624 rows | Classified (cancellations / adjustments), not deleted |
| Zero price | 2,519 rows (raw) | Classified as free items or adjustments |
| Negative price | 2 rows ("Adjust bad debt") | Classified as accounting adjustments |

## 4. Data Cleaning

Pipeline (03_data_cleaning.sql): `ecommerce_sales` → `ecommerce_sales_clean` → `ecommerce_sales_final` → `ecommerce_sales_classified`

```
541,909  raw records
 −1,454  missing descriptions            → 540,455
 −5,268  duplicate copies               → 535,187  final records
```

Each surviving record was classified into one of five transaction types:

| transaction_type | Records | Meaning |
|---|---|---|
| Sale | 524,874 | Genuine revenue-generating lines |
| Cancellation | 9,251 | Negative quantity on a `C`-prefixed invoice |
| Free/Zero-Price Item | 586 | Positive quantity at zero price |
| Internal Adjustment | 474 | Non-C negative quantities (all are zero-price stock write-offs) |
| Accounting Adjustment | 2 | Bad-debt corrections (negative prices) |

Final checks: 0 duplicate groups, 0 unexpected NULLs (only `customer_id` remains nullable by design).

## 5. Key KPIs

All KPIs computed on `transaction_type = 'Sale'` only.

| KPI | Value |
|---|---|
| Total Revenue | **£10,642,110.80** |
| Total Units Sold | **5,572,416** |
| Total Sales Invoices | **19,960** |
| Identified Customers | **4,338** |
| Average Order Value | **£533.17** |

## 6. Monthly Sales Analysis

| Month | Revenue (£) | MoM % |
|---|---|---|
| 2010-12 | 821,452.73 | – |
| 2011-01 | 689,811.61 | −16.03% |
| 2011-02 | 522,545.56 | −24.25% |
| 2011-03 | 716,215.26 | +37.06% |
| 2011-04 | 536,968.49 | −25.03% |
| 2011-05 | 769,296.61 | +43.27% |
| 2011-06 | 760,547.01 | −1.14% |
| 2011-07 | 718,076.12 | −5.58% |
| 2011-08 | 757,841.38 | +5.54% |
| 2011-09 | 1,056,435.19 | +39.40% |
| 2011-10 | 1,151,263.73 | +8.98% |
| 2011-11 | **1,503,866.78** | +30.63% |
| 2011-12 *(partial)* | 637,790.33 | −57.59%* |

\* December 2011 contains only 9 days of data — the −57.59% is an artefact of the extract end date, not a real collapse.

- **Highest revenue month:** November 2011 (£1,503,866.78, 14.13% of annual revenue)
- **Lowest complete month:** February 2011 (£522,545.56)
- **Largest MoM increase (value):** November 2011, +£352,603.05
- **Strongest MoM growth (%):** May 2011, +43.27%
- **Steepest complete-month decline:** April 2011, −25.03% (−£179,246.77)
- Clear seasonal ramp: September–November delivers 30.9% of annual revenue.

## 7. Daily Sales Analysis

- 305 active trading days; the store never trades on Saturdays.
- **Best day:** 2011-12-09 (£200,900.98) — *inflated by a single 80,995-unit wholesale order placed and cancelled the same day; genuine revenue that day was roughly £32k.*
- **Worst day:** 2011-02-06 (£3,439.67).
- **Best weekday:** Thursday (£2,199,292.52 over the year); Sunday weakest (£806,790.78).
- Trading window runs ~06:00–20:00 with the core volume between 09:00 and 15:00.

## 8. Geographic Analysis

| Rank | Country | Revenue (£) | Share | Invoices | Identified Customers | Rev/Customer (£) |
|---|---|---|---|---|---|---|
| 1 | United Kingdom | 9,001,744.09 | 84.59% | 18,019 | 3,920 | 2,296 |
| 2 | Netherlands | 285,446.34 | 2.68% | 94 | 9 | 31,716 |
| 3 | EIRE | 283,140.52 | 2.66% | 288 | 3 | 94,380 |
| 4 | Germany | 228,678.40 | 2.15% | 457 | 94 | 2,433 |
| 5 | France | 209,625.37 | 1.97% | 392 | 87 | 2,410 |
| 6 | Australia | 138,453.81 | 1.30% | 57 | 9 | 15,384 |

The home market dominates revenue, but export markets show a different shape: few customers, huge baskets (Netherlands averages ~£3,000 per invoice) — classic wholesale accounts.

## 9. Cancellation Analysis

| Metric | Value |
|---|---|
| Cancelled invoices | 3,836 |
| Order cancellation rate | **16.12%** of sale+cancellation invoices |
| Cancelled units | 275,560 |
| Cancelled value | **£893,979.73** |
| % of gross sales value | **8.40%** |

Highest-value cancellations are not ordinary returns:

1. AMAZON FEE reversals — £235,281.59 (marketplace fee accounting)
2. One same-day cancelled wholesale order of PAPER CRAFT LITTLE BIRDIE — £168,469.60 (invoice 581483 / C581484)
3. Manual (M) adjustments — £146,784.46
4. MEDIUM CERAMIC TOP STORAGE JAR — £77,479.64 across 74,494 units (genuine large-scale returns)

Monthly cancellation value stays broadly proportional to sales volume (~8–9%), indicating systemic process-driven cancellations rather than episodic quality failures.

## 10. Product Analysis

Non-product codes (**DOT** postage charge, **POST** shipping, **M** manual entry — together ~£362k of sale-classified value) are excluded from all rankings below.

**Top products by revenue**

| StockCode | Description | Revenue (£) |
|---|---|---|
| 22423 | REGENCY CAKESTAND 3 TIER | 174,156.54 |
| 23843 | PAPER CRAFT , LITTLE BIRDIE | 168,469.60 * |
| 85123A | WHITE HANGING HEART T-LIGHT HOLDER | 104,462.75 |
| 47566 | PARTY BUNTING | 99,445.23 |
| 85099B | JUMBO BAG RED RETROSPOT | 94,159.81 |

\* Entirely attributable to one same-day-cancelled order — treat as £0 net.

**Other findings**
- Top units: PAPER CRAFT (80,995 — cancelled), MEDIUM CERAMIC JAR (78,033), POPCORN HOLDER (56,898), WW2 GLIDERS (54,951), RED RETROSPOT BAG (48,371).
- Revenue concentration is healthy: top 20 products ≈ 16% of product revenue; ABC classes split 859 A-products (79.99%), 1,021 B (15.01%), 2,277 C (5.00%).
- Price bands: items priced £1–£2.99 generate 45.8% of product revenue; sub-£3 items together generate ~56.5%.
- REGENCY CAKESTAND / HEART T-LIGHT HOLDER lead almost every country's ranking — assortment travels well internationally.

## 11. Customer Analysis

Anonymous transactions (£1,754,901.91, 16.49% of sales) are never treated as customers.

| Metric | Value |
|---|---|
| Identified customers | 4,338 |
| Revenue from identified customers | £8,887,208.89 (83.51%) |
| Avg revenue per identified customer | £2,048.69 |
| Avg invoices per customer | 4.27 |
| Repeat customers (>1 invoice) | 2,845 (65.6%) → **93.09%** of identified revenue |
| One-time customers | 1,493 (34.4%) → 6.91% of identified revenue |

- **Top customer:** 14646 — £280,206.02 across 73 invoices. Next: 18102 (£259,657), 17450 (£194,391), 14911 (£143,711 across 201 invoices).
- **Concentration:** top decile of customers = **61.45%** of identified revenue; top 15 customers alone = 20.86%.
- Customer 16446 shows £168k "revenue" from 2 invoices — entirely the same-day cancelled Paper Craft order (net £0).
- Acquisition slowed through 2011 (885 new customers in Dec-2010 baseline → 188 by Jul-2011) while the returning base grew steadily (up to 1,341 returning actives in November).

## 12. Advanced SQL Analysis

Demonstrated against real business questions (05_advanced_sql.sql):

| Query | Business question | Techniques |
|---|---|---|
| Cumulative daily revenue | How does cash build across the year? | CTE, running-total window frame |
| RFM segmentation (NTILE(5)) | Who are our best/worst customers? | Multi-level CTEs, NTILE, scalar subquery, CASE segmentation |
| ABC inventory classification | Which SKUs really matter? | Cumulative % windows, nested aggregation |
| MoM forecast features | What do monthly trends look like for planning? | LAG(…,1)/LAG(…,2)/LEAD, multi-level CTEs |
| Customer deciles | How dependent are we on big buyers? | NTILE(10), conditional aggregation |
| Single-invoice dependency | Which "successful" products hang on one order? | Multi-level CTEs, HAVING, ratio logic |
| Interpurchase gaps | How often do loyal customers return? | LEAD on distinct dates, FILTER |
| Weekday × hour matrix | When should we staff and promote? | EXTRACT date parts, pivot via FILTER |

Key results: Class A products (859 SKUs) carry ~80% of revenue; the top decile of customers carries ~61% of identified revenue; several high-revenue SKUs draw ≥90% of their value from a single invoice.

## 13. Key Business Insights

1. **Revenue is real but overstated at the line level.** £10.64M gross sales shrink meaningfully once the same-day cancelled £168k order and 8.40%-of-sales cancellations are considered.
2. **One market carries the business.** The UK supplies 84.59% of revenue — a concentration risk if domestic demand softens.
3. **Q4 is the profit engine.** September–November produce 30.9% of annual revenue, peaking in November (£1.50M, +30.63% MoM).
4. **A handful of customers hold the book.** Top decile = 61.45% of identified revenue; losing two or three flagship accounts would be material.
5. **Repeat behaviour is the business model.** Two-thirds of customers are repeaters generating 93.09% of identified revenue — retention beats acquisition here (new-customer acquisition declined through 2011).
6. **Cancellations are largely process-driven**, dominated by fee reversals, manual adjustments, and one anomalous bulk order rather than product-quality returns.
7. **The catalog is broad but top-heavy:** ~21% of products (Class A) generate ~80% of revenue.
8. **Cheap giftware wins:** sub-£3 items deliver ~56% of product revenue — pricing and bundling should defend this band.

## 14. Business Recommendations

1. **Investigate the 581483/C581484 bulk order** (80,995 units, same-day cancel) with the sales team — it distorts daily, monthly, product, and customer metrics, and may indicate a data-entry or fraud issue.
2. **Assign account management to the top decile** (~434 customers, 61% of identified revenue) with proactive reorder prompts aligned to their interpurchase cycles.
3. **Re-engage one-time buyers** (1,493 customers, 34% of the base, 6.9% of revenue) with a first-repeat incentive; even a 10% conversion adds meaningful revenue.
4. **Attack the 16.12% order-cancellation rate**: separate genuine returns (e.g., ceramic jar write-offs) from fee/manual adjustments, and set a target below 10%.
5. **Grow wholesale exports deliberately**: Netherlands/EIRE-style accounts have 10–40× the revenue-per-customer of the UK average; replicate them in France/Germany where basket sizes are still retail-like.
6. **Protect Q4 supply chains** for the ~20 hero SKUs identified in the ABC Class A list; stockouts in September–November are the costliest possible failure.
7. **Capture anonymous customer IDs at checkout** — 16.5% of revenue (£1.75M) cannot be tied to any customer today.
8. **Time promotions to the trading clock**: volume concentrates 09:00–15:00 Monday–Friday; avoid spending on Sunday/Saturday campaigns.

## 15. Conclusion

The project converts 541,909 raw lines into a clean, classified 535,187-record analytical base and answers concrete commercial questions: what the business earns (£10.64M), when (Q4 peak), where (84.6% UK), with what products (giftware under £3, led by CAKESTAND/T-LIGHT HOLDER), and with whom (a concentrated, highly loyal wholesale-leaning customer base). All figures trace directly to executable PostgreSQL queries, and every cleaning decision is documented and reversible.
