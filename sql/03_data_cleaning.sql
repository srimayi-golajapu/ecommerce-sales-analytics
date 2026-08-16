-- ==========================================================
-- Question 1: Handle missing product descriptions
-- ==========================================================

-- Check missing descriptions
SELECT COUNT(*) AS null_description_records
FROM ecommerce_sales
WHERE description IS NULL;

-- Create cleaned table while preserving the original dataset
CREATE TABLE IF NOT EXISTS ecommerce_sales_clean AS
SELECT *
FROM ecommerce_sales
WHERE description IS NOT NULL;

-- Verify cleaned record count
SELECT COUNT(*) AS total_clean_records
FROM ecommerce_sales_clean;

-- Verify that no NULL descriptions remain
SELECT COUNT(*) AS remaining_null_descriptions
FROM ecommerce_sales_clean
WHERE description IS NULL;

-- Result:
-- Original records: 541,909
-- Records with NULL descriptions: 1,454
-- Clean records: 540,455
-- Remaining NULL descriptions: 0


-- ==========================================================
-- Question 2: Check and remove duplicate records
-- ==========================================================

-- Identify duplicate groups

SELECT
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country,
    COUNT(*) AS duplicate_count
FROM ecommerce_sales_clean
GROUP BY
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country
HAVING COUNT(*) > 1;


-- Count duplicate groups

SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country
    FROM ecommerce_sales_clean
    GROUP BY
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country
    HAVING COUNT(*) > 1
) AS duplicates;


-- Count duplicate copies that need to be removed

SELECT SUM(duplicate_count - 1) AS duplicate_rows_to_remove
FROM (
    SELECT
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country,
        COUNT(*) AS duplicate_count
    FROM ecommerce_sales_clean
    GROUP BY
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country
    HAVING COUNT(*) > 1
) AS duplicates;


-- Create final cleaned table without exact duplicates

CREATE TABLE ecommerce_sales_final AS
SELECT DISTINCT *
FROM ecommerce_sales_clean;


-- Verify final record count

SELECT COUNT(*) AS final_records
FROM ecommerce_sales_final;


-- Verify that duplicate groups no longer exist

SELECT COUNT(*) AS remaining_duplicate_groups
FROM (
    SELECT
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country,
        COUNT(*) AS duplicate_count
    FROM ecommerce_sales_final
    GROUP BY
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country
    HAVING COUNT(*) > 1
) AS duplicates;

-- ==========================================================
-- Question 3: Classify transaction types
-- ==========================================================

CREATE TABLE ecommerce_sales_classified AS
SELECT
    *,
    CASE
        WHEN quantity < 0 AND LEFT(invoice, 1) = 'C'
            THEN 'Cancellation'
        WHEN quantity < 0
            THEN 'Internal Adjustment'
        ELSE 'Sale'
    END AS transaction_type;


-- Verify transaction classification

SELECT
    transaction_type,
    COUNT(*) AS record_count
FROM ecommerce_sales_classified
GROUP BY transaction_type
ORDER BY record_count DESC;