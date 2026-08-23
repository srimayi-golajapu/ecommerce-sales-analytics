-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 02_data_exploration.sql
-- Author  : Srimayi G
-- Purpose : Initial exploration of the dataset to audit quality.
-- ==========================================================

-- Question 1: Total number of records in the dataset
SELECT COUNT(*) AS total_records
FROM ecommerce_sales;

-- Question 2: Total number of unique customers
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM ecommerce_sales;

-- Question 3: Total number of unique transactions
SELECT COUNT(DISTINCT invoice) AS total_transactions
FROM ecommerce_sales;

-- Question 4: Total number of unique products
SELECT COUNT(DISTINCT stockcode) AS total_products
FROM ecommerce_sales;

-- Question 5: Date range of the dataset
SELECT MIN(invoicedate) AS start_date, MAX(invoicedate) AS end_date
FROM ecommerce_sales;

-- Question 6: Which countries are included in the dataset?
SELECT DISTINCT country
FROM ecommerce_sales
ORDER BY country;

-- Question 7: Check for NULL values across all columns
SELECT
    COUNT(*) - COUNT(invoice) AS null_invoice,
    COUNT(*) - COUNT(stockcode) AS null_stockcode,
    COUNT(*) - COUNT(description) AS null_description,
    COUNT(*) - COUNT(quantity) AS null_quantity,
    COUNT(*) - COUNT(invoicedate) AS null_invoicedate,
    COUNT(*) - COUNT(price) AS null_price,
    COUNT(*) - COUNT(customer_id) AS null_customer_id,
    COUNT(*) - COUNT(country) AS null_country
FROM ecommerce_sales;

-- Question 8: Check for negative/zero quantities and prices
SELECT
    COUNT(CASE WHEN quantity < 0 THEN 1 END) AS negative_quantities,
    COUNT(CASE WHEN quantity = 0 THEN 1 END) AS zero_quantities,
    COUNT(CASE WHEN price < 0 THEN 1 END) AS negative_prices,
    COUNT(CASE WHEN price = 0 THEN 1 END) AS zero_prices
FROM ecommerce_sales;

-- Question 9: Check for non-standard stock codes (contain letters, service fees, etc.)
SELECT stockcode, COUNT(*) AS record_count
FROM ecommerce_sales
WHERE stockcode ~ '[a-zA-Z]' -- Matches stock codes that contain letters
GROUP BY stockcode
ORDER BY record_count DESC;

-- ==========================================================
-- SECTION 2: ADDITIONAL QUALITY CHECKS (added during audit)
-- These surface every issue that the cleaning script later
-- fixes, so the exploration file tells the full story.
-- ==========================================================

-- Question 10: Exact duplicate rows (identical across all columns)
-- Result: 4,879 groups holding 5,268 removable copies.
SELECT
    COUNT(*) AS duplicate_groups,
    COALESCE(SUM(row_count - 1), 0) AS duplicate_copies_to_remove
FROM (
    SELECT COUNT(*) AS row_count
    FROM ecommerce_sales
    GROUP BY invoice, stockcode, description, quantity,
             invoicedate, price, customer_id, country
    HAVING COUNT(*) > 1
) AS dup;

-- Question 11: Cancellation invoices (invoice number prefixed with 'C')
-- Result: 9,288 raw records across 3,927 distinct C-invoices.
SELECT
    COUNT(*)              AS cancellation_records,
    COUNT(DISTINCT invoice) AS cancelled_invoices
FROM ecommerce_sales
WHERE LEFT(invoice, 1) = 'C';

-- Question 12: Known non-product operational codes.
-- DOT = postage charge per order | POST = postage/shipping | M = manual entry.
-- These must be excluded from PRODUCT rankings because they are fees,
-- not merchandise (see 06_product_analysis.sql).
SELECT stockcode, MAX(description) AS description,
       COUNT(*) AS line_items, ROUND(SUM(quantity * price), 2) AS total_value
FROM ecommerce_sales
WHERE stockcode IN ('DOT', 'POST', 'M')
GROUP BY stockcode
ORDER BY total_value DESC;
-- Result: DOT £206k+ | POST £78k+ | M £77k+ of sale-classified non-product value

-- Question 13: Records per year-month (coverage check for trend analysis)
-- Result: Dec-2010 through Dec-2011; Dec-2011 stops on the 9th (partial month).
SELECT
    TO_CHAR(invoicedate, 'YYYY-MM') AS year_month,
    COUNT(*)                        AS records,
    COUNT(DISTINCT invoice)         AS invoices
FROM ecommerce_sales
GROUP BY TO_CHAR(invoicedate, 'YYYY-MM')
ORDER BY year_month;