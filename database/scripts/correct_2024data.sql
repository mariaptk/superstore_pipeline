-- Удаляем детали заказов за 2024 год (оставляем только 20% случайных)
DELETE FROM core.order_details
WHERE order_id IN (
    SELECT order_id
    FROM core.orders
    WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
    AND order_number LIKE 'GAP%' -- Только наши сгенерированные
)
AND random() > 0.2; -- Удаляем 80% строк

-- Удаляем сами заказы, у которых не осталось деталей (чистка)
DELETE FROM core.orders
WHERE order_id NOT IN (SELECT DISTINCT order_id FROM core.order_details)
AND order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- Обновляем аудит (опционально, для порядка)
INSERT INTO core.load_audit (load_type, source_table, rows_processed, start_time, status)
VALUES ('DATA_CORRECTION', '2024_cleanup', 0, CURRENT_TIMESTAMP, 'COMPLETED');