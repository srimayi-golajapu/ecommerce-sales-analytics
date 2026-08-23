-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 06_product_analysis.sql
-- Author  : Srimayi G
-- Purpose : Product-level analysis: best sellers, revenue
--           drivers, ranking functions, cancellations, and
--           country-level product performance.
--
-- IMPORTANT - NON-PRODUCT STOCK CODES
-- The following codes are operational charges, NOT merchandise.
-- They are excluded from every product ranking in this file:
--   DOT  = postage-related charge added to orders
--   POST = postage / shipping charge
--   M    = manual entry or adjustment made by staff
-- If they were included, "postage" would rank as one of the
-- top "products", which misstates real merchandise demand.
-- Together they carry ~£362k of sale-classified value that
-- belongs in revenue KPIs but not in product rankings.
-- Other non-product codes exist (AMAZONFEE, BANK CHARGES,
-- CRUK); they are called out where relevant below.
-- ==========================================================


-- ==========================================================
-- QUERY 1: TOP PRODUCTS BY UNITS SOLD
-- Business question: Which items move the most volume?
-- ==========================================================

SELECT
    stockcode,
    MAX(description) AS description,
    SUM(quantity) AS total_units_sold,
    COUNT(DISTINCT invoice) AS order_frequency
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
  AND stockcode NOT IN ('DOT', 'POST', 'M') -- exclude fees/manual entries (see header)
GROUP BY stockcode
ORDER BY total_units_sold DESC
LIMIT 10;
-- Result highlights: PAPER CRAFT LITTLE BIRDIE (80,995), MEDIUM CERAMIC
-- TOP STORAGE JAR (78,033), SMALL POPCORN HOLDER (56,898).
-- CAUTION on 23843 (PAPER CRAFT): all 80,995 units came from ONE invoice
-- that was cancelled the same day - see Query 6 before celebrating it.


-- ==========================================================
-- QUERY 2: TOP PRODUCTS BY REVENUE
-- Business question: Which items actually generate the money?
-- ==========================================================

SELECT
    stockcode,
    MAX(description) AS description,
    ROUND(SUM(quantity * price), 2) AS total_revenue,
    COUNT(DISTINCT invoice) AS order_frequency
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
  AND stockcode NOT IN ('DOT', 'POST', 'M')
GROUP BY stockcode
ORDER BY total_revenue DESC
LIMIT 10;
-- Result: REGENCY CAKESTAND 3 TIER leads (£174,156.54) followed by
-- PAPER CRAFT (£168,469.60 - same cancelled-order caveat applies).


-- ==========================================================
-- QUERY 3: AVERAGE SELLING PRICE PER PRODUCT
-- Business question: What does each item typically sell for?
-- Weighted by units (revenue / units), not a naive AVG(price),
-- because AVG would over-weight small bulk-discounted lines.
-- ==========================================================

SELECT
    stockcode,
    MAX(description) AS description,
    ROUND(SUM(quantity * price) / NULLIF(SUM(quantity), 0), 2) AS avg_selling_price,
    MIN(price) AS min_unit_price,
    MAX(price) AS max_unit_price,
    COUNT(DISTINCT invoice) AS invoices_sold_in
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
  AND stockcode NOT IN ('DOT', 'POST', 'M')
GROUP BY stockcode
HAVING SUM(quantity * price) > 0 -- ignore zero-revenue curiosities
ORDER BY invoices_sold_in DESC
LIMIT 15;
-- The wide min/max spread per product shows wholesale vs retail pricing tiers.


-- ==========================================================
-- QUERY 4: PRODUCT REVENUE CONTRIBUTION (PARETO VIEW)
-- Business question: How concentrated is revenue across the catalog?
-- Uses a window sum for cumulative % - no self-join needed.
-- ==========================================================

WITH product_revenue AS (
    SELECT
        stockcode,
        MAX(description) AS description,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY stockcode
)
SELECT
    stockcode,
    description,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue / SUM(revenue) OVER () * 100, 2) AS pct_of_product_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(revenue) OVER () * 100, 2) AS cumulative_pct
FROM product_revenue
ORDER BY revenue DESC
LIMIT 20;
-- Result: top 20 products deliver ~16% of product revenue; the full Pareto
-- split (A/B/C classes) is quantified in 05_advanced_sql.sql Query 3.


-- ==========================================================
-- QUERY 5: PRODUCTS WITH HIGHEST CANCELLATION ACTIVITY
-- Business question: Which items come back / get cancelled most?
-- Ranked by cancelled VALUE; unit counts shown alongside.
-- ==========================================================

SELECT
    c.stockcode,
    MAX(c.description) AS description,
    COUNT(*) AS cancellation_line_items,
    SUM(ABS(c.quantity)) AS units_cancelled,
    ROUND(SUM(ABS(c.quantity * c.price)), 2) AS value_cancelled,
    RANK() OVER (ORDER BY SUM(ABS(c.quantity * c.price)) DESC) AS cancel_value_rank
FROM ecommerce_sales_classified c
WHERE c.transaction_type = 'Cancellation'
GROUP BY c.stockcode
ORDER BY value_cancelled DESC
LIMIT 10;
-- Result: AMAZON FEE (£235,281.59) tops cancelled value - marketplace fee
-- reversals, not product returns. Next: PAPER CRAFT (£168,469.60) which is a
-- single same-day cancelled wholesale order, then Manual (M) adjustments
-- (£146,784.46). Genuine returned merchandise starts at MEDIUM CERAMIC JAR.


-- ==========================================================
-- QUERIES 6-8: RANKING FUNCTION COMPARISON (RANK vs DENSE_RANK vs ROW_NUMBER)
-- Business question: How do we identify our true top sellers, and what is
-- the difference between the three SQL ranking functions?
-- All three run over the same revenue-ordered set so results are comparable.
-- ==========================================================

WITH ranked_products AS (
    SELECT
        stockcode,
        MAX(description) AS description,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY stockcode
)
-- QUERY 6: RANK() - skips ranks after ties (1, 2, 2, 4...)
SELECT
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    stockcode,
    description,
    ROUND(revenue, 2) AS revenue
FROM ranked_products
ORDER BY revenue_rank
LIMIT 12;

WITH ranked_products AS (
    SELECT
        stockcode,
        MAX(description) AS description,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY stockcode
)
-- QUERY 7: DENSE_RANK() - no gaps after ties (1, 2, 2, 3...)
SELECT
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS dense_revenue_rank,
    stockcode,
    description,
    ROUND(revenue, 2) AS revenue
FROM ranked_products
ORDER BY dense_revenue_rank
LIMIT 12;

WITH ranked_products AS (
    SELECT
        stockcode,
        MAX(description) AS description,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY stockcode
)
-- QUERY 8: ROW_NUMBER() - unique sequential ids regardless of ties (1, 2, 3...)
-- Practical use: deterministic "Top-N" lists and pagination.
SELECT
    ROW_NUMBER() OVER (ORDER BY revenue DESC) AS row_num,
    stockcode,
    description,
    ROUND(revenue, 2) AS revenue
FROM ranked_products
ORDER BY row_num
LIMIT 12;
-- Note: exact ties are rare in this dataset's monetary sums, so the three
-- functions mostly agree here; the semantic differences still matter for
-- tie-heavy data (e.g., rounding prices into buckets).


-- ==========================================================
-- QUERY 9: PRODUCT PERFORMANCE BY COUNTRY
-- Business question: What sells in which market? Shows the top product
-- per country using a multi-level CTE + window rank (nested queries).
-- ==========================================================

WITH country_product_sales AS (
    SELECT
        country,
        stockcode,
        MAX(description) AS description,
        SUM(quantity) AS units_sold,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY country, stockcode
),
country_product_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY revenue DESC) AS product_rank_in_country
    FROM country_product_sales
)
SELECT
    country,
    stockcode,
    description,
    units_sold,
    ROUND(revenue, 2) AS revenue,
    product_rank_in_country
FROM country_product_ranked
WHERE product_rank_in_country <= 3 -- top 3 products per market
ORDER BY country, product_rank_in_country;
-- Insight: REGENCY CAKESTAND 3 TIER or WHITE HANGING HEART T-LIGHT HOLDER
-- lead almost every market - the assortment has broad international appeal.


-- ==========================================================
-- QUERY 10: SAME-DAY SALE+CANCELLATION DETECTION (DATA ANOMALY WATCH)
-- Business question: Which "sales" were reversed on the day they happened?
-- These inflate gross revenue and cancellation stats simultaneously and
-- must be understood before quoting either number.
-- ==========================================================

WITH sales_lines AS (
    SELECT
        stockcode,
        description,
        invoice,
        invoicedate,
        quantity * price AS line_value
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
),
cancel_pairs AS (
    SELECT
        REPLACE(invoice, 'C', '') AS original_invoice,
        ABS(quantity * price) AS reversed_value
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Cancellation'
)
SELECT
    s.invoice,
    s.stockcode,
    s.description,
    ROUND(s.line_value, 2) AS sale_value,
    s.invoicedate::date AS sale_date
FROM sales_lines s
JOIN cancel_pairs cp
     ON cp.original_invoice = s.invoice
    AND cp.reversed_value = s.line_value
ORDER BY s.line_value DESC;
-- Confirms invoice 581483 / C581484 (customer 16446, £168,469.60):
-- an 80,995-unit Paper Craft order placed and fully cancelled on 2011-12-09.


-- ==========================================================
-- QUERY 11: MONTHLY UNITS TREND FOR TOP-5 REVENUE PRODUCTS
-- Business question: Are star products growing or fading month by month?
-- Multi-level CTE: rank products first, then track only those through time.
-- ==========================================================

WITH product_revenue AS (
    SELECT
        stockcode,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY stockcode
),
top_5 AS (
    SELECT stockcode
    FROM product_revenue
    ORDER BY revenue DESC
    LIMIT 5
)
SELECT
    DATE_TRUNC('month', invoicedate) AS sales_month,
    p.stockcode,
    MAX(p.description) AS description,
    SUM(p.quantity) AS units_sold
FROM ecommerce_sales_classified p
JOIN top_5 t ON p.stockcode = t.stockcode
WHERE p.transaction_type = 'Sale'
GROUP BY DATE_TRUNC('month', invoicedate), p.stockcode
ORDER BY sales_month, p.stockcode;


-- ==========================================================
-- QUERY 12: PRICE-BAND PERFORMANCE
-- Business question: Does cheap volume or mid-price value drive revenue?
-- CASE WHEN buckets every sale line into price bands, then compares.
-- Extreme prices simply fall into the ">= £10" band; no rows are removed.
-- ==========================================================

SELECT
    CASE
        WHEN price < 1 THEN 'a: < £1'
        WHEN price < 3 THEN 'b: £1 - £2.99'
        WHEN price < 5 THEN 'c: £3 - £4.99'
        WHEN price < 10 THEN 'd: £5 - £9.99'
        ELSE 'e: >= £10'
    END AS price_band,
    COUNT(*) AS line_items,
    SUM(quantity) AS units_sold,
    ROUND(SUM(quantity * price), 2) AS revenue,
    ROUND(100 * SUM(quantity * price) / SUM(SUM(quantity * price)) OVER (), 2) AS pct_of_product_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
  AND stockcode NOT IN ('DOT', 'POST', 'M')
GROUP BY price_band
ORDER BY price_band;
