USE olist_data;
GO

-- 1. Create Gold Schema
IF SCHEMA_ID(N'gold') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA [gold];');
END
GO

--------------------------------------------------------------------
-- DIMENSION VIEWS
--------------------------------------------------------------------

-- Dim Customers View
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    g.latitude,
    g.longitude
FROM silver.customers c
LEFT JOIN silver.geolocation g 
    ON c.customer_zip_code_prefix = g.zip_code_prefix;
GO

-- Dim Sellers View
CREATE OR ALTER VIEW gold.dim_sellers AS
SELECT 
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    g.latitude,
    g.longitude
FROM silver.sellers s
LEFT JOIN silver.geolocation g 
    ON s.seller_zip_code_prefix = g.zip_code_prefix;
GO

-- Dim Products View
CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM silver.products;
GO

--------------------------------------------------------------------
-- FACT VIEWS
--------------------------------------------------------------------

-- Fact Sales Orders View
CREATE OR ALTER VIEW gold.fact_sales_orders AS
SELECT 
    i.order_id,
    i.order_item_id,
    o.customer_id,
    i.product_id,
    i.seller_id,
    o.order_status,
    CAST(FORMAT(o.order_purchase_timestamp, 'yyyyMMdd') AS INT) AS purchase_date_key,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    i.shipping_limit_date,
    i.price,
    i.freight_value,
    (i.price + i.freight_value) AS total_order_item_cost,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS actual_delivery_days,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date) AS estimated_delivery_days
FROM silver.order_items i
INNER JOIN silver.orders o ON i.order_id = o.order_id;
GO

-- Fact Order Payments View
CREATE OR ALTER VIEW gold.fact_order_payments AS
SELECT 
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM silver.order_payments p;
GO

-- Fact Order Reviews View
CREATE OR ALTER VIEW gold.fact_order_reviews AS
SELECT 
    r.review_id,
    r.order_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp
FROM silver.order_reviews r;
GO