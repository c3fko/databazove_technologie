-- Active: 1790526834652@@127.0.0.1@5432@superstore
WITH ranked_orders AS (
    SELECT 
        c.customer_name,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id 
            ORDER BY o.order_date DESC, o.order_id DESC
        ) AS rn
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
)
SELECT 
    customer_name,
    order_id,
    order_date
FROM ranked_orders
WHERE rn <= 2
ORDER BY customer_name ASC, rn ASC;
-- uloha 2
WITH customer_profit AS (
    SELECT 
        c.region,
        c.customer_name,
        SUM(o.profit) AS total_profit
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.region, c.customer_name
)
SELECT 
    region,
    customer_name,
    total_profit,
    RANK() OVER (PARTITION BY region ORDER BY total_profit DESC) AS rank,
    DENSE_RANK() OVER (PARTITION BY region ORDER BY total_profit DESC) AS dense_rank
FROM customer_profit
ORDER BY region ASC, total_profit DESC;
-- uloha 3
WITH customer_sales AS (
    SELECT 
        c.customer_name,
        SUM(o.sales) AS total_sales
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT 
    customer_name,
    total_sales,
    NTILE(4) OVER (ORDER BY total_sales DESC) AS quartile
FROM customer_sales
ORDER BY total_sales DESC;
-- uloha 4
WITH monthly_summary AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    monthly_sales,
    LAG(monthly_sales, 1) OVER (ORDER BY month ASC) AS prev_month_sales,
    LEAD(monthly_sales, 1) OVER (ORDER BY month ASC) AS next_month_sales
FROM monthly_summary
ORDER BY month ASC;
-- uloha 5
WITH product_sales_cte AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(o.sales) AS product_sales
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT 
    category,
    product_name,
    product_sales,
    SUM(product_sales) OVER (PARTITION BY category) AS category_total,
    ROUND(
        product_sales * 100.0 / SUM(product_sales) OVER (PARTITION BY category),
        2
    ) AS pct_of_category
FROM product_sales_cte;
-- uloha 6
WITH customer_orders AS (
    SELECT DISTINCT
        c.customer_id,
        c.customer_name,
        MAX(o.order_date) OVER (PARTITION BY c.customer_id) AS last_order_date,
        MAX(o.order_date) OVER () AS latest_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
)
SELECT 
    customer_id,
    customer_name,
    last_order_date
FROM customer_orders
WHERE last_order_date < latest_order_date - INTERVAL '90 days'
ORDER BY last_order_date ASC;
-- uloha 7
WITH monthly_sales_summary AS (
    SELECT 
        DATE_TRUNC('month', order_date)::DATE AS month,
        SUM(sales) AS monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)::DATE
),
monthly_with_lag AS (
    SELECT 
        month,
        monthly_sales,
        LAG(monthly_sales) OVER (ORDER BY month) AS prev_month_sales
    FROM monthly_sales_summary
)
SELECT 
    month,
    monthly_sales,
    prev_month_sales,
    (monthly_sales - prev_month_sales) AS sales_change,
    ROUND(
        ((monthly_sales - prev_month_sales) * 100.0 / prev_month_sales),
        2
    ) AS growth_percentage
FROM monthly_with_lag
ORDER BY month ASC;
-- uloha 8
WITH first_purchases AS (
    SELECT 
        customer_id,
        MIN(DATE_TRUNC('month', order_date)) AS first_month
    FROM orders
    GROUP BY customer_id
)
SELECT 
    COUNT(DISTINCT fp.customer_id) AS returning_customers_count
FROM first_purchases fp
WHERE fp.first_month = '2024-06-01'
  AND EXISTS (
      SELECT 1 
      FROM orders o 
      WHERE o.customer_id = fp.customer_id 
        AND DATE_TRUNC('month', o.order_date) > fp.first_month
  );