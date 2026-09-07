USE olist_data;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_items_orders')
    ALTER TABLE bronze.olist_order_items_dataset DROP CONSTRAINT FK_items_orders;

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_items_sellers')
    ALTER TABLE bronze.olist_order_items_dataset DROP CONSTRAINT FK_items_sellers;

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_items_products')
    ALTER TABLE bronze.olist_order_items_dataset DROP CONSTRAINT FK_items_products;

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_payments_orders')
    ALTER TABLE bronze.olist_order_payments_dataset DROP CONSTRAINT FK_payments_orders;


IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'PK_items')
    ALTER TABLE bronze.olist_order_items_dataset DROP CONSTRAINT PK_items;

IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'PK_payments')
    ALTER TABLE bronze.olist_order_payments_dataset DROP CONSTRAINT PK_payments;
GO

ALTER TABLE bronze.olist_order_items_dataset ALTER COLUMN order_id NVARCHAR(255) NOT NULL;
ALTER TABLE bronze.olist_order_items_dataset ALTER COLUMN order_item_id BIGINT NOT NULL;
ALTER TABLE bronze.olist_order_items_dataset ALTER COLUMN seller_id NVARCHAR(255) NOT NULL;
ALTER TABLE bronze.olist_order_items_dataset ALTER COLUMN product_id NVARCHAR(255) NOT NULL;

ALTER TABLE bronze.olist_order_payments_dataset ALTER COLUMN order_id NVARCHAR(255) NOT NULL;
ALTER TABLE bronze.olist_order_payments_dataset ALTER COLUMN payment_sequential BIGINT NOT NULL;
GO


ALTER TABLE bronze.olist_order_items_dataset 
    ADD CONSTRAINT PK_items PRIMARY KEY CLUSTERED (order_id, order_item_id);

ALTER TABLE bronze.olist_order_items_dataset 
    ADD CONSTRAINT FK_items_orders FOREIGN KEY (order_id) REFERENCES bronze.olist_orders_dataset(order_id);

ALTER TABLE bronze.olist_order_items_dataset 
    ADD CONSTRAINT FK_items_sellers FOREIGN KEY (seller_id) REFERENCES bronze.olist_sellers_dataset(seller_id);

ALTER TABLE bronze.olist_order_items_dataset 
    ADD CONSTRAINT FK_items_products FOREIGN KEY (product_id) REFERENCES bronze.olist_products_dataset(product_id);

ALTER TABLE bronze.olist_order_payments_dataset 
    ADD CONSTRAINT PK_payments PRIMARY KEY CLUSTERED (order_id, payment_sequential);

ALTER TABLE bronze.olist_order_payments_dataset 
    ADD CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES bronze.olist_orders_dataset(order_id);
GO

PRINT 'done';
GO





SELECT name, type_desc 
FROM sys.objects 
WHERE name IN ('PK_items', 'PK_payments', 'FK_items_orders', 'FK_items_sellers', 'FK_items_products', 'FK_payments_orders');

