-- problem solving
-- checking the initial data
SELECT
    customer_name,
    region,
    city
FROM stage.raw_orders
WHERE customer_id IN (
    -- Select customers who have more than 1 address record
    SELECT customer_id
    FROM stage.raw_orders
    GROUP BY customer_id
    HAVING COUNT(*) > 1
)
ORDER BY customer_name;
-- conclusion: only customers have given orders from different addresses

-- Step 1. Find the "Traveler"
-- We are looking for clients whose address has changed (there are records in the history)
SELECT
    c.customer_name,
    c.customer_id,
    a.region,
    a.valid_from,
    a.valid_to,
    a.is_current
FROM core.addresses a
JOIN core.customers c ON a.customer_id = c.customer_id
WHERE c.customer_id IN (
    -- We take those who have more than 1 record
    SELECT customer_id FROM core.addresses GROUP BY customer_id HAVING COUNT(*) > 1
)
ORDER BY c.customer_name, a.valid_from;

--Step 2. Select for your order in the Showcase (March)
SELECT
    order_date,
    sales_region,  -- This is a field from the address table, inserted via JOIN
    sales
FROM mart.fact_sales
WHERE customer_id = (SELECT customer_id FROM core.customers WHERE customer_name = 'Aaron Bergman') -- Подставь имя своего "путешественника"
ORDER BY order_date;



