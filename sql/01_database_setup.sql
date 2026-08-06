-- ==========================================================
-- Project : E-commerce Sales Analytics using SQL
-- File    : 01_database_setup.sql
-- Author  : Srimayi G
-- Purpose : Create the main table for storing e-commerce
--           transaction data.
-- ==========================================================

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
