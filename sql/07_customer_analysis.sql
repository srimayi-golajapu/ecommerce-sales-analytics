-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 07_customer_analysis.sql
-- Author  : Srimayi G
-- Purpose : Customer-level analysis: value, loyalty, frequency,
--           concentration, and geography.
--
-- NULL CUSTOMER ID POLICY
-- ~24.9% of records (and £1,754,901.91 of sales revenue) have no
-- customer_id - these are anonymous/retail transactions. They are
-- NEVER counted as customers. Every query in this file either
-- (a) filters them out for customer-level metrics, or
-- (b) reports them explicitly as an "Anonymous" bucket so the
--     identified-customer numbers stay honest.
-- ==========================================================


-- ==========================================================
-- QUERY 0: THE ANONYMOUS REVENUE BASELINE
-- Business question: How much revenue cannot be attributed to a
-- known customer? Sets expectations for every later number here.
-- ==========================================================

SELECT
    CASE
        WHEN customer_id IS NULL THEN 'Anonymous (no ID)'
        ELSE 'Identified'
    END AS customer_attribution,
    ROUND(SUM(quantity * price), 2) AS revenue,
    ROUND(100 * SUM(quantity * price) / SUM(SUM(quantity * price)) OVER (), 2) AS pct_of_sales
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
GROUP BY CASE
        WHEN customer_id IS NULL THEN 'Anonymous (no ID)'
        ELSE 'Identified'
    END
ORDER BY revenue DESC;
-- Result: Identified £8,887,208.89 (83.51%) | Anonymous £1,754,901.91 (16.49%)


-- ==========================================================
-- QUERY 1: ALL CUSTOMERS BY TOTAL REVENUE (FULL RANKING)
-- Business question: Who are our customers by value?
-- RANK() gives the full leaderboard; cumulative % shows concentration.
-- ==========================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS total_invoices,
        SUM(quantity) AS total_units,
        SUM(quantity * price) AS revenue,
        MIN(invoicedate) AS first_purchase,
        MAX(invoicedate) AS last_purchase
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL -- anonymous rows excluded by design
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_invoices,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue / NULLIF(total_invoices, 0), 2) AS avg_order_value,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(revenue) OVER (), 2) AS cumulative_pct_of_revenue
FROM customer_revenue
ORDER BY revenue_rank;
-- Result: 4,338 identified customers; leader is 14646 (£280,206.02 over 73 invoices).


-- ==========================================================
-- QUERY 2: TOP 10 CUSTOMERS BY NUMBER OF INVOICES
-- Business question: Who orders most often (not necessarily biggest)?
-- ==========================================================

SELECT
    customer_id,
    COUNT(DISTINCT invoice) AS invoice_count,
    COUNT(DISTINCT DATE(invoicedate)) AS active_days,
    ROUND(SUM(quantity * price), 2) AS total_revenue,
    MIN(invoicedate)::date AS first_order,
    MAX(invoicedate)::date AS last_order
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
  AND customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY invoice_count DESC
LIMIT 10;
-- Result: customer 14911 leads with 201 invoices; 13089 (97) and 14646 (73) follow.


-- ==========================================================
-- QUERY 3: AVERAGE ORDER VALUE PER CUSTOMER + FREQUENCY BANDS
-- Business question: How do ordering habits differ across the base?
-- Purchase frequency = distinct invoices per customer; CASE WHEN buckets it.
-- ==========================================================

WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS invoices,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN invoices = 1 THEN 'One-time buyer'
        WHEN invoices <= 5 THEN 'Light (2-5 invoices)'
        WHEN invoices <= 20 THEN 'Regular (6-20 invoices)'
        WHEN invoices <= 50 THEN 'Frequent (21-50 invoices)'
        ELSE 'Power buyer (>50 invoices)'
    END AS frequency_band,
    COUNT(*) AS customers,
    ROUND(AVG(revenue / invoices), 2) AS avg_order_value,
    ROUND(AVG(revenue), 2) AS avg_customer_revenue,
    ROUND(SUM(revenue), 2) AS band_revenue
FROM customer_stats
GROUP BY frequency_band
ORDER BY avg_customer_revenue DESC;
-- Insight: power buyers order at far higher AOVs - wholesale behaviour.


-- ==========================================================
-- QUERY 4: REPEAT vs ONE-TIME CUSTOMERS
-- Business question: Is revenue driven by loyalty or acquisition?
-- Conditional aggregation keeps it to a single pass over the data.
-- ==========================================================

WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS invoices,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    CASE WHEN invoices > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS pct_of_revenue
FROM customer_stats
GROUP BY CASE WHEN invoices > 1 THEN 'Repeat' ELSE 'One-time' END
ORDER BY revenue DESC;
-- Result: Repeat 2,845 customers -> 93.09% of identified revenue
--         One-time 1,493 customers -> 6.91% of identified revenue


-- ==========================================================
-- QUERY 5: CUSTOMER ACTIVITY BY COUNTRY
-- Business question: Where do identified customers sit, and how much
-- does each market earn per identified customer?
-- ==========================================================

SELECT
    country,
    COUNT(DISTINCT customer_id) AS identified_customers,
    COUNT(DISTINCT invoice) AS invoices,
    ROUND(SUM(quantity * price), 2) AS revenue,
    ROUND(SUM(quantity * price) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS revenue_per_identified_customer
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale'
  AND customer_id IS NOT NULL
GROUP BY country
HAVING COUNT(DISTINCT customer_id) >= 5 -- skip markets with tiny samples
ORDER BY revenue DESC;
-- Contrast with 04_business_analysis.sql geographic view: Netherlands earns
-- ~£31k per identified customer from just 9 customers vs ~£2.3k in the UK -
-- export markets behave like wholesale accounts.


-- ==========================================================
-- QUERY 6: HIGH-VALUE CUSTOMER IDENTIFICATION
-- Business question: Which customers justify account management?
-- Rule: lifetime revenue above the average customer revenue AND
-- more than one purchase (i.e., valuable AND returning).
-- Uses a nested subquery for the population average.
-- ==========================================================

WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS invoices,
        SUM(quantity * price) AS revenue,
        MAX(invoicedate) AS last_purchase
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
segmented AS (
    SELECT
        cs.*,
        AVG(cs.revenue) OVER () AS avg_customer_revenue,
        EXTRACT(DAY FROM TIMESTAMP '2011-12-09 12:50:00' - cs.last_purchase) AS days_since_last_purchase
    FROM customer_stats cs
)
SELECT
    customer_id,
    invoices,
    ROUND(revenue, 2) AS lifetime_revenue,
    ROUND(avg_customer_revenue, 2) AS base_average,
    ROUND(revenue / avg_customer_revenue, 1) AS x_times_base_avg,
    days_since_last_purchase,
    CASE
        WHEN revenue > avg_customer_revenue AND invoices > 1 THEN 'High-Value Repeat'
        WHEN revenue > avg_customer_revenue THEN 'High-Value One-time'
        ELSE 'Standard'
    END AS segment
FROM segmented
ORDER BY lifetime_revenue DESC;
-- 843 customers qualify as High-Value Repeat; the top decile of customers
-- generates 61.45% of identified revenue (see 05_advanced_sql.sql).


-- ==========================================================
-- QUERY 7: NEW vs RETURNING CUSTOMERS PER MONTH (PURCHASE TREND)
-- Business question: Are we acquiring new customers or farming old ones?
-- A customer is "New" in their first-ever purchase month and "Returning"
-- in every later active month. Using FIRST_VALUE against the true
-- first-purchase month avoids miscounting extra invoices made in the
-- same month as repeat purchases.
-- December 2011 is partial (data ends Dec 9) - read its drop accordingly.
-- ==========================================================

WITH customer_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoicedate) AS activity_month
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
),
activity_with_origin AS (
    SELECT
        customer_id,
        activity_month,
        FIRST_VALUE(activity_month) OVER (PARTITION BY customer_id ORDER BY activity_month) AS first_month
    FROM customer_activity
)
SELECT
    activity_month,
    COUNT(DISTINCT customer_id) FILTER (WHERE activity_month = first_month) AS new_customers,
    COUNT(DISTINCT customer_id) FILTER (WHERE activity_month > first_month) AS returning_customers
FROM activity_with_origin
GROUP BY activity_month
ORDER BY activity_month;
