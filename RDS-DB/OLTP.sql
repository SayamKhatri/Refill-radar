-- DDL COMMANDS
CREATE DATABASE HASP;
USE HASP;

-- 1. Products Table
CREATE TABLE products (
    product_id         INT AUTO_INCREMENT PRIMARY KEY,
    sku_number         VARCHAR(30) UNIQUE NOT NULL,
    name               VARCHAR(100) NOT NULL,
    brand              VARCHAR(50),
    category           VARCHAR(50),
    regular_price      DECIMAL(10, 2) NOT NULL
);

-- 2. Inventory Table (for CDC)
CREATE TABLE inventory (
    product_id         INT PRIMARY KEY,
    quantity_available INT NOT NULL,
    last_updated       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 3. Stores Table
CREATE TABLE stores (
    store_id           INT AUTO_INCREMENT PRIMARY KEY,
    store_number       VARCHAR(20) UNIQUE NOT NULL,
    store_name         VARCHAR(100),
    district           VARCHAR(50),
    region             VARCHAR(50)
);

-- 4. Cashiers Table
CREATE TABLE cashiers (
    cashier_id         INT AUTO_INCREMENT PRIMARY KEY,
    employee_number    VARCHAR(20) UNIQUE NOT NULL,
    name               VARCHAR(100)
);

-- Create promotions without AUTO_INCREMENT
CREATE TABLE promotions (
    promotion_id       INT PRIMARY KEY,
    promotion_code     VARCHAR(20) UNIQUE NOT NULL,
    name               VARCHAR(100),
    media_type         VARCHAR(50),
    begin_date         DATE,
    end_date           DATE
);

-- 6. Payment Methods Table
CREATE TABLE payment_methods (
    payment_method_id      INT AUTO_INCREMENT PRIMARY KEY,
    payment_description    VARCHAR(50),
    payment_group          VARCHAR(50)
);

-- 7. Sales Transactions Table
CREATE TABLE sales_transactions (
    transaction_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_id          INT,
    cashier_id          INT,
    store_id            INT,
    promotion_id        INT,
    payment_method_id   INT,
    quantity_sold       INT NOT NULL,
    discount_per_unit   DECIMAL(10,2) DEFAULT 0,
    sale_datetime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (cashier_id) REFERENCES cashiers(cashier_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (promotion_id) REFERENCES promotions(promotion_id),
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id)
);
