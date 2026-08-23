-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 05_advanced_sql.sql
-- Author  : Srimayi G
-- Purpose : Advanced SQL analysis demonstrating complex queries,
--           multi-level CTEs, window functions, and business
--           logic (Running Totals, RFM, ABC Inventory, MoM).
-- ==========================================================

-- ==========================================================
-- QUERY 1: CUMULATIVE DAILY REVENUE (RUNNING TOTALS)
-- Purpose: Track the day-by-day progression of gross sales revenue
--          across the entire time period.
-- ==========================================================

WITH daily_sales AS (
    SELECT
        DATE(invoicedate) AS sales_date,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
    GROUP BY DATE(invoicedate)
)
SELECT
    sales_date,
    revenue,
    SUM(revenue) OVER (ORDER BY sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM daily_sales
ORDER BY sales_date;


-- ==========================================================
-- QUERY 2: RFM CUSTOMER SEGMENTATION (RECENCY, FREQUENCY, MONETARY)
-- Purpose: Segment customer behavior based on how recently they bought,
--          how frequently they buy, and how much they spend.
--          Uses NTILE(5) to score customers from 1 to 5.
-- ==========================================================

WITH max_date AS (
    SELECT MAX(invoicedate) AS max_dataset_date 
    FROM ecommerce_sales_classified
),
customer_rfm_base AS (
    SELECT
        c.customer_id,
        -- Recency: Days since last purchase to the end of the dataset
        EXTRACT(DAY FROM (SELECT max_dataset_date FROM max_date) - MAX(c.invoicedate)) AS recency_days,
        -- Frequency: Count of distinct sales invoices
        COUNT(DISTINCT c.invoice) AS frequency,
        -- Monetary Value: Sum of sales revenue
        SUM(c.quantity * c.price) AS monetary_value
    FROM ecommerce_sales_classified c
    WHERE c.customer_id IS NOT NULL
      AND c.transaction_type = 'Sale'
    GROUP BY c.customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        -- Score 5 is best. NTILE assigns 1 (lowest) to 5 (highest).
        -- Since lower recency days is better, we order by recency_days DESC so smaller values get a higher score.
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM customer_rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary_value,
    r_score,
    f_score,
    m_score,
    -- Combined RFM segment code (e.g. 555 for top customers)
    (r_score * 100 + f_score * 10 + m_score) AS rfm_code,
    -- Classify into business segments
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions / VIP'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score = 1 THEN 'New Customers'
        WHEN r_score = 1 THEN 'At Risk / Churned'
        ELSE 'General Customers'
    END AS customer_segment
FROM rfm_scores
ORDER BY monetary_value DESC
LIMIT 20;


-- ==========================================================
-- QUERY 3: ABC INVENTORY CLASSIFICATION (PRODUCT REVENUE FOCUS)
-- Purpose: Classify products using the Pareto principle:
--          * Class A: Top 80% of revenue (critical items)
--          * Class B: Next 15% of revenue (medium items)
--          * Class C: Bottom 5% of revenue (slow-moving items)
-- ==========================================================

WITH product_revenue AS (
    SELECT
        stockcode,
        description,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY stockcode, description
),
cumulative_product_revenue AS (
    SELECT
        stockcode,
        description,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM product_revenue
),
abc_raw AS (
    SELECT
        stockcode,
        description,
        revenue,
        running_revenue,
        total_revenue,
        ROUND((running_revenue / total_revenue * 100), 2) AS cumulative_pct,
        CASE
            WHEN (running_revenue / total_revenue) <= 0.80 THEN 'A'
            WHEN (running_revenue / total_revenue) <= 0.95 THEN 'B'
            ELSE 'C'
        END AS abc_class
    FROM cumulative_product_revenue
)
-- Summarize ABC segment contributions
SELECT
    abc_class,
    COUNT(*) AS unique_products,
    SUM(revenue) AS total_revenue_class,
    ROUND((SUM(revenue) / (SELECT SUM(revenue) FROM product_revenue) * 100), 2) AS revenue_share_pct
FROM abc_raw
GROUP BY abc_class
ORDER BY abc_class;


-- ==========================================================
-- QUERY 4: MONTH-OVER-MONTH SALES FORECAST FEATURES & GROWTH
-- Purpose: Compute monthly sales, running sales growth, and lag features
--          using multi-level CTEs, subqueries, and LAG/LEAD functions.
-- ==========================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate) AS sales_month,
        SUM(quantity * price) AS current_revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
    GROUP BY DATE_TRUNC('month', invoicedate)
),
lagged_sales AS (
    SELECT
        sales_month,
        current_revenue,
        -- Lag features (previous month, 2 months ago)
        LAG(current_revenue, 1) OVER (ORDER BY sales_month) AS revenue_lag_1,
        LAG(current_revenue, 2) OVER (ORDER BY sales_month) AS revenue_lag_2,
        -- Lead feature (next month)
        LEAD(current_revenue, 1) OVER (ORDER BY sales_month) AS revenue_lead_1
    FROM monthly_sales
)
SELECT
    sales_month,
    current_revenue,
    revenue_lag_1,
    revenue_lag_2,
    revenue_lead_1,
    ROUND((current_revenue - revenue_lag_1), 2) AS absolute_change,
    ROUND(((current_revenue - revenue_lag_1) / NULLIF(revenue_lag_1, 0) * 100), 2) AS growth_rate_pct
FROM lagged_sales
ORDER BY sales_month;
-- Audit note: NULLIF() added to guard against division by zero.


-- ==========================================================
-- QUERY 5: REVENUE CONCENTRATION BY CUSTOMER DECILE
-- Business question: How dependent is the business on its best customers?
-- Splits identified customers into ten equal groups (NTILE) and measures
-- each group's revenue share via conditional aggregation.
-- ==========================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(quantity * price) AS revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL -- anonymous transactions excluded by design
    GROUP BY customer_id
),
deciled AS (
    SELECT
        revenue,
        NTILE(10) OVER (ORDER BY revenue DESC) AS revenue_decile -- 1 = top 10%
    FROM customer_revenue
)
SELECT
    revenue_decile AS decile,
    COUNT(*) AS customers_in_decile,
    ROUND(SUM(revenue), 2) AS decile_revenue,
    ROUND(SUM(revenue) / SUM(SUM(revenue)) OVER () * 100, 2) AS pct_of_identified_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_customer
FROM deciled
GROUP BY revenue_decile
ORDER BY revenue_decile;
-- Result: the top decile generates ~61% of identified revenue - a classic
-- wholesale concentration profile that deserves account-management cover.


-- ==========================================================
-- QUERY 6: SINGLE-INVOICE DEPENDENCY RISK PER PRODUCT
-- Business question: Which products look successful but really depend on
-- ONE order (fragile demand)? A product where a single invoice supplies
-- most of its revenue can vanish without warning.
-- Multi-level CTE + nested aggregation + HAVING.
-- ==========================================================

WITH product_invoice_revenue AS (
    SELECT
        stockcode,
        MAX(description) AS description,
        invoice,
        SUM(quantity * price) AS invoice_revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND stockcode NOT IN ('DOT', 'POST', 'M')
    GROUP BY stockcode, invoice
),
product_totals AS (
    SELECT
        stockcode,
        MAX(description) AS description,
        SUM(invoice_revenue) AS product_revenue,
        MAX(invoice_revenue) AS largest_single_invoice_revenue,
        COUNT(*) AS contributing_invoices
    FROM product_invoice_revenue
    GROUP BY stockcode
)
SELECT
    stockcode,
    description,
    ROUND(product_revenue, 2) AS product_revenue,
    contributing_invoices,
    ROUND(largest_single_invoice_revenue, 2) AS largest_invoice_value,
    ROUND(largest_single_invoice_revenue / NULLIF(product_revenue, 0) * 100, 2) AS pct_from_single_invoice
FROM product_totals
WHERE contributing_invoices <= 3 -- only sold on <= 3 distinct invoices
  AND product_revenue > 5000     -- but still material money at stake
ORDER BY pct_from_single_invoice DESC;
-- Flags items whose entire revenue history hangs on one or two orders -
-- candidates for diversification outreach rather than stock expansion.


-- ==========================================================
-- QUERY 7: INTERPURCHASE GAP ANALYSIS (LEAD ON ACTIVITY DATES)
-- Business question: How many days pass between a repeat customer's
-- purchases? Short gaps = healthy engagement; long gaps = churn risk.
-- LEAD() walks each customer's distinct active dates.
-- ==========================================================

WITH purchase_dates AS (
    SELECT DISTINCT
        customer_id,
        DATE(invoicedate) AS purchase_date
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
),
gaps AS (
    SELECT
        customer_id,
        purchase_date,
        LEAD(purchase_date) OVER (PARTITION BY customer_id ORDER BY purchase_date) AS next_purchase_date,
        LEAD(purchase_date) OVER (PARTITION BY customer_id ORDER BY purchase_date) - purchase_date AS days_to_next_purchase
    FROM purchase_dates
)
SELECT
    customer_id,
    COUNT(*) FILTER (WHERE days_to_next_purchase IS NOT NULL) AS measured_gaps,
    ROUND(AVG(days_to_next_purchase), 1) AS avg_days_between_purchases,
    MAX(days_to_next_purchase) AS longest_gap_days
FROM gaps
GROUP BY customer_id
HAVING COUNT(*) >= 5 -- customers with at least 4 measured gaps = enough signal
ORDER BY avg_days_between_purchases
LIMIT 20;


-- ==========================================================
-- QUERY 8: WHEN DOES THE BUSINESS TRADE? (WEEKDAY x HOUR MATRIX)
-- Business question: Which weekday/hour combinations carry the revenue?
-- Conditional aggregation builds a pivot; EXTRACT() pulls date parts.
-- Useful for staffing and campaign timing.
-- Note: no Saturday column appears - the store never trades Saturdays
-- in this dataset (verified: zero invoices on DOW=6).
-- ==========================================================

WITH hourly_sales AS (
    SELECT
        EXTRACT(DOW FROM invoicedate) AS day_of_week,   -- 0 = Sunday .. 6 = Saturday
        EXTRACT(HOUR FROM invoicedate) AS hour_of_day,
        quantity * price AS line_revenue
    FROM ecommerce_sales_classified
    WHERE transaction_type = 'Sale'
)
SELECT
    day_of_week,
    -- Map DOW number to a label: 2011-12-04 is a Sunday (DOW 0 anchor date)
    INITCAP(TO_CHAR(DATE '2011-12-04' + (day_of_week)::int, 'FMDay')) AS weekday_label,
    SUM(line_revenue) FILTER (WHERE hour_of_day BETWEEN 6 AND 7) AS h_06_07,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 8)             AS h_08,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 9)             AS h_09,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 10)            AS h_10,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 11)            AS h_11,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 12)            AS h_12,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 13)            AS h_13,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 14)            AS h_14,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 15)            AS h_15,
    SUM(line_revenue) FILTER (WHERE hour_of_day = 16)            AS h_16,
    SUM(line_revenue) FILTER (WHERE hour_of_day >= 17)           AS h_17_plus
FROM hourly_sales
GROUP BY day_of_week
ORDER BY day_of_week;
