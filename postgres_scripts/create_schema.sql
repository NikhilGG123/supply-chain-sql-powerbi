-- Supply Chain Analytics Database Schema
-- PostgreSQL 16.x

DROP TABLE IF EXISTS shipping_details CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- Customer master data
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_fname TEXT NOT NULL,
    customer_lname TEXT NOT NULL,
    customer_email TEXT UNIQUE NOT NULL,
    customer_segment TEXT,
    customer_city TEXT,
    customer_state TEXT,
    customer_country TEXT,
    customer_zipcode TEXT,
    customer_street TEXT,
    latitude REAL,
    longitude REAL
);

CREATE INDEX idx_customers_email ON customers(customer_email);

-- Product catalog
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    product_card_id INTEGER,
    category_name TEXT,
    department_name TEXT,
    product_price REAL,
    product_description TEXT,
    product_image TEXT,
    product_status INTEGER
);

CREATE INDEX idx_products_name ON products(product_name);

-- Order transactions
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_item_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    order_date_dateorders TEXT,
    order_quantity INTEGER,
    sales REAL,
    discount REAL,
    profit_per_order REAL,
    order_status TEXT,
    market TEXT,
    order_region TEXT,
    order_country TEXT,
    order_city TEXT,
    order_state TEXT,
    order_zipcode TEXT,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_product ON orders(product_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_region ON orders(order_region);

-- Shipping and delivery tracking
CREATE TABLE shipping_details (
    shipping_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    shipping_date TEXT,
    shipping_mode TEXT,
    days_for_shipping_real INTEGER,
    days_for_shipment_scheduled INTEGER,
    delivery_status TEXT,
    late_delivery_risk INTEGER,
    CONSTRAINT fk_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE INDEX idx_shipping_order ON shipping_details(order_id);
CREATE INDEX idx_shipping_mode ON shipping_details(shipping_mode);
CREATE INDEX idx_shipping_status ON shipping_details(delivery_status);

SELECT 'Schema created successfully' AS status;