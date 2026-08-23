-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 04_business_analysis.sql
-- Author  : Srimayi G
-- Purpose : Comprehensive Business Analysis of sales, monthly
--           trends, daily sales, geographic performance,
--           and cancellations.
-- ==========================================================

-- ==========================================================
-- PHASE 4.1: OVERALL KPIs
-- ==========================================================

-- KPI 1: Total Revenue
-- Calculates gross revenue generated from all normal sales (excluding cancellations/adjustments)
SELECT
    SUM(quantity * price) AS total_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale';

-- KPI 2: Total Units Sold
-- Calculates the total quantity of items sold through normal sales
SELECT
    SUM(quantity) AS total_units_sold
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale';

-- KPI 3: Total Sales Invoices
-- Counts unique invoices corresponding to completed sales
SELECT
    COUNT(DISTINCT invoice) AS total_sales_invoices
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale';

-- KPI 4: Total Identified Customers
-- Counts unique customers with valid IDs who made purchases
SELECT
    COUNT(DISTINCT customer_id) AS total_identified_customers
FROM ecommerce_sales_classified
WHERE customer_id IS NOT NULL 
  AND transaction_type = 'Sale';

-- KPI 5: Average Order Value (AOV)
-- Calculates average revenue per sales invoice
SELECT
    SUM(quantity * price) / COUNT(DISTINCT invoice) AS average_order_value
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale';


-- ==========================================================
-- PHASE 4.2: MONTHLY REVENUE & TRENDS
-- ==========================================================

-- Query 1: Monthly Revenue
-- Summarizes sales revenue by calendar month
SELECT
    DATE_TRUNC('month', invoicedate) AS sales_month,
    SUM(quantity * price) AS monthly_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY sales_month;

-- Query 2: Highest Revenue Month
-- Returns the month with the maximum revenue
SELECT
    DATE_TRUNC('month', invoicedate) AS sales_month,
    SUM(quantity * price) AS monthly_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY monthly_revenue DESC
LIMIT 1;

-- Query 3: Lowest Revenue Month
-- Returns the month with the minimum revenue (note that December 2011 is incomplete)
SELECT
    DATE_TRUNC('month', invoicedate) AS sales_month,
    SUM(quantity * price) AS monthly_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY monthly_revenue ASC
LIMIT 1;

-- Query 4: Month-over-Month (MoM) Revenue Growth
-- Calculates the absolute change and percentage growth MoM using LAG() window function.
-- Audit fix: wrapped the divisor in NULLIF() to eliminate a division-by-zero risk
-- (safe against months with zero revenue).
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate) AS sales_month,
        SUM(quantity * price) AS monthly_revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
    GROUP BY DATE_TRUNC('month', invoicedate)
)
SELECT
    sales_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY sales_month) AS prev_month_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY sales_month) AS absolute_change,
    ROUND(((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY sales_month)) /
           NULLIF(LAG(monthly_revenue) OVER (ORDER BY sales_month), 0) * 100), 2) AS mom_growth_pct
FROM monthly_sales
ORDER BY sales_month;
-- Result highlights:
-- Largest increase : Nov 2011 (+£352,603.05, +30.63% vs Oct)
-- Strong ramp-up   : Sep +39.40%, Oct +8.98%, Nov +30.63% -> Q4 peak season
-- CAUTION          : Dec 2011 shows -57.59% but data ends on 2011-12-09,
--                    so December is a PARTIAL month, not a real collapse.

-- Query 5: Largest Monthly Revenue Increase & Decrease
-- Demonstrates the months with highest growth and decline.
-- NOTE: The raw result flags Dec 2011 (-£866,076.45) as the largest decrease,
-- but that month is incomplete (data stops on 2011-12-09). Among COMPLETE months,
-- the largest decrease is Apr 2011 (-£179,246.77, -25.03%).
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate) AS sales_month,
        SUM(quantity * price) AS monthly_revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
    GROUP BY DATE_TRUNC('month', invoicedate)
),
mom_changes AS (
    SELECT
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY sales_month) AS prev_month_revenue,
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY sales_month)) AS absolute_change
    FROM monthly_sales
)
-- Display Largest Increase
(SELECT 'Largest Increase' AS change_type, sales_month, absolute_change 
 FROM mom_changes 
 WHERE absolute_change IS NOT NULL 
 ORDER BY absolute_change DESC 
 LIMIT 1)
UNION ALL
-- Display Largest Decrease
(SELECT 'Largest Decrease' AS change_type, sales_month, absolute_change 
 FROM mom_changes 
 WHERE absolute_change IS NOT NULL 
 ORDER BY absolute_change ASC 
 LIMIT 1);


-- ==========================================================
-- PHASE 4.3: DAILY SALES ANALYSIS
-- ==========================================================

-- Query 1: Daily Revenue Trends
-- Summarizes sales revenue by day
SELECT
    DATE(invoicedate) AS sales_date,
    SUM(quantity * price) AS daily_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY DATE(invoicedate)
ORDER BY sales_date;

-- Query 2: Highest Revenue Day
-- Result: 2011-12-09 (£200,900.98).
-- CAUTION: this figure is inflated by a single wholesale order of 80,995
-- "PAPER CRAFT , LITTLE BIRDIE" units (£168,469.60, invoice 581483) that was
-- fully cancelled the SAME DAY (C581484). Excluding that order, the day's
-- genuine revenue is ~£32k. See 06_product_analysis.sql for the product view.
SELECT
    DATE(invoicedate) AS sales_date,
    SUM(quantity * price) AS daily_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY DATE(invoicedate)
ORDER BY daily_revenue DESC
LIMIT 1;

-- Query 3: Lowest Revenue Day
-- Excludes zero sales days if any exist, or returns the absolute lowest sales day
SELECT
    DATE(invoicedate) AS sales_date,
    SUM(quantity * price) AS daily_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY DATE(invoicedate)
HAVING SUM(quantity * price) > 0
ORDER BY daily_revenue ASC
LIMIT 1;


-- ==========================================================
-- PHASE 4.4: GEOGRAPHIC SALES ANALYSIS
-- ==========================================================

-- Query 1: Country Sales Breakdown
-- Evaluates geographic revenue, Ranking, Contribution, and Customer Metrics.
-- Note: COUNT(DISTINCT customer_id) ignores NULLs automatically, so
-- customer_count and revenue_per_customer reflect IDENTIFIED customers only;
-- countries served purely anonymously (e.g. Hong Kong) show NULL there.
SELECT
    country,
    SUM(quantity * price) AS total_revenue,
    RANK() OVER (ORDER BY SUM(quantity * price) DESC) AS revenue_rank,
    ROUND((SUM(quantity * price) / (SELECT SUM(quantity * price) FROM ecommerce_sales_classified WHERE transaction_type = 'Sale') * 100), 2) AS revenue_contribution_pct,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoice) AS invoice_count,
    COUNT(DISTINCT customer_id) AS customer_count,
    ROUND((SUM(quantity * price) / NULLIF(COUNT(DISTINCT customer_id), 0)), 2) AS revenue_per_customer
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY country
ORDER BY total_revenue DESC;


-- ==========================================================
-- PHASE 4.5: CANCELLATION & RETURN ANALYSIS
-- ==========================================================

-- Query 1: Overall Cancellation Metrics
-- Summarizes returning transactions, cancellation rate, units, and financial impact.
--
-- AUDIT FIXES (documented):
-- 1. Cancellation rate denominator: the original query divided by invoices of ALL
--    transaction types (24,446), which wrongly included 650 adjustment/free-item
--    invoices and understated the rate (15.69%). A fair "of orders placed, how
--    many were cancelled" rate uses Sale + Cancellation invoices only (23,796).
-- 2. Cancelled units/revenue now shown as positive values via ABS(), consistent
--    with the revenue-percentage line, to avoid mixed-sign reporting.
-- 3. NULLIF() guards added on every division.
SELECT
    -- Cancelled invoices
    COUNT(DISTINCT CASE WHEN transaction_type = 'Cancellation' THEN invoice END) AS cancelled_invoices,
    -- Invoices that were either sold or cancelled (excludes adjustments / free items)
    COUNT(DISTINCT CASE WHEN transaction_type IN ('Sale', 'Cancellation') THEN invoice END) AS sale_and_cancel_invoices,
    -- Cancellation Rate = cancelled invoices / (sales + cancellation invoices)
    ROUND(COUNT(DISTINCT CASE WHEN transaction_type = 'Cancellation' THEN invoice END)::DECIMAL /
          NULLIF(COUNT(DISTINCT CASE WHEN transaction_type IN ('Sale', 'Cancellation') THEN invoice END), 0) * 100, 2) AS cancellation_rate_pct,
    -- Cancelled units (magnitude of returned quantities)
    SUM(ABS(quantity)) FILTER (WHERE transaction_type = 'Cancellation') AS cancelled_units,
    -- Cancelled revenue (financial value of cancellations)
    ROUND(SUM(ABS(quantity * price)) FILTER (WHERE transaction_type = 'Cancellation'), 2) AS cancelled_revenue,
    -- Cancellation revenue percentage relative to sales revenue
    ROUND(SUM(ABS(quantity * price)) FILTER (WHERE transaction_type = 'Cancellation') /
          NULLIF(SUM(CASE WHEN transaction_type = 'Sale' THEN quantity * price END), 0) * 100, 2) AS cancellation_revenue_pct
FROM ecommerce_sales_classified;
-- Result: 3,836 cancelled invoices | 16.12% order-cancellation rate
--         275,560 units returned | £893,979.73 cancelled value (~8.40% of gross sales)

-- Query 2: Cancellation trend by month
-- Added during audit: shows WHEN cancellations happen, not just how many.
WITH monthly_cancellations AS (
    SELECT
        DATE_TRUNC('month', invoicedate) AS cancel_month,
        COUNT(DISTINCT invoice) AS cancelled_invoices,
        SUM(ABS(quantity)) AS cancelled_units,
        SUM(ABS(quantity * price)) AS cancelled_value
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Cancellation'
    GROUP BY DATE_TRUNC('month', invoicedate)
),
monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate) AS sales_month,
        SUM(quantity * price) AS sales_value
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
    GROUP BY DATE_TRUNC('month', invoicedate)
)
SELECT
    mc.cancel_month,
    mc.cancelled_invoices,
    mc.cancelled_units,
    ROUND(mc.cancelled_value, 2) AS cancelled_value,
    ROUND(mc.cancelled_value / ms.sales_value * 100, 2) AS pct_of_sales_value
FROM monthly_cancellations mc
JOIN monthly_sales ms ON mc.cancel_month = ms.sales_month
ORDER BY mc.cancel_month;