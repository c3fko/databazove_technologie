-- Active: 1790526834652@@127.0.0.1@5432@datacraftinglab_db
WITH daily_sales AS (
    SELECT 
        sale_date, 
        SUM(total_amount) AS total_daily_sales
    FROM flourmills_sales
    GROUP BY sale_date
)
SELECT 
    sale_date, 
    total_daily_sales
FROM daily_sales
WHERE total_daily_sales > 3000000
ORDER BY total_daily_sales DESC;

-- druha 
WITH category_sales AS (
    SELECT 
        product_category,
        SUM(total_amount) AS total_sales
    FROM flourmills_sales
    GROUP BY product_category
)
SELECT 
    product_category,
    total_sales
FROM category_sales
ORDER BY total_sales DESC;

--tretia
WITH product_sales AS (
    SELECT 
        product_category,
        product_name,
        SUM(total_amount) AS total_product_sales
    FROM flourmills_sales
    GROUP BY product_category, product_name
),
ranked_products AS (
    SELECT 
        product_category,
        product_name,
        total_product_sales,
        RANK() OVER (PARTITION BY product_category ORDER BY total_product_sales DESC) AS category_rank
    FROM product_sales
)
SELECT 
    product_category,
    product_name,
    total_product_sales,
    category_rank
FROM ranked_products
WHERE category_rank <= 3
ORDER BY product_category ASC, category_rank ASC;

--stvrtka
WITH customer_revenue AS (
    SELECT 
        customer_type,
        SUM(total_amount) AS revenue
    FROM flourmills_sales
    GROUP BY customer_type
),
calculated_shares AS (
    SELECT 
        customer_type,
        revenue,
        SUM(revenue) OVER () AS total_revenue,
        ROUND((revenue / SUM(revenue) OVER ()) * 100, 2) AS revenue_percentage
    FROM customer_revenue
)
SELECT 
    customer_type,
    revenue,
    total_revenue,
    revenue_percentage
FROM calculated_shares
ORDER BY revenue DESC;

-- piata
WITH ranked_transactions AS (
    SELECT 
        customer_id,
        product_name,
        sale_date,
        total_amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY sale_date DESC) AS row_num
    FROM flourmills_sales
)
SELECT 
    customer_id,
    product_name,
    sale_date,
    total_amount
FROM ranked_transactions
WHERE row_num = 1
ORDER BY customer_id ASC;

--sestka
WITH date_bounds AS (
    SELECT 
        MIN(sale_date)::DATE AS min_date,
        MAX(sale_date)::DATE AS max_date
    FROM flourmills_sales
),
recursive_calendar AS (
    SELECT min_date AS calendar_date, max_date
    FROM date_bounds
    
    UNION ALL
    
    SELECT (calendar_date + INTERVAL '1 day')::DATE, max_date
    FROM recursive_calendar
    WHERE calendar_date < max_date
)
SELECT calendar_date
FROM recursive_calendar
ORDER BY calendar_date ASC;