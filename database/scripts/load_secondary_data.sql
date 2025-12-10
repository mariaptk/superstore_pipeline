-- 1. Update existing customers (scd type 1)
UPDATE core.customers c
SET
    customer_name = s.customer_name,
    segment = s.segment
FROM stage.delta_orders s
WHERE c.customer_number = s.customer_id
  AND (c.customer_name != s.customer_name OR c.segment != s.segment);

-- Insert new customers
INSERT INTO core.customers (customer_number, customer_name, segment)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM stage.delta_orders
ON CONFLICT (customer_number) DO NOTHING;

-- 2. Process addresses (scd type 2)
-- Close old versions of addresses
UPDATE core.addresses a
SET
    is_current = FALSE,
    valid_to = CASE
        -- Handle date overlap errors
        WHEN (s.valid_from::DATE - INTERVAL '1 day') <= a.valid_from
        THEN a.valid_from + INTERVAL '1 day'
        -- Normal case: close with previous day
        ELSE (s.valid_from::DATE - INTERVAL '1 day')
    END
FROM stage.delta_orders s
JOIN core.customers c ON s.customer_id = c.customer_number
WHERE a.customer_id = c.customer_id
  AND s.is_new_version = TRUE
  AND a.is_current = TRUE;

-- Insert new address versions
INSERT INTO core.addresses (customer_id, country, city, state, postal_code, region, valid_from, is_current)
SELECT DISTINCT
    c.customer_id,
    s.country,
    s.city,
    s.state,
    s.postal_code,
    s.region,
    CASE
        WHEN s.valid_from IS NOT NULL AND s.valid_from != '' THEN s.valid_from::DATE
        ELSE s.order_date::DATE
    END as valid_from,
    TRUE as is_current
FROM stage.delta_orders s
JOIN core.customers c ON s.customer_id = c.customer_number
WHERE NOT EXISTS (
    SELECT 1 FROM core.addresses a
    WHERE a.customer_id = c.customer_id
      AND a.region = s.region
      AND a.city = s.city
      AND a.is_current = TRUE
);

-- 3. Insert new products
INSERT INTO core.products (product_number, product_name, category, sub_category)
SELECT DISTINCT
    product_id,
    product_name,
    category,
    sub_category
FROM stage.delta_orders
ON CONFLICT (product_number) DO NOTHING;

-- 4. Process orders
INSERT INTO core.orders (customer_id, order_number, order_date, ship_date, ship_mode, batch_id)
SELECT DISTINCT
    c.customer_id,
    s.order_id,
    s.order_date::DATE,
    -- Fix invalid ship dates using greatest function
    GREATEST(s.ship_date::DATE, s.order_date::DATE) as ship_date,
    s.ship_mode,
    2 -- Secondary batch
FROM stage.delta_orders s
JOIN core.customers c ON s.customer_id = c.customer_number
ON CONFLICT (order_number) DO NOTHING;

-- 5. Process order details
INSERT INTO core.order_details (order_id, product_id, sales, quantity, discount, profit)
SELECT
    o.order_id,
    p.product_id,
    s.sales,
    CASE WHEN s.quantity = 0 THEN 1 ELSE s.quantity END,
    s.discount,
    s.profit
FROM stage.delta_orders s
JOIN core.orders o ON s.order_id = o.order_number
JOIN core.products p ON s.product_id = p.product_number
WHERE NOT EXISTS (
    SELECT 1 FROM core.order_details od
    WHERE od.order_id = o.order_id AND od.product_id = p.product_id
);

-- Check results
SELECT 'Orders count batch 2' as metric, count(*) as val FROM core.orders WHERE batch_id = 2;