/*
Supply Chain Analytics - Analytical Views
PostgreSQL 16+

Seven optimized views for Power BI dashboard integration.
*/

-- Monthly KPI aggregations
DROP VIEW IF EXISTS v_executive_kpis CASCADE;

CREATE VIEW v_executive_kpis AS
SELECT 
    TO_CHAR(TO_DATE(o.order_date, 'MM/DD/YYYY'), 'YYYY-MM') as year_month,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    SUM(o.order_quantity) as total_units_sold,
    ROUND(SUM(o.sales)::numeric, 2) as total_revenue,
    ROUND(SUM(o.profit_per_order)::numeric, 2) as total_profit,
    ROUND(AVG(o.sales)::numeric, 2) as avg_order_value,
    ROUND((SUM(o.profit_per_order) * 100.0 / NULLIF(SUM(o.sales), 0))::numeric, 2) as profit_margin_pct,
    SUM(CASE WHEN sd.late_delivery_risk = 1 THEN 1 ELSE 0 END) as late_deliveries,
    ROUND((SUM(CASE WHEN sd.late_delivery_risk = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::numeric, 2) as on_time_pct
FROM orders o
LEFT JOIN shipping_details sd ON o.order_id = sd.order_id
WHERE o.order_date IS NOT NULL AND o.order_date != ''
GROUP BY year_month
ORDER BY year_month;

-- Delivery performance with delay analysis
DROP VIEW IF EXISTS v_delivery_performance CASCADE;

CREATE VIEW v_delivery_performance AS
SELECT 
    o.order_id,
    o.order_date,
    o.market,
    o.order_region,
    o.order_country,
    sd.shipping_mode,
    sd.delivery_status,
    sd.days_for_shipping_real,
    sd.days_for_shipment_scheduled,
    sd.days_for_shipping_real - sd.days_for_shipment_scheduled as delay_days,
    sd.late_delivery_risk,
    CASE WHEN sd.late_delivery_risk = 1 THEN 'Late' ELSE 'On Time' END as delivery_category,
    o.sales as order_value
FROM orders o
JOIN shipping_details sd ON o.order_id = sd.order_id;

-- Product sales analysis
DROP VIEW IF EXISTS v_product_sales CASCADE;

CREATE VIEW v_product_sales AS
SELECT 
    p.product_id,
    p.product_name,
    p.category_name,
    p.department_name,
    p.product_price,
    COUNT(o.order_id) as order_count,
    SUM(o.order_quantity) as total_quantity_sold,
    ROUND(SUM(o.sales)::numeric, 2) as total_revenue,
    ROUND(SUM(o.profit_per_order)::numeric, 2) as total_profit,
    ROUND(AVG(o.sales)::numeric, 2) as avg_sale_value,
    ROUND((SUM(o.profit_per_order) * 100.0 / NULLIF(SUM(o.sales), 0))::numeric, 2) as profit_margin_pct
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name, p.category_name, p.department_name, p.product_price;

-- Customer metrics and segmentation
DROP VIEW IF EXISTS v_customer_analysis CASCADE;

CREATE VIEW v_customer_analysis AS
SELECT 
    c.customer_id,
    c.customer_fname || ' ' || c.customer_lname as customer_name,
    c.customer_segment,
    c.customer_city,
    c.customer_state,
    c.customer_country,
    COUNT(o.order_id) as total_orders,
    SUM(o.order_quantity) as total_items,
    ROUND(SUM(o.sales)::numeric, 2) as total_spent,
    ROUND(AVG(o.sales)::numeric, 2) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    SUM(CASE WHEN sd.late_delivery_risk = 1 THEN 1 ELSE 0 END) as late_deliveries
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN shipping_details sd ON o.order_id = sd.order_id
GROUP BY c.customer_id, customer_name, c.customer_segment, 
         c.customer_city, c.customer_state, c.customer_country;

-- Geographic sales breakdown
DROP VIEW IF EXISTS v_geographic_sales CASCADE;

CREATE VIEW v_geographic_sales AS
SELECT 
    o.market,
    o.order_region,
    o.order_country,
    o.order_state,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    ROUND(SUM(o.sales)::numeric, 2) as total_revenue,
    ROUND(SUM(o.profit_per_order)::numeric, 2) as total_profit,
    ROUND((SUM(CASE WHEN sd.late_delivery_risk = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::numeric, 2) as on_time_pct
FROM orders o
JOIN shipping_details sd ON o.order_id = sd.order_id
GROUP BY o.market, o.order_region, o.order_country, o.order_state;

-- Category performance over time
DROP VIEW IF EXISTS v_category_performance CASCADE;

CREATE VIEW v_category_performance AS
SELECT 
    TO_CHAR(TO_DATE(o.order_date, 'MM/DD/YYYY'), 'YYYY-MM') as year_month,
    p.department_name,
    p.category_name,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.order_quantity) as units_sold,
    ROUND(SUM(o.sales)::numeric, 2) as total_revenue,
    ROUND(SUM(o.profit_per_order)::numeric, 2) as total_profit,
    ROUND((SUM(o.profit_per_order) * 100.0 / NULLIF(SUM(o.sales), 0))::numeric, 2) as profit_margin_pct
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_date IS NOT NULL AND o.order_date != ''
GROUP BY year_month, p.department_name, p.category_name
ORDER BY year_month;

-- Complete order details (fact table with all dimensions)
DROP VIEW IF EXISTS v_order_details CASCADE;

CREATE VIEW v_order_details AS
SELECT 
    o.order_id,
    o.order_date,
    TO_CHAR(TO_DATE(o.order_date, 'MM/DD/YYYY'), 'YYYY-MM') as year_month,
    c.customer_id,
    c.customer_fname || ' ' || c.customer_lname as customer_name,
    c.customer_segment,
    c.customer_city as customer_city,
    p.product_id,
    p.product_name,
    p.category_name,
    p.department_name,
    o.order_quantity,
    o.sales,
    o.discount,
    o.profit_per_order,
    o.market,
    o.order_region,
    o.order_country,
    sd.shipping_mode,
    sd.delivery_status,
    sd.days_for_shipping_real,
    sd.late_delivery_risk,
    CASE WHEN sd.late_delivery_risk = 1 THEN 'Late' ELSE 'On Time' END as delivery_category
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
LEFT JOIN shipping_details sd ON o.order_id = sd.order_id;

GRANT SELECT ON v_executive_kpis TO PUBLIC;
GRANT SELECT ON v_delivery_performance TO PUBLIC;
GRANT SELECT ON v_product_sales TO PUBLIC;
GRANT SELECT ON v_customer_analysis TO PUBLIC;
GRANT SELECT ON v_geographic_sales TO PUBLIC;
GRANT SELECT ON v_category_performance TO PUBLIC;
GRANT SELECT ON v_order_details TO PUBLIC;

SELECT 'All 7 analytical views created successfully' AS status;
