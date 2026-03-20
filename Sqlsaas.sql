Create Table raw_ecom(
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

Select * From raw_ecom;

SELECT COUNT(*) FROM raw_ecom;

SELECT event_type, COUNT(*) AS count
FROM raw_ecom
GROUP BY event_type
ORDER BY count DESC;

SELECT MIN(event_time), MAX(event_time) FROM raw_ecom;

-- Q1: How many total unique users, sessions, and events 
--     are in the dataset?

SELECT
    COUNT(*)                        AS total_events,
    COUNT(DISTINCT user_id)         AS unique_users,
    COUNT(DISTINCT user_session)    AS unique_sessions,
    COUNT(DISTINCT product_id)      AS unique_products
FROM raw_ecom;

-- Q2: What is the breakdown of event types 

SELECT
    event_type,
    COUNT(*)                                            AS total_events,
    COUNT(DISTINCT user_id)                             AS unique_users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)  AS pct_of_total
FROM raw_ecom
GROUP BY event_type
ORDER BY total_events DESC;


-- Q3: What are the top 10 best selling brands 
--     by total purchases?


SELECT
    brand,
    COUNT(*)                        AS total_purchases,
    ROUND(SUM(price), 2)            AS total_revenue,
    ROUND(AVG(price), 2)            AS avg_price
FROM raw_ecom
WHERE event_type = 'purchase'
  AND brand IS NOT NULL
GROUP BY brand
ORDER BY total_purchases DESC
LIMIT 10;


-- Q4: What is the total revenue and the number of purchases 
--     per product category?

SELECT
    SPLIT_PART(category_code, '.', 1)   AS category,
    COUNT(*)                            AS total_purchases,
    ROUND(SUM(price), 2)                AS total_revenue,
    ROUND(AVG(price), 2)                AS avg_order_value
FROM raw_ecom
WHERE event_type = 'purchase'
  AND category_code IS NOT NULL
GROUP BY SPLIT_PART(category_code, '.', 1)
ORDER BY total_revenue DESC;


-- Q5: How many events happen each day? 
--     What is the daily activity trend?

SELECT
    event_time::DATE                AS event_date,
    COUNT(*)                        AS total_events,
    COUNT(DISTINCT user_id)         AS active_users,
    COUNT(DISTINCT user_session)    AS total_sessions
FROM raw_ecom
GROUP BY event_time::DATE
ORDER BY event_date;


-- Q6: What is the overall purchase conversion rate?

SELECT
    COUNT(DISTINCT user_id)  AS total_users,
    COUNT(DISTINCT CASE 
        WHEN event_type = 'purchase' THEN user_id 
    END) AS buyers,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' 
              THEN user_id END)
        * 100.0 / COUNT(DISTINCT user_id), 2
    )   AS conversion_rate_pct
FROM raw_ecom;


-- Q7: What is the daily revenue trend with a 
--     7-day rolling average?

WITH daily_revenue AS (
    SELECT
        event_time::DATE                AS sale_date,
        ROUND(SUM(price), 2)            AS daily_revenue,
        COUNT(*)                        AS total_purchases
    FROM raw_ecom
    WHERE event_type = 'purchase'
    GROUP BY event_time::DATE
)
SELECT
    sale_date,
    daily_revenue,
    total_purchases,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)                               AS rolling_7day_avg_revenue
FROM daily_revenue
ORDER BY sale_date;


-- Q8: Who are the top 100 highest value customers 
--     by total spend?

SELECT
    user_id,
    COUNT(*)                            AS total_purchases,
    ROUND(SUM(price), 2)                AS total_spent,
    ROUND(AVG(price), 2)                AS avg_order_value,
    MIN(event_time::DATE)               AS first_purchase,
    MAX(event_time::DATE)               AS last_purchase,
    RANK() OVER (ORDER BY SUM(price) DESC) AS spend_rank
FROM raw_ecom
WHERE event_type = 'purchase'
GROUP BY user_id
ORDER BY total_spent DESC
LIMIT 100;


-- Q9: What hour of the day and day of the week 
--      drives the most purchases?

-- By hour of day
SELECT
    EXTRACT(HOUR FROM event_time)       AS hour_of_day,
    COUNT(*)                            AS total_purchases,
    ROUND(SUM(price), 2)                AS total_revenue
FROM raw_ecom
WHERE event_type = 'purchase'
GROUP BY EXTRACT(HOUR FROM event_time)
ORDER BY total_purchases DESC;

-- By day of week
SELECT
    TO_CHAR(event_time, 'Day')          AS day_of_week,
    EXTRACT(DOW FROM event_time)        AS day_num,
    COUNT(*)                            AS total_purchases,
    ROUND(SUM(price), 2)                AS total_revenue
FROM raw_ecom
WHERE event_type = 'purchase'
GROUP BY TO_CHAR(event_time, 'Day'), EXTRACT(DOW FROM event_time)
ORDER BY day_num;


-- Q10: Which products have the highest view-to-purchase 
--      ratio?

WITH product_views AS (
    SELECT product_id, COUNT(*) AS views
    FROM raw_ecom
    WHERE event_type = 'view'
    GROUP BY product_id
),
product_purchases AS (
    SELECT product_id, COUNT(*) AS purchases
    FROM raw_ecom
    WHERE event_type = 'purchase'
    GROUP BY product_id
)
SELECT
    v.product_id,
    v.views,
    COALESCE(p.purchases, 0)            AS purchases,
    ROUND(
        COALESCE(p.purchases, 0) * 100.0 / v.views, 2
    )                                   AS conversion_rate_pct
FROM product_views v
LEFT JOIN product_purchases p ON v.product_id = p.product_id
WHERE v.views >= 100                    -- min 100 views for significance
ORDER BY conversion_rate_pct DESC
LIMIT 20;


-- Q19: Rank brands by revenue within each category

WITH brand_category_revenue AS (
    SELECT
        SPLIT_PART(category_code, '.', 1)   AS category,
        brand,
        COUNT(*)                            AS total_purchases,
        ROUND(SUM(price), 2)                AS total_revenue
    FROM raw_ecom
    WHERE event_type = 'purchase'
      AND brand IS NOT NULL
      AND category_code IS NOT NULL
    GROUP BY
        SPLIT_PART(category_code, '.', 1),
        brand
)
SELECT
    category,
    brand,
    total_purchases,
    total_revenue,
    RANK() OVER (
        PARTITION BY category
        ORDER BY total_revenue DESC
    )                                       AS rank_in_category,
    ROUND(
        total_revenue * 100.0 /
        SUM(total_revenue) OVER (PARTITION BY category), 2
    )                                       AS pct_of_category_revenue
FROM brand_category_revenue
ORDER BY category, rank_in_category
LIMIT 50;


-- Q14: What is the repeat purchase rate?
--      How many users bought more than once?


WITH purchase_counts AS (
    SELECT
        user_id,
        COUNT(*)                        AS total_purchases
    FROM raw_ecom
    WHERE event_type = 'purchase'
    GROUP BY user_id
)
SELECT
    CASE
        WHEN total_purchases = 1  THEN '1 purchase (one-time)'
        WHEN total_purchases = 2  THEN '2 purchases'
        WHEN total_purchases <= 5 THEN '3-5 purchases'
        WHEN total_purchases <= 10 THEN '6-10 purchases'
        ELSE '10+ purchases (loyal)'
    END                                 AS purchase_bucket,
    COUNT(*)                            AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_buyers
FROM purchase_counts
GROUP BY
    CASE
        WHEN total_purchases = 1  THEN '1 purchase (one-time)'
        WHEN total_purchases = 2  THEN '2 purchases'
        WHEN total_purchases <= 5 THEN '3-5 purchases'
        WHEN total_purchases <= 10 THEN '6-10 purchases'
        ELSE '10+ purchases (loyal)'
    END
ORDER BY user_count DESC;