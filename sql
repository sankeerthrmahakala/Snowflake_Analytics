--Create PORTFOLIO_DB database and ANALYTICS schema
CREATE DATABASE PORTFOLIO_DB;
CREATE SCHEMA ANALYTICS;

USE DATABASE PORTFOLIO_DB;
USE SCHEMA ANALYTICS;


--Create stage table to upload SampleSuperstore.csv
CREATE OR REPLACE STAGE my_internal_stage;



------------------------------------------------------------------------------------------------

-- 1) Create Tables
--Customers Table
CREATE OR REPLACE TABLE customers (
    customer_id VARCHAR PRIMARY KEY,
    customer_name VARCHAR,
    segment VARCHAR
);

--Products Table
CREATE OR REPLACE TABLE products (
    product_id VARCHAR PRIMARY KEY,
    product_name VARCHAR,
    sub_category VARCHAR,
    category VARCHAR
);

--Regions Table
CREATE OR REPLACE TABLE regions (
    region VARCHAR,
    country VARCHAR,
    state VARCHAR,
    city VARCHAR,
    postal_code VARCHAR,
    PRIMARY KEY (region, country, state, city, postal_code)
);

--Orders Table
CREATE OR REPLACE TABLE orders (
    order_id VARCHAR PRIMARY KEY,
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR,
    customer_id VARCHAR,
    region VARCHAR,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

--Order_Details Table
CREATE OR REPLACE TABLE order_details (
    order_id VARCHAR,
    product_id VARCHAR,
    sales FLOAT,
    quantity INT,
    discount FLOAT,
    profit FLOAT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),    
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);





------------------------------------------------------------------------------------------------

-- 2) Create Raw Superstore Table
create or replace TABLE PORTFOLIO_DB.Analytics.raw_superstore (
	order_id VARCHAR,
	order_date DATE,
	ship_date DATE,
	ship_mode VARCHAR,
	customer_id VARCHAR,
	customer_name VARCHAR,
	segment VARCHAR,
	country VARCHAR,
	city VARCHAR,
	state VARCHAR,
	postal_code VARCHAR,
    	region VARCHAR,
	product_id VARCHAR,
	category VARCHAR,
	sub_category VARCHAR,
	product_name VARCHAR,
	sales NUMBER,
	quantity NUMBER,
	discount NUMBER,
	profit NUMBER
);


-----------------------------------------------------------------------------------------------
--Load SampleSuperstore.csv into raw table 
COPY INTO raw_superstore
FROM @my_internal_stage/SampleSuperstore.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = CONTINUE;



------------------------------------------------------------------------------------------------

-- 3) Insert normalized data
--Insert into Customers
INSERT INTO customers
SELECT DISTINCT customer_id, customer_name, segment 
from raw_superstore;

--Insert into Products
INSERT INTO products
SELECT DISTINCT product_id, product_name, sub_category, category 
from raw_superstore;

--Insert into Regions
INSERT INTO regions
SELECT DISTINCT region, country, state, city, postal_code
from raw_superstore;

--Insert into Orders
INSERT INTO orders
SELECT DISTINCT order_id, order_date, ship_date, ship_mode, customer_id, region
from raw_superstore;

--Insert into Order_Details
INSERT INTO order_details
SELECT DISTINCT order_id, product_id,  sales, profit, discount, quantity
from raw_superstore;





------------------------------------------------------------------------------------------------

--Business_driven_queries
--Monthly Sales to Profit Ratio
SELECT 
TO_CHAR(order_date, 'YYYY-MM') AS month,
ROUND(SUM(sales), 2) AS total_sales,
ROUND(SUM(profit), 2) AS total_profit,
ROUND(SUM(profit)/SUM(sales),2) As Profit_to_Sales_ratio
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY 1
ORDER BY 1;

--Top 5 Products by Profit
SELECT 
p.product_name,
ROUND(SUM(od.profit), 2) AS total_profit
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC
LIMIT 5;

--Top 10 Customers by Lifetime Value
SELECT 
c.customer_id,
c.customer_name,
ROUND(SUM(od.sales), 2) AS lifetime_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_sales DESC
LIMIT 10;

--Regional Sales performance
SELECT 
r.region,
ROUND(SUM(od.sales), 2) AS total_sales,
ROUND(SUM(od.profit), 2) AS total_profit
FROM regions r
JOIN orders o ON r.region = o.region
JOIN orderdetails od ON o.order_id = od.order_id
GROUP BY r.region
ORDER BY total_sales DESC;


--Impact of discount on Profit
SELECT 
p.product_name,
ROUND(od.discount, 2) AS discount_rate,
ROUND(AVG(od.profit), 2) AS avg_profit
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.product_name, discount_rate
ORDER BY avg_profit DESC
LIMIT 5;


--Orders with Top losses
SELECT 
o.order_id,
ROUND(SUM(od.sales), 2) AS total_sales,
ROUND(SUM(od.profit), 2) AS total_profit
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_id
ORDER BY total_profit ASC
LIMIT 5;

--Ship mode usage share
SELECT 
ship_mode,
COUNT(DISTINCT order_id) AS orders,
ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER (), 2) AS percent_share
FROM orders
GROUP BY ship_mode;

--Avg delivery delay (in days)
SELECT 
ROUND(AVG(DATEDIFF(DAY, order_date, ship_date)), 2) AS avg_delivery_delay
FROM orders;
