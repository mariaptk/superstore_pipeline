-- After initial data load, all client addresses are marked as active.
-- This script ensures only the most recent address remains active per customer.

BEGIN;

-- 1. Identify duplicate active addresses to deactivate
CREATE TEMP TABLE addresses_to_close AS
SELECT address_id
FROM (
    SELECT
        address_id,
        customer_id,
        valid_from,
        -- Rank addresses: 1 = most recent (keep active), 2+ = older (deactivate)
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY valid_from DESC, address_id DESC) as rn
    FROM core.addresses
    WHERE is_current = TRUE
) t
WHERE rn > 1; -- Select all except the most recent

-- 2. Deactivate duplicate addresses
-- NOTE: Adding 1 day to ensure valid_to > valid_from constraint
UPDATE core.addresses
SET
    is_current = FALSE,
    valid_to = valid_from + INTERVAL '1 day'
WHERE address_id IN (SELECT address_id FROM addresses_to_close);

-- 3. Verification step
SELECT
    (SELECT COUNT(*) FROM core.customers) as total_customers,
    (SELECT COUNT(*) FROM core.addresses WHERE is_current = TRUE) as active_addresses;

-- Cleanup temporary table
DROP TABLE addresses_to_close;

COMMIT;