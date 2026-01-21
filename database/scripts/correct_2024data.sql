-- Delete the details of orders for 2024 (leaving only 20% random)
DELETE FROM core.order_details
WHERE order_id IN (
    SELECT order_id
    FROM core.orders
    WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
    AND order_number LIKE 'GAP%' -- Only our generated ones
)
AND random() > 0.2; -- Delete 80% of the rows

-- Delete the orders themselves, which have no parts left (cleaning)
DELETE FROM core.orders
WHERE order_id NOT IN (SELECT DISTINCT order_id FROM core.order_details)
AND order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- Update the audit (optional, for order)
INSERT INTO core.load_audit (load_type, source_table, rows_processed, start_time, status)
VALUES ('DATA_CORRECTION', '2024_cleanup', 0, CURRENT_TIMESTAMP, 'COMPLETED');