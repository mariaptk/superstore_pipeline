Вот код для создания структурированного README.md файла:

# Superstore BI Pipeline: ETL & Data Warehousing

## Project Overview

This project simulates a complete real-world Business Intelligence (BI) pipeline. The goal was to transform a raw, flat dataset (Superstore) into a structured Data Warehouse capable of handling historical changes (SCD) and providing analytical insights via Power BI.

The project covers the full data lifecycle:
1. **Data Engineering:** Data generation, cleaning, and database modeling (Normalization)
2. **ETL Development:** Building an incremental loading strategy with SCD Type 1 and Type 2 logic
3. **BI Reporting:** Creating an interactive Power BI dashboard with advanced DAX measures and storytelling

## Project Structure

```
superstore_bi_pipeline/
├── dashboard/
│   └── superstore.pbix           # Power BI Report file
├── data/
│   └── raw/                      # Generated CSV files (initial & secondary)
├── database/
│   ├── config/                   # DB connection setup
│   └── scripts/                  # SQL scripts for the pipeline
│       ├── create_schemas.sql    # DDL: Tables and constraints
│       ├── create_mart.sql       # Views for Power BI (Star Schema)
│       ├── load_initial_data.sql # DML: Initial Load logic
│       └── load_secondary_data.sql # DML: Incremental Load (SCD logic)
├── notebooks/
│   └── dataset_split.ipynb       # Python script for data generation
└── README.md                     # Project documentation
```

## 1. Database Architecture

I designed a **3-Layer Architecture** to ensure data integrity, scalability, and query performance.

### Layer 1: Stage
Contains raw tables (`raw_orders`, `delta_orders`). Data is ingested here directly from CSVs without strict constraints to allow fast loading and initial data profiling.

### Layer 2: Core (Normalized Layer)
This is the central Data Warehouse layer. I applied **Pragmatic Normalization** principles to organize data into logical entities.

**Design Decision - Handling History (SCD Type 2):**
I decided to separate Customers and Addresses into different tables:
- `core.customers`: Handles SCD Type 1 (e.g., Name corrections). We overwrite the old name because we don't need to track typo history
- `core.addresses`: Handles SCD Type 2 (History tracking). Uses `valid_from`, `valid_to`, and `is_current` columns

**Why?** This allows tracking a customer's relocation history without duplicating their static profile data (Name, Segment) in every transaction row.

**Key Features:**
- **Surrogate Keys:** All tables use internal serial IDs (`customer_id`, `product_id`) instead of relying solely on business keys
- **Audit Table:** `core.load_audit` tracks execution time, status, and row counts for every ETL load

### Layer 3: Mart (Reporting Layer)
I created SQL Views to transform the normalized schema into a **Star Schema** optimized for Power BI:
- `fact_sales`: Implements **Point-in-Time logic**. Joins orders to the address valid at purchase time for historical accuracy
- `dim_products` & `dim_customers`: Denormalized dimensions for easy filtering and drilling

![Database Schema](database_schema.png)

## 2. ETL Process & Logic

The ETL pipeline handles complex data scenarios during the Secondary (Incremental) Load.

### Python Data Preparation
The Jupyter Notebook (`dataset_split.ipynb`) simulates a real production environment by:
- Standardizing date formats to `YYYY-MM-DD` to prevent SQL conversion errors
- Generating specific test scenarios: New records, Duplicates, SCD1 changes (customer name updates), and SCD2 changes (region moves)

### SQL Transformation Logic
The `load_secondary_data.sql` script implements robust logic to handle changes:

**SCD Type 1 (Customers):**
- Updates customer names in place if they changed in the source

**SCD Type 2 (Addresses):**
1. Identifies if a customer moved to a new region
2. Closes the old record by setting `valid_to` to the day before the new record starts
3. **Logic for Date Overlaps:** Includes a CASE statement to handle edge cases where new record dates conflict with existing history
4. Inserts the new active record with `is_current = TRUE`

**Data Quality & Cleaning:**
- **Ship Date Repair:** Uses `GREATEST(ship_date, order_date)` to fix logical errors
- **Deduplication:** Uses `ON CONFLICT` and `NOT EXISTS` clauses to ensure idempotency

## 3. Power BI Report & Analysis

The report connects to the Mart Layer using Import Mode for better performance and DAX capabilities.

### Data Modeling & DAX

**Date Table:** Created a dedicated Calendar table using DAX to support Time Intelligence functions.

**Key Measures Implemented:**
- **SUM vs SUMX:** Demonstrated the difference between simple aggregation and iterative calculations
- **Time Intelligence:** Created Sales YoY % (Year-over-Year growth) and Sales YTD (Year-to-Date)
- **Context Manipulation:** Used `ALL()` to calculate % of Total Sales

### Dashboard Pages

#### 1. Sales Overview
- **Visuals:** KPI Cards, Trend Line, and Map
- **Key Feature:** The Map uses historical data from `fact_sales`. If a customer moved regions, their old sales correctly remain attributed to the original region

#### 2. Product Performance
- **Visuals:** Decomposition Tree (AI visual) and Matrix with Data Bars
- **Insight:** Technology drives the most revenue. Furniture has high volume but critically low profit margins (needs logistics investigation)

#### 3. Customer Insights
- **Visuals:** Scatter Plot and Histogram
- **Scatter Plot Analysis:** Shows correlation between Sales and Profit. Identified "Unprofitable Customers" cluster (high sales, negative profit)
- **Histogram Analysis:** Shows most orders are small value (<$500), indicating a mass-market business model

## How to Run

### 1. Generate Data:
```bash
# Run the Jupyter notebook to generate test data
jupyter notebook notebooks/dataset_split.ipynb
```
This creates `initial_load.csv` and `secondary_load.csv` in `data/raw/`

### 2. Setup Database:
Execute SQL scripts in order:
```
-- 1. Create schemas and tables
database/scripts/create_schemas.sql

-- 2. Import initial data
-- First, import initial_load.csv into stage.raw_orders using your SQL client
-- Then run:
database/scripts/load_initial_data.sql

-- 3. Import secondary data
-- Truncate stage.delta_orders and import secondary_load.csv
-- Then run:
database/scripts/load_secondary_data.sql

-- 4. Create mart views
database/scripts/create_mart.sql
```

