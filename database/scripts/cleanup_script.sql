-- after the initial download, all the client's addresses are considered active,
-- we make sure that the most recent address remains active during the initial upload

BEGIN;

-- 1. Вычисляем "лишние" активные адреса (дубликаты)
CREATE TEMP TABLE addresses_to_close AS
SELECT address_id
FROM (
    SELECT
        address_id,
        customer_id,
        valid_from,
        -- Нумеруем адреса: 1 = самый свежий (оставляем), 2,3... = старые (закрываем)
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY valid_from DESC, address_id DESC) as rn
    FROM core.addresses
    WHERE is_current = TRUE
) t
WHERE rn > 1; -- Берем все, кроме первого

-- 2. Закрываем лишние адреса
-- ИСПРАВЛЕНИЕ: Добавляем +1 день, чтобы удовлетворить условие valid_to > valid_from
UPDATE core.addresses
SET
    is_current = FALSE,
    valid_to = valid_from + INTERVAL '1 day'
WHERE address_id IN (SELECT address_id FROM addresses_to_close);

-- 3. Проверка результата
SELECT
    (SELECT COUNT(*) FROM core.customers) as total_customers,
    (SELECT COUNT(*) FROM core.addresses WHERE is_current = TRUE) as active_addresses;

-- Удаляем временную таблицу
DROP TABLE addresses_to_close;

COMMIT;