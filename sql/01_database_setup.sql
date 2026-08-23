-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 01_database_setup.sql
-- Author  : Srimayi G
-- Purpose : Create the main table for storing e-commerce
--           transaction data.
-- ==========================================================

-- Drop table if it already exists to ensure re-runnability
DROP TABLE IF EXISTS ecommerce_sales CASCADE;

CREATE TABLE ecommerce_sales (
    invoice VARCHAR(20),
    stockcode VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    invoicedate TIMESTAMP,
    price DECIMAL(10,2),
    customer_id INTEGER,
    country VARCHAR(100)
);

-- Dataset:
-- Online Retail Dataset (UCI Machine Learning Repository)

-- Import Method:
-- Imported using pgAdmin Import/Export Tool.

-- CAUTION:
-- The DROP statement above makes this script re-runnable, but it also
-- deletes all raw data on re-run. After running it, re-import
-- dataset/Online_Retail.csv before executing any later scripts.
-- Column mapping used in pgAdmin (CSV header -> column):
--   InvoiceNo->invoice | StockCode->stockcode | Description->description
--   Quantity->quantity | InvoiceDate->invoicedate (DD-MM-YYYY HH24:MI)
--   UnitPrice->price   | CustomerID->customer_id | Country->country
