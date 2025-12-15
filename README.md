# Superstore BI Pipeline

This project implements a Data Pipeline for Superstore data, covering data preparation, initial loading, and incremental updates using SCD (Slowly Changing Dimensions) strategies.

## 📂 Project Structure

- **Database/**: SQL scripts for schema creation and data transformation.
- **notebooks/**: Jupyter notebooks for data preprocessing and splitting.
- **src/**: Source code and utilities.
- **Dashboard/**: Visualization files and dashboard exports.

---

## 🗄️ Database Schema

<img width="100%" alt="Database Schema" src="https://github.com/user-attachments/assets/8e0a0134-b99c-4b43-b5ae-a3134b30fbbe" />

---

## 🚀 How to run

Follow these steps to set up and populate the database.

### 1. Prepare data
*   **File:** `notebooks/dataset_split.ipynb`
*   **Run:** Execute all cells in the notebook.
*   **Result:** Generates `initial_load.csv` and `secondary_load.csv`.
*   **Why:** Formats dates correctly and creates test data for updates and versioning.

### 2. Setup database
*   **File:** `Database/01_create_schemas.sql`
*   **Run:** Execute in your SQL client.
*   **Why:** Creates the `stage` and `core` schemas and tables.

### 3. Initial load
*   **Import:** Load `initial_load.csv` into the `stage.raw_orders` table.
*   **File:** `Database/02_initial_load.sql`
*   **Run:** Execute in your SQL client.
*   **Why:** Fills the database with the main historical data.

### 4. Secondary load
*   **Import:**
    1. Clear the previous table: `TRUNCATE stage.delta_orders;`
    2. Load `secondary_load.csv` into the `stage.delta_orders` table.
*   **File:** `Database/03_
