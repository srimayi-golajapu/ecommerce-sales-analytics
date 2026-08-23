# 🛒 E-commerce Sales Analytics

### Business-Driven Sales & Customer Analysis using PostgreSQL

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Data%20Analysis-4479A1?style=for-the-badge&logo=databricks&logoColor=white)
![Data Analysis](https://img.shields.io/badge/Data%20Analysis-Business%20Analytics-2E8B57?style=for-the-badge)
![GitHub](https://img.shields.io/badge/GitHub-Portfolio%20Project-181717?style=for-the-badge&logo=github&logoColor=white)

---

## 📖 Project Overview

This project uses the UCI Online Retail dataset containing 541,909 raw transaction records from an online gift retailer.

The raw dataset contains missing customer IDs, duplicate records, missing descriptions, negative quantities, zero-price transactions, accounting adjustments, cancellations, and non-product transaction codes.

The project follows a complete SQL analytics workflow:

```text
Raw Data
   ↓
Data Exploration
   ↓
Data Cleaning
   ↓
Transaction Classification
   ↓
Business Analysis
   ↓
Product Analysis
   ↓
Customer Analysis
   ↓
Advanced SQL Analysis
   ↓
Business Insights
```

---

## 🎯 Business Objectives

- Calculate reliable revenue, volume, invoice, customer, and AOV KPIs
- Analyze monthly and daily sales trends
- Compare market performance across countries
- Measure cancellation volume and financial impact
- Identify top products by revenue and units sold
- Analyze customer value, frequency, and loyalty
- Apply advanced SQL to real business questions
- Convert SQL results into actionable business insights

---

## 📊 Dataset

| Property | Details |
|---|---|
| Source | UCI Online Retail Dataset |
| Raw Records | 541,909 |
| Clean Records | 535,187 |
| Time Period | 2010-12-01 to 2011-12-09 |
| Countries | 38 |
| Grain | One row per invoice line item |

### Main Columns

| Column | Description |
|---|---|
| `invoice` | Invoice or transaction number |
| `stockcode` | Product or transaction code |
| `description` | Product description |
| `quantity` | Quantity purchased |
| `invoicedate` | Transaction date and time |
| `price` | Unit price |
| `customer_id` | Customer identifier |
| `country` | Customer country |

---

## 🛠️ Tech Stack

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Data%20Analysis-4479A1?style=for-the-badge&logo=databricks&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-Version%20Control-181717?style=for-the-badge&logo=github&logoColor=white)

**Core Tools:** PostgreSQL • SQL • GitHub

---

## 📁 Project Structure

```text
ecommerce-sales-analytics/
│
├── dataset/
│   └── Online_Retail.csv
│
├── sql/
│   ├── 01_database_setup.sql
│   ├── 02_data_exploration.sql
│   ├── 03_data_cleaning.sql
│   ├── 04_business_analysis.sql
│   ├── 05_advanced_sql.sql
│   ├── 06_product_analysis.sql
│   └── 07_customer_analysis.sql
│
└── docs/
    └── Analysis_Report.md
```

---

## 🧹 Data Cleaning

The project uses staged tables to keep the cleaning process reproducible.

```text
ecommerce_sales
541,909 raw records
        ↓
Remove 1,454 rows with NULL description
        ↓
ecommerce_sales_clean
540,455 records
        ↓
Remove 5,268 exact duplicate copies
        ↓
ecommerce_sales_final
535,187 records
        ↓
Classify transactions
        ↓
ecommerce_sales_classified
535,187 records
```

### Cleaning Activities

- Checked missing descriptions
- Checked missing customer IDs
- Identified exact duplicates
- Removed duplicate copies
- Investigated negative quantities
- Identified cancellation transactions
- Identified internal adjustments
- Identified accounting adjustments
- Identified zero-price transactions
- Classified transaction types using `CASE WHEN`
- Verified the final record count

### Transaction Classification

| Transaction Type | Description |
|---|---|
| Sale | Normal sales transaction |
| Cancellation | Cancelled transaction |
| Internal Adjustment | Negative-quantity adjustment not classified as a cancellation |
| Accounting Adjustment | Negative-price accounting entry |
| Free/Zero-Price Item | Transaction with zero price |

Missing customer IDs are retained for overall sales analysis but excluded from customer-level metrics.

---

## 📌 Key Business KPIs

| KPI | Result |
|---|---:|
| Total Revenue | £10,642,110.80 |
| Total Units Sold | 5,572,416 |
| Sales Invoices | 19,960 |
| Identified Customers | 4,338 |
| Average Order Value | £533.17 |
| Cancelled Invoices | 3,836 |
| Cancellation Rate | 19.22% |
| Cancelled Units | 275,560 |
| Cancelled Revenue Impact | £893,979.73 |
| Cancellation Revenue Impact | 8.40% |

---

## 📈 Business Analysis

### Monthly Sales Analysis

- November 2011 recorded the highest monthly revenue at approximately £1.50 million.
- February 2011 recorded the lowest monthly revenue at approximately £522.55K.
- May 2011 recorded the largest month-over-month increase at 43.27%.
- December 2011 recorded the largest month-over-month decline at 57.59%.

December 2011 is an incomplete period because the dataset ends on 9 December 2011.

### Daily Sales Analysis

- Highest recorded daily revenue: 9 December 2011
- Highest daily revenue: £200,900.98
- Lowest recorded daily revenue: 1 December 2010
- Lowest daily revenue: £58,776.79

### Geographic Analysis

The United Kingdom is the dominant market.

| Metric | United Kingdom |
|---|---:|
| Revenue | £9,001,744.09 |
| Revenue Contribution | 84.59% |
| Units Sold | 4,646,902 |
| Sales Invoices | 18,019 |
| Identified Customers | 3,920 |

### Cancellation Analysis

- Cancelled invoices: 3,836
- Cancellation rate: 19.22%
- Cancelled units: 275,560
- Cancelled revenue impact: £893,979.73
- Cancellation revenue impact: 8.40%

The project distinguishes cancellation records from other negative-quantity transactions instead of treating every negative quantity as a cancellation.

---

## 🛍️ Product Analysis

Product analysis evaluates both sales volume and revenue.

It includes:

- Top products by units sold
- Top products by revenue
- Average selling price
- Product revenue contribution
- Product cancellation activity
- Product rankings
- Product performance by country

### Non-Product Transaction Codes

Some stock codes are charges or manual entries rather than normal products.

| Stock Code | Treatment |
|---|---|
| `DOT` | Postage-related charge |
| `POST` | Shipping/postage charge |
| `M` | Manual entry or adjustment |

These codes are excluded from product rankings so that transaction charges are not incorrectly presented as products.

---

## 👥 Customer Analysis

Customer analysis focuses only on identified customers.

It includes:

- Revenue by customer
- Top customers by revenue
- Customer invoice frequency
- Average customer order value
- Repeat customers
- One-time customers
- Customer revenue contribution
- Customer rankings
- Customer activity by country
- High-value customer identification

Anonymous transactions are excluded from customer-level metrics.

---

## 🧠 Advanced SQL Concepts

The project applies advanced SQL to real business questions.

- CTEs
- Subqueries
- Window functions
- `LAG()`
- `LEAD()`
- `RANK()`
- `DENSE_RANK()`
- `ROW_NUMBER()`
- Running totals
- Percentage-of-total calculations
- `CASE WHEN`
- Conditional aggregation
- `DATE_TRUNC()`
- Date functions
- `EXTRACT()`
- `COALESCE()`
- `NULLIF()`
- NULL handling

---

## 💡 Key Insights

### 1. Revenue is highly concentrated in the UK

The United Kingdom contributes 84.59% of total sales revenue.

### 2. Sales increase strongly toward the end of the year

November 2011 is the strongest recorded month. The final December period is incomplete and must be interpreted accordingly.

### 3. Cancellations have a meaningful financial impact

Cancelled revenue represents £893,979.73, equivalent to 8.40% of normal sales revenue.

### 4. Product volume and product revenue are different measures

A product can sell many units without being the highest-revenue product. The project therefore analyzes both metrics separately.

### 5. Customer-level analysis requires reliable customer IDs

Transactions without customer IDs remain useful for overall sales analysis but cannot be reliably assigned to individual customers.

---

## 🎯 Business Recommendations

1. Reduce dependency on the UK by identifying opportunities in other markets.
2. Investigate the causes of cancellations and separate genuine cancellations from operational and accounting adjustments.
3. Monitor high-revenue products separately from high-volume products.
4. Protect inventory availability during strong seasonal periods.
5. Improve customer identification at checkout.
6. Focus retention efforts on high-value and repeat customers.
7. Investigate unusually large transactions and cancellation pairs separately from normal activity.

---

## 💻 SQL Concepts Demonstrated

The project covers:

- `SELECT`
- `WHERE`
- `ORDER BY`
- `GROUP BY`
- `HAVING`
- Aggregate functions
- `CASE WHEN`
- Conditional aggregation
- CTEs
- Subqueries
- Window functions
- `LAG()`
- `LEAD()`
- `RANK()`
- `DENSE_RANK()`
- `ROW_NUMBER()`
- Running totals
- Percentage-of-total calculations
- `DATE_TRUNC()`
- Date and time functions
- NULL handling

---

## ▶️ How to Run

Run the SQL files in this order:

```text
01_database_setup.sql
        ↓
02_data_exploration.sql
        ↓
03_data_cleaning.sql
        ↓
04_business_analysis.sql
        ↓
05_advanced_sql.sql
        ↓
06_product_analysis.sql
        ↓
07_customer_analysis.sql
```

Then review:

```text
docs/Analysis_Report.md
```

---

## 🏆 Project Outcome

This project demonstrates the ability to take messy transactional data and turn it into reproducible SQL analysis and business findings.

It demonstrates:

- Real-world data cleaning
- Transaction classification
- KPI development
- Trend analysis
- Geographic analysis
- Product analysis
- Customer analysis
- Advanced SQL
- Business insight generation

Every major metric should be traceable back to an executable SQL query in the project.

---

## 👤 Author

**Srimayi G**

[GitHub](https://github.com/srimayi-golajapu)
