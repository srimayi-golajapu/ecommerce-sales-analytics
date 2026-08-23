-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 03_data_cleaning.sql
-- Author  : Srimayi G
-- Purpose : Clean the dataset by handling nulls, duplicates,
--           and classifying transaction types.
-- ==========================================================

-- ==========================================================
-- Question 1: Handle missing product descriptions
-- ==========================================================

-- Check missing descriptions
SELECT COUNT(*) AS null_description_records
FROM ecommerce_sales
WHERE description IS NULL;

-- Drop table if exists to ensure re-runnability
DROP TABLE IF EXISTS ecommerce_sales_clean CASCADE;

-- Create cleaned table while preserving the original dataset
CREATE TABLE ecommerce_sales_clean AS
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


-- Drop table if exists to ensure re-runnability
DROP TABLE IF EXISTS ecommerce_sales_final CASCADE;

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

-- Pre-checks that justify the classification rules below:

-- a) Zero-price records (free items / giveaways)
SELECT COUNT(*) AS zero_price_records
FROM ecommerce_sales_final
WHERE price = 0;
-- Result: 1,060 records

-- b) Negative-price records (accounting entries, not sales)
SELECT invoice, stockcode, description, quantity, price
FROM ecommerce_sales_final
WHERE price < 0;
-- Result: 2 records - "Adjust bad debt" on invoices A563186 / A563187 (£-11,062.06 each)

-- AUDIT FIX:
-- The original script classified rows into only 3 types (Sale / Cancellation /
-- Internal Adjustment), but the production table ecommerce_sales_classified
-- contains FIVE types. The zero-price and negative-price records were silently
-- labelled 'Sale', which inflated revenue KPIs with £0 lines and bad-debt
-- adjustments. The CASE below reproduces the real classification exactly and
-- makes the script reproducible from scratch.

-- Drop table if exists to ensure re-runnability
DROP TABLE IF EXISTS ecommerce_sales_classified CASCADE;

CREATE TABLE ecommerce_sales_classified AS
SELECT
    *,
    CASE
        -- Cancellations: negative quantity + 'C' prefix on invoice number
        WHEN quantity < 0 AND LEFT(invoice, 1) = 'C'
            THEN 'Cancellation'
        -- Stock write-offs / samples: negative quantity, non-C invoice.
        -- All 474 of these are also zero-price lines (damaged stock etc.)
        WHEN quantity < 0
            THEN 'Internal Adjustment'
        -- Accounting corrections (negative prices, e.g. bad-debt adjustments)
        WHEN price < 0
            THEN 'Accounting Adjustment'
        -- Free items given away at zero price (positive quantity)
        WHEN price = 0
            THEN 'Free/Zero-Price Item'
        -- Genuine revenue-generating sale lines
        ELSE 'Sale'
    END AS transaction_type
FROM ecommerce_sales_final;


-- Verify transaction classification
SELECT
    transaction_type,
    COUNT(*) AS record_count
FROM ecommerce_sales_classified
GROUP BY transaction_type
ORDER BY record_count DESC;

-- Result:
-- Sale                   : 524,874
-- Cancellation           :   9,251
-- Free/Zero-Price Item   :     586
-- Internal Adjustment    :     474
-- Accounting Adjustment  :       2
-- Total                  : 535,187

-- ==========================================================
-- Question 4: Final data-quality checks on the classified table
-- Added during audit to close the cleaning loop with hard evidence.
-- ==========================================================

-- Final NULL check per column
SELECT
    COUNT(*) FILTER (WHERE invoice      IS NULL) AS null_invoice,
    COUNT(*) FILTER (WHERE description  IS NULL) AS null_description,
    COUNT(*) FILTER (WHERE quantity     IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE invoicedate  IS NULL) AS null_invoicedate,
    COUNT(*) FILTER (WHERE price        IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE customer_id  IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE country      IS NULL) AS null_country
FROM ecommerce_sales_classified;
-- Result: only customer_id contains NULLs (133,583 = ~24.9%).
-- These are kept deliberately: the sales are valid, they just cannot be
-- attributed to a named customer. Customer-level analyses exclude them.

-- Final duplicate check (exact full-row duplicates)
SELECT
    COUNT(*) AS duplicate_groups,
    COALESCE(SUM(row_count - 1), 0) AS duplicate_copies
FROM (
    SELECT COUNT(*) AS row_count
    FROM ecommerce_sales_classified
    GROUP BY invoice, stockcode, description, quantity,
             invoicedate, price, customer_id, country, transaction_type
    HAVING COUNT(*) > 1
) AS dup;
-- Result: 0 groups, 0 copies