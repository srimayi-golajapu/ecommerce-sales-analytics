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


## Phase 3: Data Cleaning

### Question 1: Are there any missing values in the dataset?

#### Observation

The `description` and `customer_id` columns contain missing values, while the remaining columns are complete.

#### Insight

Missing `customer_id` values do not invalidate a transaction because the sale details are still available. These records should be retained for revenue and sales analysis but excluded from customer-specific analyses.

### Missing Description Analysis

The `description` column contained 1,454 missing values, representing approximately 0.27% of the original dataset.

The affected records were investigated and found to contain incomplete transaction information, including missing descriptions and zero-valued prices. These records were excluded from the cleaned dataset.

The original dataset contained 541,909 records, while the cleaned dataset contains 540,455 records. No NULL descriptions remain in the cleaned dataset.

### Duplicate Record Analysis

The cleaned dataset contained 4,879 groups of duplicate records, representing 5,268 duplicate copies.

The duplicate records were removed using `SELECT DISTINCT`, while preserving one valid copy of each unique transaction line.

The dataset was reduced from 540,455 records to 535,187 records. A final duplicate check returned zero duplicate groups.

### Negative Quantity Analysis

The final cleaned dataset contained 9,725 records with negative quantities.

These records were not removed because they represent meaningful business events.

Based on invoice patterns, 9,251 records were classified as cancellations because their invoice numbers began with `C`. The remaining 474 negative-quantity records were classified as internal adjustments because they were associated with inventory-related activities such as damaged goods, samples, and other adjustments.

The final dataset contains 525,462 normal sales records, 9,251 cancellation records, and 474 internal adjustment records.

### 6.1 Total Revenue

#### SQL Query

```sql
SELECT
    SUM(quantity * price) AS total_revenue
FROM ecommerce_sales_classified
WHERE transaction_type = 'Sale';
