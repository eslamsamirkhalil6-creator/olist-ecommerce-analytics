USE olist_data;
GO

-- 1. Create Silver Schema
IF SCHEMA_ID(N'silver') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA [silver];');
END
GO

-- 2. Silver Customers
IF OBJECT_ID(N'silver.customers', 'U') IS NOT NULL DROP TABLE silver.customers;
SELECT 
    TRIM(customer_id) AS customer_id,
    TRIM(customer_unique_id) AS customer_unique_id,
    TRY_CAST(customer_zip_code_prefix AS INT) AS customer_zip_code_prefix,
    TRIM(customer_city) AS customer_city,
    TRIM(customer_state) AS customer_state
INTO silver.customers
FROM bronze.customers;

ALTER TABLE silver.customers ALTER COLUMN customer_id VARCHAR(50) NOT NULL;
ALTER TABLE silver.customers ADD CONSTRAINT PK_silver_customers PRIMARY KEY (customer_id);
GO

-- 3. Silver Sellers
IF OBJECT_ID(N'silver.sellers', 'U') IS NOT NULL DROP TABLE silver.sellers;
SELECT 
    TRIM(seller_id) AS seller_id,
    TRY_CAST(seller_zip_code_prefix AS INT) AS seller_zip_code_prefix,
    TRIM(seller_city) AS seller_city,
    TRIM(seller_state) AS seller_state
INTO silver.sellers
FROM bronze.olist_sellers_dataset;

ALTER TABLE silver.sellers ALTER COLUMN seller_id VARCHAR(50) NOT NULL;
ALTER TABLE silver.sellers ADD CONSTRAINT PK_silver_sellers PRIMARY KEY (seller_id);
GO

-- 4. Silver Products (Translating Categories & Preserving Raw Values)
IF OBJECT_ID(N'silver.products', 'U') IS NOT NULL DROP TABLE silver.products;
SELECT 
    TRIM(p.product_id) AS product_id,
    COALESCE(TRIM(t.product_category_name_english), TRIM(p.product_category_name), 'Unknown') AS product_category_name,
    TRY_CAST(p.product_name_lenght AS INT) AS product_name_length,
    TRY_CAST(p.product_description_lenght AS INT) AS product_description_length,
    TRY_CAST(p.product_photos_qty AS INT) AS product_photos_qty,
    TRY_CAST(p.product_weight_g AS FLOAT) AS product_weight_g,
    TRY_CAST(p.product_length_cm AS FLOAT) AS product_length_cm,
    TRY_CAST(p.product_height_cm AS FLOAT) AS product_height_cm,
    TRY_CAST(p.product_width_cm AS FLOAT) AS product_width_cm
INTO silver.products
FROM bronze.olist_products_dataset p
LEFT JOIN bronze.product_category_name_translation t
    ON TRIM(p.product_category_name) = TRIM(t.product_category_name);

ALTER TABLE silver.products ALTER COLUMN product_id VARCHAR(50) NOT NULL;
ALTER TABLE silver.products ADD CONSTRAINT PK_silver_products PRIMARY KEY (product_id);
GO

-- 5. Silver Orders
IF OBJECT_ID(N'silver.orders', 'U') IS NOT NULL DROP TABLE silver.orders;
SELECT 
    TRIM(order_id) AS order_id,
    TRIM(customer_id) AS customer_id,
    TRIM(order_status) AS order_status,
    TRY_CAST(order_purchase_timestamp AS DATETIME) AS order_purchase_timestamp,
    TRY_CAST(order_approved_at AS DATETIME) AS order_approved_at,
    TRY_CAST(order_delivered_carrier_date AS DATETIME) AS order_delivered_carrier_date,
    TRY_CAST(order_delivered_customer_date AS DATETIME) AS order_delivered_customer_date,
    TRY_CAST(order_estimated_delivery_date AS DATETIME) AS order_estimated_delivery_date
INTO silver.orders
FROM bronze.olist_orders_dataset;

ALTER TABLE silver.orders ALTER COLUMN order_id VARCHAR(50) NOT NULL;
ALTER TABLE silver.orders ADD CONSTRAINT PK_silver_orders PRIMARY KEY (order_id);
GO

-- 6. Silver Order Items
IF OBJECT_ID(N'silver.order_items', 'U') IS NOT NULL DROP TABLE silver.order_items;
SELECT 
    TRIM(order_id) AS order_id,
    TRY_CAST(order_item_id AS INT) AS order_item_id,
    TRIM(product_id) AS product_id,
    TRIM(seller_id) AS seller_id,
    TRY_CAST(shipping_limit_date AS DATETIME) AS shipping_limit_date,
    TRY_CAST(price AS FLOAT) AS price,
    TRY_CAST(freight_value AS FLOAT) AS freight_value
INTO silver.order_items
FROM bronze.olist_order_items_dataset;

ALTER TABLE silver.order_items ALTER COLUMN order_id VARCHAR(50) NOT NULL;
ALTER TABLE silver.order_items ALTER COLUMN order_item_id INT NOT NULL;
ALTER TABLE silver.order_items ADD CONSTRAINT PK_silver_order_items PRIMARY KEY (order_id, order_item_id);
GO

-- 7. Silver Order Payments
IF OBJECT_ID(N'silver.order_payments', 'U') IS NOT NULL DROP TABLE silver.order_payments;
SELECT 
    TRIM(order_id) AS order_id,
    TRY_CAST(payment_sequential AS INT) AS payment_sequential,
    TRIM(payment_type) AS payment_type,
    TRY_CAST(payment_installments AS INT) AS payment_installments,
    TRY_CAST(payment_value AS FLOAT) AS payment_value
INTO silver.order_payments
FROM bronze.olist_order_payments_dataset;
GO

-- 8. Silver Order Reviews
IF OBJECT_ID(N'silver.order_reviews', 'U') IS NOT NULL DROP TABLE silver.order_reviews;
SELECT 
    TRIM(review_id) AS review_id,
    TRIM(order_id) AS order_id,
    TRY_CAST(review_score AS INT) AS review_score,
    TRIM(review_comment_title) AS review_comment_title,
    TRIM(review_comment_message) AS review_comment_message,
    TRY_CAST(review_creation_date AS DATETIME) AS review_creation_date,
    TRY_CAST(review_answer_timestamp AS DATETIME) AS review_answer_timestamp
INTO silver.order_reviews
FROM bronze.olist_order_reviews_dataset;
GO

-- 9. Silver Geolocation (Deduplicated to single unique ZIP logic)
IF OBJECT_ID(N'silver.geolocation', 'U') IS NOT NULL DROP TABLE silver.geolocation;
WITH RankedGeo AS (
    SELECT 
        TRY_CAST(geolocation_zip_code_prefix AS INT) AS zip_code_prefix,
        TRY_CAST(geolocation_lat AS FLOAT) AS latitude,
        TRY_CAST(geolocation_lng AS FLOAT) AS longitude,
        TRIM(geolocation_city) AS city,
        TRIM(geolocation_state) AS state,
        ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix ORDER BY geolocation_city) AS rn
    FROM bronze.olist_geolocation_dataset
)
SELECT zip_code_prefix, latitude, longitude, city, state
INTO silver.geolocation
FROM RankedGeo
WHERE rn = 1;

ALTER TABLE silver.geolocation ALTER COLUMN zip_code_prefix INT NOT NULL;
ALTER TABLE silver.geolocation ADD CONSTRAINT PK_silver_geolocation PRIMARY KEY (zip_code_prefix);
GO