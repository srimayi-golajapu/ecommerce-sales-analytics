# Business Insights

## Phase 1: Data Exploration

---

### Question 1: How many records are available in the dataset?

#### SQL Query

```sql
SELECT COUNT(*) AS total_records
FROM ecommerce_sales;
```

#### Observation

The dataset contains **541,909** records. Each record represents a single product purchased within a customer invoice.

#### Insight

The data is stored at the transaction line-item level rather than the invoice level. This enables detailed analysis of individual product sales, customer purchasing behavior, and order composition.

---

### Question 2: How many unique customers are available in the dataset?

#### SQL Query

```sql
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM ecommerce_sales;
```

#### Observation

The dataset contains **4,372** unique customers with valid customer IDs.

#### Insight

The customer base consists of 4,372 identified customers. This provides a strong foundation for customer-focused analyses such as identifying high-value customers, purchase frequency, customer segmentation, and retention patterns.

---

### Question 3: How many unique transactions are available in the dataset?

#### SQL Query

```sql
SELECT COUNT(DISTINCT invoice) AS total_transactions
FROM ecommerce_sales;
```

#### Observation

The dataset contains **<25900>** unique customer transactions.

#### Insight

Each unique invoice represents one completed customer order. Since a single order can contain multiple products, the total number of transactions is lower than the total number of records. This distinction is important when analyzing customer purchasing behavior, order frequency, and overall sales performance.

---

### Question 4: How many unique products are available in the dataset?

#### SQL Query

```sql
SELECT COUNT(DISTINCT stockcode) AS total_products
FROM ecommerce_sales;
```

#### Observation

The dataset contains **<4070>** unique products identified by their stock codes.

#### Insight

Each stock code represents a unique product in the catalog. Understanding the number of distinct products helps evaluate the size of the product portfolio and supports future analyses such as identifying top-selling products, product demand, and inventory planning.

---

### Question 5: What is the date range of the dataset?

#### SQL Query

```sql
SELECT
    MIN(invoicedate) AS start_date,
    MAX(invoicedate) AS end_date
FROM ecommerce_sales;
```

#### Observation

The dataset contains transaction records from **<2010-12-01 08:26:00>** to **<2011-12-09 12:50:00>**.

#### Insight

The dataset spans approximately one year of sales activity. This time period is sufficient to analyze seasonal demand, monthly sales trends, customer purchasing patterns, and year-end business performance.

---

### Question 6: Which countries are included in the dataset?

#### SQL Query

```sql
SELECT DISTINCT country
FROM ecommerce_sales;
```

#### Observation

The dataset contains transactions from multiple countries, indicating that the business serves an international customer base.

#### Insight

The presence of customers from different countries enables geographical analysis of sales performance. This can help identify key markets, compare regional demand, and support decisions related to international expansion and localized marketing strategies.

