-- DDL

-- dim_product
CREATE TABLE hasp_dw.dim_product (
  product_key INT IDENTITY(1,1),
  product_id INT,
  sku_number VARCHAR(30),
  name VARCHAR(100),
  brand VARCHAR(50),
  category VARCHAR(50),
  regular_price DECIMAL(10,2),
  PRIMARY KEY (product_key)
)
DISTKEY(product_id)
SORTKEY(product_id);

-- dim_store
CREATE TABLE hasp_dw.dim_store (
  store_key INT IDENTITY(1,1),
  store_id INT,
  store_number VARCHAR(20),
  store_name VARCHAR(100),
  district VARCHAR(50),
  region VARCHAR(50),
  PRIMARY KEY (store_key)
)
DISTKEY(store_id)
SORTKEY(store_id);

-- dim_cashier
CREATE TABLE hasp_dw.dim_cashier (
  cashier_key INT IDENTITY(1,1),
  cashier_id INT,
  employee_number VARCHAR(20),
  name VARCHAR(100),
  PRIMARY KEY (cashier_key)
)
DISTKEY(cashier_id)
SORTKEY(cashier_id);

-- dim_promotion
CREATE TABLE hasp_dw.dim_promotion (
  promotion_key INT IDENTITY(1,1),
  promotion_id INT,
  promotion_code VARCHAR(20),
  name VARCHAR(100),
  media_type VARCHAR(50),
  begin_date DATE,
  end_date DATE,
  PRIMARY KEY (promotion_key)
)
DISTKEY(promotion_id)
SORTKEY(promotion_id);

-- dim_payment_method
CREATE TABLE dim_payment_method (
  payment_key INT IDENTITY(1,1),
  payment_method_id INT,
  payment_description VARCHAR(50),
  payment_group VARCHAR(50),
  PRIMARY KEY (payment_key)
)
DISTKEY(payment_method_id)
SORTKEY(payment_method_id);

-- fact_sales
CREATE TABLE hasp_dw.fact_sales (
  sales_key INT IDENTITY(1,1),
  transaction_id INT,
  product_id INT,
  cashier_id INT,
  store_id INT,
  promotion_id INT,
  payment_method_id INT,
  quantity_sold INT,
  discount_per_unit DECIMAL(10,2),
  sale_datetime TIMESTAMP,
  PRIMARY KEY (sales_key)
)
DISTKEY(product_id)
SORTKEY(sale_datetime);


-- fact_inventory

CREATE TABLE hasp_dw.fact_inventory (
  inventory_key INT IDENTITY(1,1),
  product_id INT,
  quantity_available INT,
  last_updated TIMESTAMP,
  PRIMARY KEY (inventory_key)
)
DISTKEY(product_id)
SORTKEY(last_updated);
