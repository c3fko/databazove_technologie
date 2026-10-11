-- Active: 1790526834652@@127.0.0.1@5432@retail_sales
CREATE VIEW high_value_customers AS
SELECT 
    c.customer_id,
    c.customer_name,
    SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.sales) > 2000;

SELECT COUNT(*)
FROM high_value_customers;

-- druha
CREATE VIEW regional_monthly_sales AS
SELECT 
    c.region,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(o.sales) AS monthly_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region, DATE_TRUNC('month', o.order_date);

SELECT *
FROM regional_monthly_sales
WHERE region = 'West'
ORDER BY month;

-- tretia
CREATE VIEW analyst_orders AS
SELECT 
    order_id,
    customer_id,
    product_id,
    sales,
    quantity,
    discount
FROM orders;

SELECT *
FROM analyst_orders;

-- stvorka
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

SELECT *
FROM orders
WHERE customer_id = 'C001';

-- piata 
CREATE INDEX idx_orders_order_date ON orders(order_date);

SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(sales) AS total_sales
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month ASC;

-- sestka 
CREATE INDEX idx_orders_region_category ON orders(customer_id, order_date);

SELECT 
    o.order_id,
    c.customer_id,
    c.customer_name,
    o.order_date,
    c.region,
    o.profit
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.region = 'West' 
  AND o.order_date >= '2024-01-01';

-- sedmikca
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 'C001';

-- osmicka
CREATE DATABASE retail_sales;

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    region VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ship_mode VARCHAR(30) NOT NULL,
    sales DECIMAL(10, 2) NOT NULL,
    profit DECIMAL(10, 2) NOT NULL
);
ALTER DATABASE retail_sales SET datestyle TO 'ISO, MDY';

-- deviatka
CREATE OR REPLACE PROCEDURE get_customer_sales(p_customer_id VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_sales NUMERIC;
BEGIN
    SELECT SUM(sales) INTO v_total_sales
    FROM orders
    WHERE customer_id = p_customer_id;

    RAISE NOTICE 'Zákazník ID: %, Celkový predaj: %', p_customer_id, v_total_sales;
END;
$$;
CALL get_customer_sales('C001');