# 🛒 E-Commerce Behavior Analysis — SQL Case Study

An end-to-end SQL analytics project built on **42 million rows** of real e-commerce event data. This project answers 12 business questions that mirror real-world data analyst work — covering user behavior, revenue trends, product performance, and customer segmentation.

---

## 📁 Dataset

| Property | Details |
|---|---|
| **Source** | [eCommerce Behavior Data — Kaggle](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store) |
| **File Used** | `2019-Oct.csv` |
| **Total Rows** | ~42 million events |
| **Time Period** | October 2019 |
| **Platform** | PostgreSQL |

### Table Schema — `raw_ecom`

```sql
CREATE TABLE raw_ecom (
    event_time      TIMESTAMP,
    event_type      VARCHAR(20),    -- 'view', 'cart', 'purchase'
    product_id      BIGINT,
    category_id     BIGINT,
    category_code   VARCHAR(100),   -- e.g. 'electronics.smartphone'
    brand           VARCHAR(100),
    price           DECIMAL(10, 2),
    user_id         BIGINT,
    user_session    VARCHAR(100)
);
```

---

## ❓ Business Questions Answered

### 🟢 Basic (Q1–Q6)

| # | Question | Concepts Used |
|---|---|---|
| Q1 | How many total unique users, sessions, events and products are in the dataset? | `COUNT DISTINCT` |
| Q2 | What is the breakdown of event types — view vs cart vs purchase? | `GROUP BY`, `SUM() OVER()`, percentage |
| Q3 | What are the top 10 best selling brands by total purchases? | `WHERE`, `GROUP BY`, `SUM`, `AVG` |
| Q4 | What is the total revenue and purchases per product category? | `SPLIT_PART`, `SUM`, `AVG`, `GROUP BY` |
| Q5 | How many events happen each day — what is the daily activity trend? | `DATE casting`, `COUNT DISTINCT` |
| Q6 | What is the overall purchase conversion rate? | `COUNT DISTINCT`, `CASE WHEN`, percentage |

### 🟡 Intermediate (Q7–Q12)

| # | Question | Concepts Used |
|---|---|---|
| Q7 | What is the daily revenue trend with a 7-day rolling average? | `CTE`, `AVG() OVER()`, `ROWS BETWEEN` |
| Q8 | Who are the top 100 highest value customers by total spend? | `RANK()`, `SUM`, `MIN`, `MAX` |
| Q9 | What hour of day and day of week drives the most purchases? | `EXTRACT`, `TO_CHAR` |
| Q10 | Which products have the highest view-to-purchase conversion rate? | `CTE`, `LEFT JOIN`, `COALESCE` |
| Q11 | Rank brands by revenue within each category | `CTE`, `RANK()`, `PARTITION BY`, `SUM() OVER()` |
| Q12 | What is the repeat purchase rate — how many users bought more than once? | `CTE`, `CASE WHEN` buckets, `SUM() OVER()` |

---

## 💡 Key Insights

### 📊 Platform Scale
- Over **42 million events** across **~1.4 million unique users** and **~8.5 million sessions**
- Dataset covers the entire month of October 2019

### 🔄 Conversion Funnel
- The large majority of events are **views** — cart additions and purchases are significantly lower
- This drop-off from view → cart → purchase is the biggest revenue recovery opportunity

### 🏆 Top Brands & Categories
- A small set of brands drive a disproportionate share of revenue — a classic Pareto pattern
- Electronics dominates both purchase volume and total revenue across categories

### 📅 Purchase Timing
- Clear patterns in **hour of day and day of week** — actionable for scheduling flash sales, email campaigns, and push notifications

### 👥 Customer Loyalty
- The majority of buyers are **one-time purchasers**
- Repeat buyers (2+ purchases) are a small but significantly higher-value segment

### 📈 Revenue Trend
- The 7-day rolling average reveals true revenue momentum by smoothing out daily noise and weekend dips

---

## 🛠️ SQL Concepts Demonstrated

```
✅ COUNT, COUNT DISTINCT, SUM, AVG, ROUND
✅ WHERE, GROUP BY, ORDER BY, LIMIT
✅ CASE WHEN — conditional logic and purchase bucketing
✅ Percentage calculations using SUM() OVER()
✅ CTEs (WITH clause)            — Q7, Q10, Q11, Q12
✅ Window Functions
    - RANK() OVER()              — Q8  (customer spend ranking)
    - RANK() PARTITION BY        — Q11 (brand rank within category)
    - AVG() OVER() ROWS BETWEEN  — Q7  (7-day rolling average)
    - SUM() OVER()               — Q2, Q11, Q12 (% of total)
✅ LEFT JOIN + COALESCE          — Q10 (handle products with no purchases)
✅ Date Functions
    - event_time::DATE           — casting timestamp to date
    - EXTRACT(HOUR / DOW)        — hour of day, day of week
    - TO_CHAR                    — formatting day names
✅ SPLIT_PART                    — Q4, Q11 (parsing category hierarchy)
```

---

## 🚀 How to Run This Project

### Prerequisites
- PostgreSQL installed
- pgAdmin or any PostgreSQL client
- Dataset downloaded from Kaggle (link above)

### Step 1 — Create the table
```sql
CREATE TABLE raw_ecom (
    event_time      TIMESTAMP,
    event_type      VARCHAR(20),
    product_id      BIGINT,
    category_id     BIGINT,
    category_code   VARCHAR(100),
    brand           VARCHAR(100),
    price           DECIMAL(10, 2),
    user_id         BIGINT,
    user_session    VARCHAR(100)
);
```

### Step 2 — Load the data
Open CMD or PowerShell and run:
```bash
psql -U postgres -d your_database_name -c "\COPY raw_ecom FROM 'your/path/2019-October.csv' CSV HEADER DELIMITER ',';"
```
> ⚠️ Use forward slashes `/` in the file path. This will take 5–10 minutes for 42M rows.

### Step 3 — Verify the load
```sql
-- Should return ~42 million
SELECT COUNT(*) FROM raw_ecom;

-- Should return 2019-10-01 to 2019-10-31
SELECT MIN(event_time), MAX(event_time) FROM raw_ecom;

-- Check event distribution
SELECT event_type, COUNT(*) FROM raw_ecom GROUP BY event_type;
```

### Step 4 — Run the queries
Open `queries.sql` and run each question block one by one in pgAdmin.

---

## 📂 Project Structure

```
ecommerce-sql-case-study/
│
├── README.md        ← Project overview and documentation
├── schema.sql       ← Table creation script and all 12 business questions with comments

```

---

## 🙋 About This Project

This project was built as part of my data analyst portfolio to demonstrate real-world SQL skills on production-scale data. All queries were written and tested on **42 million rows** in PostgreSQL.

The goal was not just to write SQL — but to answer genuine business questions, the kind that come up in analyst roles and day-to-day data work.

---

