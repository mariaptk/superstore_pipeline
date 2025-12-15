# Superstore BI Pipeline

This project demonstrates an end-to-end Data Engineering pipeline using Python, SQL (PostgreSQL), and Power BI. The goal was to simulate a real-world scenario where data is loaded incrementally, and historical changes (like address updates) are tracked correctly.

## Project Overview

The project processes sales data from a "Superstore" retailer. Instead of simply loading a static file, the pipeline handles:
1.  **Data Splitting:** Simulating "Day 1" (historical data) and "Day 2" (new orders and updates).
2.  **Data Warehousing:** Using specific strategies to handle changes in customer data.
3.  **Visualization:** Analyzing the final data in Power BI.

---

## Architecture & Design Decisions

I designed the database with two specific layers to ensure data quality and traceability.

### 1. Two-Layer Approach
*   **Stage Schema (`stage`):** This is the landing zone. Data is loaded here directly from CSV files without modification. This ensures we always have a copy of the raw source data.
*   **Core Schema (`core`):** This is the production layer. Data is cleaned, transformed, and stored here for the dashboard.

### 2. Handling Data Changes (SCD Strategy)
A key challenge was how to handle updates when a customer changes their details. I used **Slowly Changing Dimensions (SCD)**:

*   **Customer Names (SCD Type 1):**
    *   *Logic:* If a customer's name changes (e.g., a spelling correction), the old name is overwritten.
    *   *Reason:* We do not need to track the history of typos. The current name is the only one that matters.
*   **Addresses/Cities (SCD Type 2):**
    *   *Logic:* If a customer moves to a new city, the old record is marked as "inactive" (with an end date), and a new record is created.
    *   *Reason:* This is critical for reporting. If we look at sales from 2022, they should be attributed to the customer's *location in 2022*, not their current location.

---

## Database Schema

The schema is designed to support the SCD logic, linking orders to specific versions of customer dimensions.

<img width="100%" alt="Database Schema" src="https://github.com/user-attachments/assets/8e0a0134-b99c-4b43-b5ae-a3134b30fbbe" />

---

## How to Run the Pipeline

### 1. Prepare the Data
First, we generate the datasets to simulate the timeline.
*   **File:** `notebooks/dataset_split.ipynb`
*   **Action:** Run all cells in the notebook.
*   **Result:** Two files are created:
    *   `initial_load.csv`: The main historical dataset.
    *   `secondary_load.csv`: Contains new orders and specific updates (address changes) to test the logic.

### 2. Setup Database
*   **File:** `Database/01_create_schemas.sql`
*   **Action:** Execute in SQL client.
*   **Result:** Creates the `stage` and `core` schemas and empty tables.

### 3. Initial Load (Day 1)
Loading the historical history.
*   **Import:** Load `initial_load.csv` into the table **`stage.raw_orders`**.
*   **Execute:** Run `Database/02_initial_load.sql`.
*   **Explanation:** This script populates the Core tables for the first time. All records are marked as currently active.

### 4. Secondary Load (Day 2 - Incremental Updates)
Processing new data and changes.
*   **Prepare:** Run `TRUNCATE TABLE stage.delta_orders;` to clear the landing table.
*   **Import:** Load `secondary_load.csv` into the table **`stage.delta_orders`**.
*   **Execute:** Run `Database/03_secondary_load.sql`.
*   **Explanation:** The script compares the new data against the existing Core data. It automatically inserts new orders, updates corrected names, and versions old addresses.

---

## Power BI Insights

The Power BI dashboard is connected to the `core` tables. Here are the key findings based on the data:

*(Insert a screenshot of your dashboard here if available)*

1.  **Sales Performance:**
    *   The **Technology** category generates the highest revenue, while Furniture has the lowest profit margins due to high operational costs.
2.  **Regional Analysis:**
    *   The **West Region** performs best in terms of sales volume.
    *   Shipping delays are most frequent in the South Region, which affects customer satisfaction.
3.  **Profitability:**
    *   Discounts higher than 20% generally result in negative profit, suggesting a need to revise the discounting strategy.

---

## Repository Structure

*   **Database/**: SQL scripts for schema creation and stored procedures.
*   **notebooks/**: Python scripts for data preparation and splitting.
*   **Dashboard/**: Power BI project files.
*   **src/**: Additional source code and utilities.
