-- ==========================================================
-- Step 1: Total Revenue
-- ==========================================================

SELECT
    SUM(quantity * price) AS total_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale';