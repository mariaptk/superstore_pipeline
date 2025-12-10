SET search_path TO core, stage, public;

BEGIN; -- Start transaction

-- Start audit logging
INSERT INTO core.load_audit (load_type, source_table, rows_processed, start_time, status)
VALUES ('INITIAL', 'stage.raw_orders', 0, CURRENT_TIMESTAMP, 'STARTED');

-- 1. Load customers
INSERT INTO core.customers (customer_number, customer_name, segment)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM stage.raw_orders
ON CONFLICT (customer_number) DO NOTHING;

-- 2. Load addresses
-- We take the earliest order date as the start date for the address
INSERT INTO core.addresses (
    customer_id, country, city, state, postal_code, region,
    valid_from, is_current
)
SELECT DISTINCT
    c.customer_id,
    ro.country,
    ro.city,
    ro.state,
    ro.postal_code,
    ro.region,
    MIN(ro.order_date::DATE) OVER (PARTITION BY ro.customer_id) as valid_from,
    TRUE as is_current
FROM stage.raw_orders ro
JOIN core.customers c ON ro.customer_id = c.customer_number;

-- 3. Load products
INSERT INTO core.products (product_number, product_name, category, sub_category)
SELECT DISTINCT
    product_id,
    product_name,
    category,
    sub_category
FROM stage.raw_orders
ON CONFLICT (product_number) DO NOTHING;

-- 4. Load orders
INSERT INTO core.orders (
    customer_id, order_number, order_date, ship_date, ship_mode, batch_id
)
SELECT DISTINCT
    c.customer_id,
    ro.order_id,
    ro.order_date::DATE,
    ro.ship_date::DATE,
    ro.ship_mode,
    1 as batch_id
FROM stage.raw_orders ro
JOIN core.customers c ON ro.customer_id = c.customer_number
ON CONFLICT (order_number) DO NOTHING;

-- 5. Load order details
INSERT INTO core.order_details (
    order_id, product_id, sales, quantity, discount, profit
)
SELECT
    o.order_id,
    p.product_id,
    ro.sales,
    ro.quantity,
    ro.discount,
    ro.profit
FROM stage.raw_orders ro
JOIN core.orders o ON ro.order_id = o.order_number
JOIN core.products p ON ro.product_id = p.product_number;

-- 6. Update audit status
UPDATE core.load_audit
SET
    rows_processed = (SELECT COUNT(*) FROM core.order_details),
    end_time = CURRENT_TIMESTAMP,
    status = 'COMPLETED'
WHERE load_type = 'INITIAL' AND status = 'STARTED';

COMMIT; -- End transaction