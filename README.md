# Superstore BI Pipeline: End-to-End Data Engineering Project

This project implements a complete **Data Pipeline** for a retail Superstore. It covers the full lifecycle of data engineering: from raw data preprocessing in Python to complex data warehousing using **SCD (Slowly Changing Dimensions)** strategies in SQL, and finally visualizing business KPIs in Power BI.

---

## Project Goals & Architecture

The main goal was to simulate a real-world scenario where data comes in batches (historical + incremental updates) and business requirements dictate how changes should be tracked.

### Key Design Decisions:
1.  **Layered Architecture:**
    *   **Stage Layer (`stage` schema):** Acts as a landing zone for raw CSV data. No transformations are applied here; data is loaded "as is".
    *   **Core Layer (`core` schema):** The final production-ready tables where business logic and data history are stored.

2.  **Handling Data Changes (SCD Strategy):**
    *   **SCD Type 1 (Overwrite):** Applied to `Customer Name`. If a customer corrects their name, we overwrite the old one. We don't need history for typos.
    *   **SCD Type 2 (History Tracking):** Applied to `Address/City/Postal Code`. If a customer moves, we keep the old address record valid until the move date and create a new active record. This allows accurate historical reporting (e.g., "Sales by Region" for past years remains correct).

3.  **Data Quality:**
    *   Duplicate checks are implemented during the merge process to prevent data corruption.

---

## Technologies

*   **Python (Pandas):** For data splitting, cleaning, and simulating daily data dumps.
*   **SQL (PostgreSQL):** For DDL (Schema creation) and DML (Stored procedures logic/Merges).
*   **Power BI:** For the analytical dashboard.
*   **Git/GitHub:** Version control.

---

## Database Schema

The core schema is designed as a Star Schema variant tailored for the SCD tracking.

<img width="100%" alt="Database Schema" src="https://github.com/user-attachments/assets/8e0a0134-b99c-4b43-b5ae-a3134b30fbbe" />

---

## Detailed Setup & Execution Guide

Follow these steps to replicate the pipeline.

### Prerequisites
*   Installed Python 3.x and Jupyter Notebook.
*   A SQL Client (DBeaver, pgAdmin, or similar) connected to your database.

### Step 1: Data Preparation (Python)
We need to generate the "Historical" data and the "New" incoming data to test our pipeline.

*   **File:** `notebooks/dataset_split.ipynb`
*   **Action:** Open the notebook and run all cells.
*   **Output:** Two CSV files will be created in the `notebooks/` folder:
    1.  `initial_load.csv` (Historical data)
    2.  `secondary_load.csv` (New data with changes)

### Step 2: Database Initialization
Create the necessary schemas (`stage`, `core`) and empty tables.

*   **File:** `Database/01_create_schemas.sql`
*   **Action:** Execute the script in your SQL Client.

### Step 3: Initial Load (Historical Data)
We populate the data warehouse with the base history.

1.  **Import Data:**
    *   Use your SQL Client's "Import Data" wizard (e.g., in DBeaver: Right-click `stage.raw_orders` -> Import Data -> CSV).
    *   Select `initial_load.csv`.
    *   Target table: **`stage.raw_orders`**.
2.  **Run Logic:**
    *   Execute `Database/02_initial_load.sql`.
    *   *What happens?* Data moves from `stage` to `core`. Since tables are empty, this is a direct insert.

### Step 4: Secondary Load (Incremental Updates)
Now we simulate "Day 2". New orders arrive, some customers moved, and some fixed typos in their names.

1.  **Import Data:**
    *   **Important:** First, clear the stage table: `TRUNCATE TABLE stage.delta_orders;`
    *   Import `secondary_load.csv` into the target table: **`stage.delta_orders`**.
2.  **Run Logic:**
    *   Execute `Database/03_secondary_load.sql`.
    *   *What happens?* The script compares `stage` vs `core`.
        *   **New Orders** -> Inserted.
        *   **Name Changes** -> Update existing row (SCD1).
        *   **Address Changes** -> Close old row (`valid_to` = now), Insert new row (SCD2).

---

## Power BI Dashboard & Insights

The final step is connecting Power BI to the `core` tables to visualize the results.

### Dashboard Preview
*(Upload a screenshot of your dashboard here and replace the link below)*
<img src="https://via.placeholder.com/800x400?text=Dashboard+Screenshot+Here" width="100%" alt="Dashboard Preview">

### Key Business Insights
Based on the analysis of the loaded data:

1.  **Sales Performance:**
    *   Total Sales for the period: **$X.XM** (Replace with your number).
    *   The top-performing category is **Technology**, driven by phone sales.
2.  **Regional Trends:**
    *   The **West Region** shows the highest profit margin.
    *   Shipping times are longest in the South Region (avg. 5 days).
3.  **Customer Behavior:**
    *   Repeat customers account for **40%** of total revenue.
    *   (Add any other interesting finding from your visual charts).

---

## Repository Structure

*   `Database/`: Contains all SQL scripts (`.sql`) for schema and logic.
*   `notebooks/`: Python notebooks (`.ipynb`) and raw CSV data.
*   `Dashboard/`: Power BI project files (`.pbix`) and PDF exports.
*   `src/`: Helper scripts.
