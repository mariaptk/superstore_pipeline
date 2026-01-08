-- Clean up previous objects
DROP SCHEMA IF EXISTS stage CASCADE;
CREATE SCHEMA stage;

-- Create stage table for initial load
DROP TABLE IF EXISTS stage.raw_orders CASCADE;
CREATE TABLE stage.raw_orders (
    row_id INTEGER,
    order_id VARCHAR(50),
    order_date VARCHAR(20),
    ship_date VARCHAR(20),
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code INTEGER,
    region VARCHAR(50),
    product_id VARCHAR(20),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(200),
    sales DECIMAL(10,2),
    quantity INTEGER,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2)
);

-- Create stage table for secondary load
DROP TABLE IF EXISTS stage.delta_orders CASCADE;
CREATE TABLE stage.delta_orders (
    row_id INTEGER PRIMARY KEY,
    order_id VARCHAR(50),
    order_date VARCHAR(20),
    ship_date VARCHAR(20),
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code INTEGER,
    region VARCHAR(50),
    product_id VARCHAR(20),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(200),
    sales DECIMAL(10,2),
    quantity INTEGER,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2),
    valid_from VARCHAR(20),          -- Version start date
    valid_to VARCHAR(20),            -- Version end date
    previous_region VARCHAR(50),     -- Previous region
    is_new_version BOOLEAN,          -- Flag for new version
    scd2_attribute_changed VARCHAR(50) -- Name of changed attribute
);

-- Recreate core schema
DROP SCHEMA IF EXISTS core CASCADE;
CREATE SCHEMA IF NOT EXISTS core;

-- 1. Customers table (scd type 1)
CREATE TABLE IF NOT EXISTS core.customers (
    customer_id SERIAL PRIMARY KEY,
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    customer_name VARCHAR(255) NOT NULL,
    segment VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Addresses table (scd type 2)
CREATE TABLE IF NOT EXISTS core.addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES core.customers(customer_id),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code INTEGER,
    region VARCHAR(100),
    -- Versioning fields for scd type 2
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_dates CHECK (valid_to IS NULL OR valid_to > valid_from)
);

-- Create index for faster search of current addresses
CREATE INDEX IF NOT EXISTS idx_addresses_customer_current
ON core.addresses(customer_id, is_current);

-- 3. Products table (scd type 1)
CREATE TABLE IF NOT EXISTS core.products (
    product_id SERIAL PRIMARY KEY,
    product_number VARCHAR(50) NOT NULL UNIQUE,
    product_name TEXT NOT NULL,
    category VARCHAR(100),
    sub_category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Orders table
CREATE TABLE IF NOT EXISTS core.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES core.customers(customer_id),
    order_number VARCHAR(50) NOT NULL UNIQUE,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,
    ship_mode VARCHAR(100),
    batch_id INTEGER NOT NULL,  -- 1 for initial, 2 for secondary
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_order_dates CHECK (ship_date >= order_date)
);

-- 5. Order details table
CREATE TABLE IF NOT EXISTS core.order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES core.orders(order_id),
    product_id INTEGER NOT NULL REFERENCES core.products(product_id),
    sales DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL,
    discount DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    profit DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_quantity CHECK (quantity > 0),
    CONSTRAINT check_discount CHECK (discount >= 0 AND discount <= 1)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_order_details_order ON core.order_details(order_id);
CREATE INDEX IF NOT EXISTS idx_order_details_product ON core.order_details(product_id);

-- 6. Audit table
CREATE TABLE IF NOT EXISTS core.load_audit (
    load_id SERIAL PRIMARY KEY,
    load_type VARCHAR(20) NOT NULL,
    source_table VARCHAR(50) NOT NULL,
    rows_processed INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'STARTED',
    error_message TEXT
);