-- Active: 1790526834652@@127.0.0.1@5432@retail
-- uloha 2
SELECT 
    customer_id,
    invoice_no,
    invoice_date,
    quantity,
    unit_price,
    quantity * unit_price AS revenue,
    SUM(quantity * unit_price) OVER (
        PARTITION BY customer_id
        ORDER BY invoice_date
        RANGE BETWEEN INTERVAL '14 days' PRECEDING AND CURRENT ROW
    ) AS revenue_last_14_days
FROM retail_sales
WHERE customer_id IS NOT NULL
ORDER BY customer_id, invoice_date;
-- uloha 3
SELECT 
    stock_code,
    country,
    invoice_date,
    quantity,
    ROUND(
        AVG(quantity) OVER (
            PARTITION BY stock_code, country
            ORDER BY invoice_date
            RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
        ), 2
    ) AS avg_quantity_7_days
FROM retail_sales
WHERE quantity > 1
ORDER BY stock_code, country, invoice_date;
-- uloha 4
WITH unique_orders AS (
    SELECT DISTINCT
        customer_id,
        invoice_no,
        invoice_date::date AS invoice_date
    FROM retail_sales
),
orders_with_next AS (
    SELECT
        customer_id,
        invoice_no,
        invoice_date,
        LEAD(invoice_date) OVER (
            PARTITION BY customer_id
            ORDER BY invoice_date, invoice_no
        ) AS next_invoice_date
    FROM unique_orders
)
SELECT
    customer_id,
    invoice_no,
    invoice_date,
    next_invoice_date,
    next_invoice_date - invoice_date AS days_to_next_invoice
FROM orders_with_next
WHERE next_invoice_date IS NOT NULL
ORDER BY days_to_next_invoice DESC;
-- uloha 5
WITH priced_sales AS (
    SELECT 
        stock_code,
        invoice_no,
        invoice_date,
        unit_price AS current_price,
        LAG(unit_price) OVER (
            PARTITION BY stock_code 
            ORDER BY invoice_date ASC, invoice_no ASC
        ) AS previous_price
    FROM retail_sales
),
calculated_diff AS (
    SELECT 
        stock_code,
        invoice_no,
        invoice_date,
        previous_price,
        current_price,
        (current_price - previous_price) AS price_difference
    FROM priced_sales
    WHERE previous_price IS NOT NULL
)
SELECT 
    stock_code,
        invoice_no,
        invoice_date,
        previous_price,
        current_price,
        price_difference
FROM calculated_diff
WHERE price_difference <> 0
ORDER BY invoice_date ASC;
-- uloha 6
WITH customer_sales AS (
    SELECT 
        customer_id,
        SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT 
    customer_id,
    total_amount,
    NTILE(4) OVER (ORDER BY total_amount DESC) AS sales_quartile
FROM customer_sales
ORDER BY total_amount DESC;
-- uloha 7
WITH monthly_sales AS (
    SELECT 
        country,
        TO_CHAR(invoice_date, 'YYYY-MM') AS month,
        SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    GROUP BY country, TO_CHAR(invoice_date, 'YYYY-MM')
)
SELECT 
    country,
    month,
    total_amount,
    NTILE(4) OVER (PARTITION BY country ORDER BY total_amount DESC) AS sales_quartile
FROM monthly_sales
ORDER BY country ASC, month ASC;
-- uloha 8
WITH ranked_sales AS (
    SELECT 
        customer_id,
        invoice_no,
        invoice_date,
        stock_code,
        description,
        quantity,
        unit_price,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY invoice_date ASC, invoice_no ASC
        ) AS rn
    FROM retail_sales
    WHERE customer_id IS NOT NULL
)
SELECT 
    customer_id,
    invoice_no,
    invoice_date,
    stock_code,
    description,
    quantity,
    unit_price
FROM ranked_sales
WHERE rn = 1
ORDER BY customer_id ASC;
-- uloha 9
WITH ranked_items AS (
    SELECT 
        invoice_no,
        stock_code,
        description,
        quantity,
        unit_price,
        (quantity * unit_price) AS amount,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_no 
            ORDER BY (quantity * unit_price) DESC
        ) AS row_num
    FROM retail_sales
)
SELECT 
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    amount,
    row_num
FROM ranked_items
WHERE row_num <= 3
ORDER BY invoice_no ASC, row_num ASC;
-- uloha 10
WITH customer_monthly_sales AS (
    SELECT 
        country,
        TO_CHAR(invoice_date, 'YYYY-MM') AS month,
        customer_id,
        SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY country, TO_CHAR(invoice_date, 'YYYY-MM'), customer_id
),
ranked_customers AS (
    SELECT 
        country,
        month,
        customer_id,
        total_amount,
        DENSE_RANK() OVER (
            PARTITION BY country, month 
            ORDER BY total_amount DESC
        ) AS sales_rank
    FROM customer_monthly_sales
)
SELECT 
    country,
    month,
    customer_id,
    total_amount,
    sales_rank
FROM ranked_customers
WHERE sales_rank <= 5
ORDER BY country ASC, month ASC, sales_rank ASC, customer_id ASC;
-- uloha 11
WITH ranked_items AS (
    SELECT 
        invoice_no,
        stock_code,
        description,
        quantity,
        unit_price,
        DENSE_RANK() OVER (
            PARTITION BY invoice_no 
            ORDER BY unit_price DESC
        ) AS price_rank
    FROM retail_sales
)
SELECT 
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    price_rank
FROM ranked_items
WHERE price_rank <= 5
ORDER BY invoice_no ASC, price_rank ASC, stock_code ASC;