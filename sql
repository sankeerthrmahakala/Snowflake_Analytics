--Create PORTFOLIO_DB database and ANALYTICS schema
CREATE DATABASE PORTFOLIO_DB;
CREATE SCHEMA ANALYTICS;

USE DATABASE PORTFOLIO_DB;
USE SCHEMA ANALYTICS;

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
