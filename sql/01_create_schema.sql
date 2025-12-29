/*
Supply Chain Analytics - Database Schema
PostgreSQL 16+

Normalized schema with 4 tables for supply chain analytics.
Supports order tracking, customer analysis, and delivery performance.
*/

DROP TABLE IF EXISTS shipping_details CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- Customer master data
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_fname TEXT NOT NULL,
    customer_lname TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_segment TEXT,
    customer_city TEXT,
    customer_state TEXT,
    customer_country TEXT,
    customer_zipcode TEXT,
    customer_street TEXT,
    latitude REAL,
    longitude REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_email ON customers(customer_email);
CREATE INDEX idx_customers_segment ON customers(customer_segment);
CREATE INDEX idx_customers_location ON customers(customer_city, customer_state);

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
    product_status INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_product_price CHECK (product_price >= 0),
    CONSTRAINT chk_product_status CHECK (product_status IN (0, 1))
);

CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_products_category ON products(category_name);
CREATE INDEX idx_products_department ON products(department_name);

-- Order transactions (fact table)
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE,
    CONSTRAINT chk_quantity CHECK (order_quantity > 0),
    CONSTRAINT chk_sales CHECK (sales >= 0)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_product ON orders(product_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_region ON orders(order_region);
CREATE INDEX idx_orders_market ON orders(market);

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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT chk_days_real CHECK (days_for_shipping_real >= 0),
    CONSTRAINT chk_days_scheduled CHECK (days_for_shipment_scheduled >= 0),
    CONSTRAINT chk_late_risk CHECK (late_delivery_risk IN (0, 1))
);

CREATE INDEX idx_shipping_order ON shipping_details(order_id);
CREATE INDEX idx_shipping_mode ON shipping_details(shipping_mode);
CREATE INDEX idx_shipping_late ON shipping_details(late_delivery_risk);

ANALYZE customers;
ANALYZE products;
ANALYZE orders;
ANALYZE shipping_details;

SELECT 'Schema created: customers, products, orders, shipping_details' AS status;
