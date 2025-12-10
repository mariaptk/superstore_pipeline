### Database schema

<img width="914" height="805" alt="image" src="https://github.com/user-attachments/assets/045cb8f4-2fd2-4ecc-b642-a94ec8832904" />

### How to run

1. Prepare data
File: dataset_split.ipynb
Run: Execute all cells in the notebook.
Result: Generates initial_load.csv and secondary_load.csv.
Why: Formats dates correctly and creates test data for updates and versioning.
2. Setup database
File: 01_create_schemas.sql
Run: Execute in SQL client.
Why: Creates the stage and core schemas and tables.
3. Initial load
Import:
Load initial_load.csv into the stage.raw_orders table.
File: 02_initial_load.sql
Run: Execute in SQL client.
Why: Fills the database with the main historical data.
4. Secondary load
Import:
Clear the previous table (TRUNCATE stage.delta_orders).
Load secondary_load.csv into the stage.delta_orders table.
File: 03_secondary_load.sql
Run: Execute in SQL client.
Why:
Updates customer names (SCD1).
Tracks address changes (SCD2).
Adds new orders.
Skips duplicates.
