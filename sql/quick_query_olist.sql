SELECT 
    c.customer_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.price), 2) AS total_revenue,
    ROUND(AVG(f.freight_value), 2) AS avg_freight_cost,
    ROUND(AVG(f.actual_delivery_days), 1) AS avg_delivery_days
FROM gold.fact_sales_orders f
JOIN gold.dim_customers c ON f.customer_id = c.customer_id
WHERE f.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


SELECT TOP 15
    p.product_category_name,
    COUNT(DISTINCT f.order_id) AS items_sold,
    ROUND(SUM(f.price), 2) AS category_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM gold.fact_sales_orders f
JOIN gold.dim_products p ON f.product_id = p.product_id
LEFT JOIN gold.fact_order_reviews r ON f.order_id = r.order_id
GROUP BY p.product_category_name
ORDER BY category_revenue DESC;


SELECT 
    c.customer_state,
    COUNT(f.order_id) AS total_delayed_orders,
    AVG(DATEDIFF(DAY, f.order_estimated_delivery_date, f.order_delivered_customer_date)) AS avg_days_overdue
FROM gold.fact_sales_orders f
JOIN gold.dim_customers c ON f.customer_id = c.customer_id
WHERE f.order_delivered_customer_date > f.order_estimated_delivery_date
GROUP BY c.customer_state
ORDER BY total_delayed_orders DESC;