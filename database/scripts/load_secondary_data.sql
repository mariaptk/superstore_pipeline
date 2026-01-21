SET search_path TO core, stage, public;

BEGIN; -- Start transaction (changes will be rolled back if an error occurs)

DO $$
DECLARE
    -- Variable to store the new batch number
    new_batch_id INTEGER;

    -- Temporary counter for intermediate steps
    v_cnt INTEGER := 0;

    -- Variables for statistics tracking
    v_total_stage_rows INTEGER := 0;
    v_rows_inserted INTEGER := 0;
    v_rows_updated INTEGER := 0;
    v_rows_skipped INTEGER := 0;

BEGIN
    -- 1. Preparation: Count total rows in the staging table
    SELECT COUNT(*) INTO v_total_stage_rows FROM stage.delta_orders;

    -- Calculate new batch_id (Max existing ID + 1)
    -- If table is empty, start with 2 (since 1 was initial)
    SELECT COALESCE(MAX(batch_id), 1) + 1 INTO new_batch_id FROM core.orders;
    
    RAISE NOTICE 'Starting Secondary Data Load. Assigned Batch ID: %', new_batch_id;

    -- Log start of the load into audit table
    INSERT INTO core.load_audit (load_type, source_table, rows_processed, start_time, status)
    VALUES ('SECONDARY', 'stage.delta_orders', 0, CURRENT_TIMESTAMP, 'STARTED');

    -- 2. Customers (SCD Type 1 - Update names/segments)
    -- Update existing customers if name or segment changed
    UPDATE core.customers c
    SET
        customer_name = s.customer_name,
        segment = s.segment
    FROM stage.delta_orders s
    WHERE c.customer_number = s.customer_id
      AND (c.customer_name != s.customer_name OR c.segment != s.segment);

    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    v_rows_updated := v_rows_updated + v_cnt; -- Add to total updates

    -- Insert new customers
    INSERT INTO core.customers (customer_number, customer_name, segment)
    SELECT DISTINCT
        customer_id,
        customer_name,
        segment
    FROM stage.delta_orders
    ON CONFLICT (customer_number) DO NOTHING;

    -- 3. Addresses (SCD Type 2 - History Tracking)
    
    -- Step A: Close old address versions
    -- We use CASE to prevent date overlaps (if valid_from of new record <= old record)
    UPDATE core.addresses a
    SET
        is_current = FALSE,
        valid_to = CASE
            -- Edge case: if new date is earlier or equal to old date, close on the same day (or next)
            WHEN (s.valid_from::DATE - INTERVAL '1 day') <= a.valid_from 
            THEN a.valid_from 
            -- Normal case: close on the previous day
            ELSE (s.valid_from::DATE - INTERVAL '1 day')
        END
    FROM stage.delta_orders s
    JOIN core.customers c ON s.customer_id = c.customer_number
    WHERE a.customer_id = c.customer_id
      AND s.is_new_version = TRUE   -- Process only records marked as new version
      AND a.is_current = TRUE      -- Only update currently active addresses
        AND (                                   -- Ensure data is actually different
          a.region      IS DISTINCT FROM s.region OR
          a.state       IS DISTINCT FROM s.state OR
          a.city        IS DISTINCT FROM s.city OR
          a.postal_code IS DISTINCT FROM s.postal_code OR
          a.country     IS DISTINCT FROM s.country
      );

    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    v_rows_updated := v_rows_updated + v_cnt; -- Add to total updates

    -- Step B: Insert new address versions
    INSERT INTO core.addresses (customer_id, country, city, state, postal_code, region, valid_from, is_current)
    SELECT DISTINCT
        c.customer_id,
        s.country,
        s.city,
        s.state,
        s.postal_code,
        s.region,
        -- Use valid_from if available, otherwise use order_date
        CASE 
            WHEN s.valid_from IS NOT NULL AND s.valid_from != '' THEN s.valid_from::DATE
            ELSE s.order_date::DATE 
        END,
        TRUE -- Mark as current
    FROM stage.delta_orders s
    JOIN core.customers c ON s.customer_id = c.customer_number
    WHERE NOT EXISTS (
        -- Deduplication: do not insert if this active address already exists
        SELECT 1 FROM core.addresses a 
        WHERE a.customer_id = c.customer_id 
          AND a.is_current = TRUE
          AND a.region      IS NOT DISTINCT FROM s.region
          AND a.state       IS NOT DISTINCT FROM s.state
          AND a.city        IS NOT DISTINCT FROM s.city
          AND a.postal_code IS NOT DISTINCT FROM s.postal_code
    );

    -- 4. Products (New items)

    -- Insert new products
    INSERT INTO core.products (product_number, product_name, category, sub_category)
    SELECT DISTINCT
        product_id,
        product_name,
        category,
        sub_category
    FROM stage.delta_orders
    ON CONFLICT (product_number) DO NOTHING;

    -- 5. Orders
    -- Insert Orders (Target Table)
    INSERT INTO core.orders (customer_id, order_number, order_date, ship_date, ship_mode, batch_id)
    SELECT DISTINCT
        c.customer_id,
        s.order_id,
        s.order_date::DATE,
        -- Data cleaning: ship_date cannot be earlier than order_date
        GREATEST(s.ship_date::DATE, s.order_date::DATE),
        s.ship_mode,
        new_batch_id -- Use the calculated batch ID
    FROM stage.delta_orders s
    JOIN core.customers c ON s.customer_id = c.customer_number
    ON CONFLICT (order_number) DO NOTHING;

    -- Get number of inserted rows for the log
    GET DIAGNOSTICS v_cnt = ROW_COUNT;

    -- 6. Order Details
    -- Insert Order Details
    INSERT INTO core.order_details (order_id, product_id, sales, quantity, discount, profit)
    SELECT
        o.order_id,
        p.product_id,
        s.sales,
        -- Data cleaning: quantity cannot be 0
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

    -- 7. Calculate Skipped Rows (Duplicates)
    -- If total rows = 100 and we inserted 80 orders, then 20 were skipped duplicates
        v_rows_skipped := v_total_stage_rows - v_rows_inserted;

    -- 8. Finalize Audit
    UPDATE core.load_audit
    SET
        rows_processed = v_rows_inserted, -- Main metric
        rows_inserted  = v_rows_inserted, -- Detail
        rows_updated   = v_rows_updated,  -- Detail (SCD1 updates + SCD2 closing)
        rows_skipped   = v_rows_skipped,  -- Detail (Duplicates)
        end_time = CURRENT_TIMESTAMP,
        status = 'COMPLETED'
    WHERE load_type = 'SECONDARY' AND status = 'STARTED' AND start_time >= CURRENT_TIMESTAMP - interval '1 minute';

    RAISE NOTICE 'Load Finished. Batch: %, Inserted: %, Updated: %, Skipped: %', new_batch_id, v_rows_inserted, v_rows_updated, v_rows_skipped;

END $$;

COMMIT; -- Commit transaction