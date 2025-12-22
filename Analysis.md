

---

# Detailed Analysis of DAX Measures and Their Impact

During the report development, I opted against using standard implicit measures (auto-aggregation) in favor of explicit DAX calculations. This approach allowed for the implementation of complex business logic and the fulfillment of the assignment's technical requirements.

Below is a description of each measure created.

## Group 1: Basic Aggregations and Iterators

### 1. `Total Sales`
*   `SUM('mart fact_sales'[sales])`
*   **Description:** Basic aggregation. Sums the sales column within the current filter context.
*   **Dashboard Result:** Shows the company's total turnover — **17.65M**.

### 2. `Total Sales (Iterative)`
*   `SUMX('mart fact_sales', 'mart fact_sales'[sales])`
*   **Description:** Unlike `SUM`, the `SUMX` function iterates through the table row by row, evaluates the expression for each row, and then sums the results. It was created to demonstrate the difference between **SUM vs. SUMX**.
*   **Context:** In this dataset, the result matches `Total Sales`. However, in a real-world scenario (e.g., if the database had only `Price` and `Quantity` columns but no `Sales` column), using `SUM` would be impossible, and `SUMX` would be the only solution for row-by-row multiplication (`Price * Quantity`).

### 3. `Total Profit`
*   `SUM('mart fact_sales'[profit])`
*   **Description:** Shows the company's net profit.
*   **Dashboard Result:** **2.41M**.

### 4. `Profit Margin %`
*   `DIVIDE([Total Profit], [Total Sales], 0)`
*   **Description:** Created to evaluate sales efficiency. It shows how many cents of profit each dollar of revenue generates.
*   **Insight:** This specific measure helped identify the issue in the **Furniture** category, where despite high revenue, the margin is only **3.43%** (compared to ~18% in other categories).
    *   *(Note: Profit Margin is a financial metric indicating the percentage of revenue that remains as profit after deducting direct costs).*

---

## Group 2: Time Intelligence

These measures were created for dynamic analysis, as static figures do not provide insight into trends. A dedicated `Calendar` table was created to support them.

### 5. `Sales SPLY` (Same Period Last Year)
*   `CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Calendar'[Date]))`
*   **Technical Rationale:** The `CALCULATE` function modifies the filter context, while `SAMEPERIODLASTYEAR` shifts the current date range back by exactly one year.
*   **Purpose:** This measure was created to establish a baseline for comparison (Benchmarking). It allows plotting results for the current year and the past year on the same chart.
*   **Dashboard Result:** Visualized on the "Sales Trend" chart (dark blue line), showing seasonal fluctuations compared to the previous cycle.

### 6. `Sales YTD` (Year-to-Date)
*   `TOTALYTD([Total Sales], 'Calendar'[Date])`
*   **Description:** Calculates the cumulative total from January 1st to the current date within the context.
*   **Purpose:** A standard financial metric. It allows management to see the progress of the annual plan on any given day of the year.

### 7. `Sales YoY %` (Year-over-Year Growth)
*   ```dax
    VAR CurrentSales = [Total Sales]
    VAR LastYearSales = [Sales SPLY]
    RETURN
    DIVIDE(CurrentSales - LastYearSales, LastYearSales, 0)
    ```
*   **Technical Rationale:** Uses variables (`VAR`) for code readability and optimization (measures are not recalculated twice). It calculates relative growth.
*   **Purpose:** The main KPI for business health.
*   **Dashboard Result:** The measure value is **0.04%**. This is a critical finding: **despite millions in turnover, the company is stagnating (growth is practically non-existent compared to the last year).**

---

## Group 3: Context Manipulation

### 8. `% of Total Sales`
*   ```dax
    DIVIDE(
        [Total Sales],
        CALCULATE([Total Sales], ALL('mart fact_sales')),
        0
    )
    ```
*   **Technical Rationale:**
    *   `ALL('mart fact_sales')` — removes absolutely all filters from the fact table.
    *   `CALCULATE` — computes the total sales of the entire store (the "Denominator"), ignoring specific category selections in the visualization.
*   **Insight:** This measure revealed in the Product Matrix that the **Technology** and **Furniture** categories have nearly identical revenue shares (**~33-35%**), yet drastically different profit contributions. Without using `ALL`, we could not correctly calculate the share of a specific row relative to the grand total within the matrix.
