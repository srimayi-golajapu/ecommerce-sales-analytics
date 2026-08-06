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

-- Question 5: date range of the dataset
SELECT MIN(invoicedate) AS start_date,MAX(invoicedate) AS end_date
FROM ecommerce_sales;

-- Question 6: Which countries are included in the dataset?

SELECT DISTINCT country
FROM ecommerce_sales;
