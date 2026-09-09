## 🛠️ Progress Update - [Today's Date]

### 1. Built Data Quality Framework (`01_data_cleaning_and_validation.ipynb`)
Created modular helper functions and a unified Master Function to automate Initial Data Quality Assessments across all raw datasets:
* **`sum_nulls(df)`**: Calculates missing value counts and accurate row-level percentages.
* **`sum_dup(df)`**: Identifies duplicate records and calculates their proportion against total rows.
* **`sum_whitespace(df)`**: Automatically isolates text (`object`/`string`) columns and detects leading/trailing whitespace errors while handling nulls safely.
* **`data_quality_report(df)`**: Master pipeline function wrapping all checks (Shape, Info, Duplicates, Whitespace, Nulls) into a clean, reproducible execution report.

---

### 2. Repository Optimization & Best Practices
* Configured `.gitignore` to prevent tracking raw `.csv` transactional datasets, keeping the repository lightweight and adhering to Git performance standards.
* Maintained directory structure using `.gitkeep` within `data/raw/`.

---

### 3. Applied Data Cleaning & Validation Rules
Implemented deterministic and domain-driven cleaning transformations across the Olist datasets:

* **Handling Missing & Temporal Values**:
  * Preserved `null` values in shipping and delivery timestamps (e.g., `order_delivered_customer_date`, `order_approved_at`) for in-transit or canceled orders, validating business logic rather than dropping records prematurely.
  * Standardized date/time fields to proper datetime data types (`pd.to_datetime`) to ensure accurate lead-time calculations.

* **Text Normalization & Whitespace Cleanup**:
  * Stripped leading and trailing whitespace characters across all text (`string`/`object`) columns while preserving existing `NaN` instances.

* **Deduplication & Referential Integrity**:
  * Retained duplicate entries in high-cardinality reference datasets (such as `geolocation`) to allow proper aggregation by geolocation ZIP codes.
  * Audited foreign key relationships across core entity tables (`orders`, `customers`, `order_items`, `payments`, `products`, `sellers`) to ensure no orphan records exist.

---

### 4. Applied Dataset Inspection Summary

| Dataset | Key Cleaning Actions Applied | Decision Rationale |
| :--- | :--- | :--- |
| **`orders`** | Converted timestamps to datetime; retained nulls for undelivered orders. | Missing delivery dates reflect valid in-transit/canceled status. |
| **`order_items`** | Validated item counts and unit prices; converted shipping limit dates. | Ensured mathematical consistency with order totals. |
| **`order_payments`** | Audited payment sequential numbers and transaction types. | Preserved multi-payment split transactions. |
| **`products`** | Handled missing product dimensions and category names. | Identified unmapped categories for downstream reporting. |
| **`customers` / `sellers`** | Cleaned state codes and ZIP prefix formatting. | Ensured clean spatial joins with geolocation lookup tables. |
| **`geolocation`** | Kept non-unique ZIP code coordinates without forced deduplication. | Multiple lat/long entries represent regional spatial distribution. |

---

### 5. Next Steps
* Finalize staging transformations and clean data layer exports.
* Build third normal form (3NF) relational database schema for downstream analytical workloads.

## 🛠️ Progress Update

### 1. Built Data Quality Framework (`01_data_cleaning_and_validation.ipynb`)
Created modular helper functions and a unified Master Function to automate Initial Data Quality Assessments across all raw datasets:
* **`sum_nulls(df)`**: Calculates missing value counts and accurate row-level percentages.
* **`sum_dup(df)`**: Identifies duplicate records and calculates their proportion against total rows.
* **`sum_whitespace(df)`**: Automatically isolates text (`object`/`string`) columns and detects leading/trailing whitespace errors while handling nulls safely.
* **`data_quality_report(df)`**: Master pipeline function wrapping all checks (Shape, Info, Duplicates, Whitespace, Nulls) into a clean, reproducible execution report.

---

### 2. Repository Optimization & Best Practices
* Configured `.gitignore` to prevent tracking raw `.csv` transactional datasets, keeping the repository lightweight and adhering to Git performance standards.
* Maintained directory structure using `.gitkeep` within `data/raw/`.

---

### 3. Applied Data Cleaning & Validation Rules
Implemented deterministic and domain-driven cleaning transformations across the Olist datasets:

* **Handling Missing & Temporal Values**:
  * Preserved `null` values in shipping and delivery timestamps (e.g., `order_delivered_customer_date`, `order_approved_at`) for in-transit or canceled orders, validating business logic rather than dropping records prematurely.
  * Standardized date/time fields to proper datetime data types (`pd.to_datetime`) to ensure accurate lead-time calculations.

* **Text Normalization & Whitespace Cleanup**:
  * Stripped leading and trailing whitespace characters across all text (`string`/`object`) columns while preserving existing `NaN` instances.

* **Deduplication & Referential Integrity**:
  * Retained duplicate entries in high-cardinality reference datasets (such as `geolocation`) to allow proper aggregation by geolocation ZIP codes.
  * Audited foreign key relationships across core entity tables (`orders`, `customers`, `order_items`, `payments`, `products`, `sellers`) to ensure no orphan records exist.

---

### 4. Applied Dataset Inspection Summary

| Dataset | Key Cleaning Actions Applied | Decision Rationale |
| :--- | :--- | :--- |
| **`orders`** | Converted timestamps to datetime; retained nulls for undelivered orders. | Missing delivery dates reflect valid in-transit/canceled status. |
| **`order_items`** | Validated item counts and unit prices; converted shipping limit dates. | Ensured mathematical consistency with order totals. |
| **`order_payments`** | Audited payment sequential numbers and transaction types. | Preserved multi-payment split transactions. |
| **`products`** | Handled missing product dimensions and category names. | Identified unmapped categories for downstream reporting. |
| **`customers` / `sellers`** | Cleaned state codes and ZIP prefix formatting. | Ensured clean spatial joins with geolocation lookup tables. |
| **`geolocation`** | Kept non-unique ZIP code coordinates without forced deduplication. | Multiple lat/long entries represent regional spatial distribution. |

---

### 5. Database Schema & Medallion Pipeline Construction (SQL Server)
Transformed raw datasets into an enterprise-grade **Medallion Architecture** (Bronze $\rightarrow$ Silver $\rightarrow$ Gold) within SQL Server (`olist_data` database) using T-SQL and Python (`SQLAlchemy` / `pyodbc`):

* **Bronze Layer (Raw Ingestion)**:
  * Programmatically ingested all 9 raw datasets into the `bronze` schema via Python using `fast_executemany=True` for high-performance batch loading.
  * Implemented dynamic Foreign Key drop scripts to allow clean table re-ingestion without constraint conflicts.

* **Pre-Silver Source-Level Quality Validation**:
  * Executed comprehensive T-SQL diagnostic scripts to profile the Bronze layer directly in SQL Server prior to transformation.
  * Confirmed primary key uniqueness on core entity tables (`customers`, `orders`, `products`) and audited missing value rates (e.g., 2,965 undelivered orders, 58,274 blank review messages).
  * Validated data conversion integrity (`TRY_CAST`) and business logic constraints (verifying zero negative prices and logically valid order purchase-to-delivery timelines).

* **Silver Layer (Cleaned Operational Tables)**:
  * Built physical, materialized tables under the `silver` schema to enforce data typing, text trimming (`TRIM`), and Primary Key constraints (`PK_silver_*`).
  * Handled category translation by joining `olist_products_dataset` with `product_category_name_translation` using `COALESCE` to default missing categories to `'Unknown'`.
  * Deduplicated spatial records in `silver.geolocation` using `ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix ORDER BY geolocation_city)` to establish a clean 1:1 ZIP code lookup table.

* **Gold Layer (Virtual Dimensional Star Schema)**:
  * Architected virtual SQL **Views** under the `gold` schema instead of physical tables, eliminating disk storage overhead and ensuring zero-latency real-time synchronization with Silver updates.
  * Modeled Dimension Views (`gold.dim_customers`, `gold.dim_sellers`, `gold.dim_products`) enriched with spatial coordinates via spatial joins on ZIP code prefixes.
  * Modeled Fact Views (`gold.fact_sales_orders`, `gold.fact_order_payments`, `gold.fact_order_reviews`) featuring pre-calculated operational metrics such as `total_order_item_cost`, `actual_delivery_days`, and integer-formatted surrogate date keys (`purchase_date_key`).

---

### 6. Architectural Design Rationale

* **Why Physical Tables in Silver Layer?**
  * **Data Materialization**: Permanently stores cleaned and standardized records on disk, removing the overhead of re-cleansing raw records during queries.
  * **Performance & Constraints**: Enables Primary Keys, Foreign Keys, and indexing, which optimizes physical join performance and guarantees data integrity.

* **Why Virtual Views in Gold Layer?**
  * **Zero Storage Overhead**: Avoids duplicating underlying Silver data, optimizing overall database storage.
  * **Real-Time Data Reflection**: Any updates or insertions in the Silver layer automatically propagate through the Gold Views in real time without needing additional ETL jobs.

* **Why Execute Direct SQL Queries Before Power BI?**
  * **Source-Level QA**: Catches data anomalies and broken joins directly in SQL Server before loading datasets into Power BI.
  * **Performance & Query Folding**: Ensures complex transformations and joins are executed natively by the SQL Server engine.
  * **Single Source of Truth**: Centralizes transformation logic in SQL views so all downstream reports draw from identical business rules.

---

### 7. Pipeline Architecture Overview

[ Raw CSV Files ]
│
▼
[ Bronze Layer ] ────► (T-SQL Quality Audit & Validation)
(Raw Ingestion)         • Null Rates & Primary Key Audits
• Data Type & TRY_CAST Validation
│                • Business Logic & Timeline Checks
▼
[ Silver Layer ] ────► (Cleansing & Materialization)
(Physical Tables)       • TRIM Whitespace & Data Type Enforcement
• Primary Key & Index Constraints
• Spatial Deduplication (ZIP Lookup)
│
▼
[ Gold Layer ] ─────► (Dimensional Star Schema)
(Virtual Views)         • Zero Storage Overhead (Virtualization)
• Real-Time Synchronization with Silver
• Optimized for Power BI & DAX Pushdown


---

### 8. Next Steps
* Connect Power BI to the `gold` database views via SQL Server connector.
* Design interactive executive dashboards focusing on regional sales performance, delivery bottlenecks, seller SLA metrics, and customer review sentiment.
