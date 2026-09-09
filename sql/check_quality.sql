USE olist_data;
GO

--------------------------------------------------------------------
-- 1. NULL & MISSING VALUES CHECK
--------------------------------------------------------------------
SELECT 'products' AS Table_Name, 'product_category_name' AS Column_Name, 
       COUNT(*) AS Total_Rows, 
       SUM(CASE WHEN product_category_name IS NULL OR TRIM(product_category_name) = '' THEN 1 ELSE 0 END) AS Missing_Count
FROM bronze.olist_products_dataset

UNION ALL

SELECT 'orders', 'order_approved_at', COUNT(*), 
       SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)
FROM bronze.olist_orders_dataset

UNION ALL

SELECT 'orders', 'order_delivered_customer_date', COUNT(*), 
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)
FROM bronze.olist_orders_dataset

UNION ALL

SELECT 'reviews', 'review_comment_message', COUNT(*), 
       SUM(CASE WHEN review_comment_message IS NULL OR TRIM(review_comment_message) = '' THEN 1 ELSE 0 END)
FROM bronze.olist_order_reviews_dataset;
GO

--------------------------------------------------------------------
-- 2. DUPLICATE PRIMARY KEYS CHECK
--------------------------------------------------------------------
-- Check Duplicate Customers
SELECT customer_id, COUNT(*) AS dup_count 
FROM bronze.customers 
GROUP BY customer_id 
HAVING COUNT(*) > 1;

-- Check Duplicate Orders
SELECT order_id, COUNT(*) AS dup_count 
FROM bronze.olist_orders_dataset 
GROUP BY order_id 
HAVING COUNT(*) > 1;

-- Check Duplicate Products
SELECT product_id, COUNT(*) AS dup_count 
FROM bronze.olist_products_dataset 
GROUP BY product_id 
HAVING COUNT(*) > 1;

-- Check Duplicate Geolocation (Zip Codes are usually duplicated in raw dataset)
SELECT geolocation_zip_code_prefix, COUNT(*) AS dup_count 
FROM bronze.olist_geolocation_dataset 
GROUP BY geolocation_zip_code_prefix 
HAVING COUNT(*) > 1;
GO

--------------------------------------------------------------------
-- 3. INVALID DATE / NUMERIC FORMAT CHECKS (TRY_CAST TEST)
--------------------------------------------------------------------
-- Check for invalid dates in Orders table
SELECT COUNT(*) AS invalid_purchase_dates
FROM bronze.olist_orders_dataset
WHERE TRY_CAST(order_purchase_timestamp AS DATETIME) IS NULL 
  AND order_purchase_timestamp IS NOT NULL;

-- Check for invalid price formats in Order Items table
SELECT COUNT(*) AS invalid_price_formats
FROM bronze.olist_order_items_dataset
WHERE TRY_CAST(price AS FLOAT) IS NULL 
  AND price IS NOT NULL;
GO

--------------------------------------------------------------------
-- 4. BUSINESS LOGIC & DATA ANOMALY CHECKS
--------------------------------------------------------------------
-- Check for negative prices or freight values
SELECT COUNT(*) AS negative_prices 
FROM bronze.olist_order_items_dataset 
WHERE TRY_CAST(price AS FLOAT) < 0 OR TRY_CAST(freight_value AS FLOAT) < 0;

-- Check for invalid order timeline logic (Delivered before Purchase Date)
SELECT COUNT(*) AS illogical_delivery_dates
FROM bronze.olist_orders_dataset
WHERE TRY_CAST(order_delivered_customer_date AS DATETIME) < TRY_CAST(order_purchase_timestamp AS DATETIME);
GO