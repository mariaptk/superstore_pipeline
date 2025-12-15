-- Create schema for reporting
CREATE SCHEMA IF NOT EXISTS mart;

-- Simple list for filtering by Category -> Sub-Category -> Product
CREATE OR REPLACE VIEW mart.dim_products AS
SELECT
    product_id,
    product_number,
    product_name,
    category,
    sub_category
FROM core.products;

-- Shows where the customer lives NOW.
-- Used for marketing analysis and current segmentation.
CREATE OR REPLACE VIEW mart.dim_customers AS
SELECT DISTINCT ON (c.customer_id)
    c.customer_id,
    c.customer_number,
    c.customer_name,
    c.segment,
    a.country,
    a.city,
    a.state,
    a.region,
    a.postal_code
FROM core.customers c
JOIN core.addresses a ON c.customer_id = a.customer_id
WHERE a.is_current = TRUE
ORDER BY c.customer_id, a.valid_from DESC;

-- The main table for analysis.
-- Connects orders to the address that was valid ON THE DATE OF ORDER.
CREATE OR REPLACE VIEW mart.fact_sales AS
SELECT
    od.order_detail_id,
    o.order_id,
    o.order_number,
    o.order_date,
    o.ship_date,
    o.ship_mode,

    -- Foreign Keys for linking Dimensions
    o.customer_id,
    od.product_id,

    -- Historical Geography (Where the customer lived when they bought)
    -- This comes from the SCD Type 2 logic
    a.country as sales_country,
    a.region  as sales_region,
    a.state   as sales_state,
    a.city    as sales_city,

    -- Metrics
    od.sales,
    od.quantity,
    od.discount,
    od.profit

FROM core.order_details od
JOIN core.orders o ON od.order_id = o.order_id
-- Join addresses based on date ranges
-- This ensures sales are attributed to the correct historical region
LEFT JOIN core.addresses a ON o.customer_id = a.customer_id
    AND o.order_date >= a.valid_from
    AND (a.valid_to IS NULL OR o.order_date <= a.valid_to);




