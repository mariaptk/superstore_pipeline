
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

---

# 5. Detailed Visualization Analysis

Below is a detailed breakdown of the three dashboard pages, including the interpretation of the obtained metrics.

## Page 1: Sales Overview

This page provides a "Helicopter View" of the business status.

### 1. KPI Cards
*   **What they show:**
    *   **Total Sales:** 17.65M (Total turnover).
    *   **Total Profit:** 2.41M (Net profit).
    *   **Sales YoY %:** 0.04 (or 4%).
*   **Analytical Conclusion:** The company generates significant revenue and profit, but the **0.04% YoY** metric is a warning signal. This indicates **stagnation**: the business has barely grown compared to last year. The company has hit a "ceiling," and current strategies are insufficient for scaling.

### 2. Bar Chart "Sales Trend vs Last Year"
*   **What it shows:** A comparison of current year sales (light blue) versus last year (dark blue) broken down by month.
*   **Analytical Conclusion (Seasonality):**
    *   The business shows strong seasonality. **Peak months:** November (>2.5M), September, December. This is linked to seasonal sales (Black Friday, Christmas).
    *   **Problem zone:** February and January are the weakest months (turnover is 5x lower than November).
    *   **Recommendation:** The marketing budget needs redistribution: "warm up" demand with promotions in **Q1 (Jan-March)** to smooth out cash flow gaps.

### 3. Map "Total Sales by sales_state" (Geography)
*   **What it shows:** A bubble map of sales by US state. It utilizes historical data (SCD2).
*   **Analytical Conclusion:**
    *   Major markets are **California (West), New York (East), and Texas (South)**.
    *   The Central US (North/South Dakota, Wyoming) is practically uncovered.
    *   **Recommendation:** Logistics hubs should be located closer to the coasts, as order concentration is highest there.

### 4. Donut Chart "Sales by Segment"
*   **What it shows:** Revenue share by customer type.
*   **Analytical Conclusion:**
    *   **Consumer:** 50.86% (8.97M). This is the main business driver.
    *   **Corporate:** 30.73%.
    *   **Home Office:** 18.41%.
    *   The business model is **B2C oriented**. Any changes to user experience (UI/UX) on the site will impact half of the revenue.

---

## Page 2: Product Performance

Here we look for the causes of low efficiency.

### 1. Matrix "Category Overview"
*   **What it shows:** Product hierarchy with Sales, Profit Margin, and Share of Total Sales metrics.
*   **Analytical Conclusion (Critical Insight):**
    *   **Efficiency Leader:** `Technology` and `Office Supplies` have a healthy margin of **~18.5%**.
    *   **Unprofitable Leader:** The `Furniture` category holds a 33% sales share (5.7M) but has a margin of only **3.43%**.
    *   **Problem Detail:** Drilling down into Furniture reveals the **Tables** sub-category with a negative margin of **-7.93%**. The **Bookcases** sub-category is also unprofitable at **-2.31%**.
    *   **Positive Example:** The `Paper` sub-category has a margin of **44.42%**.
*   **Recommendation:** We are losing money on tables. This is likely due to high logistics costs for heavy items. We need to raise prices on tables or remove them from the assortment.

### 2. Decomposition Tree
*   **What it shows:** How total sales (17.65M) are distributed by region, and then by category.
*   **Analytical Conclusion:** Allows visualizing the sales structure in each region. For example, in the `Central` region, Technology sales amount to 2.09M. The visual confirms that demand structure is roughly consistent across all regions.

### 3. Bar Chart "Top 10 Products by Profit"
*   **What it shows:** Ranking of specific items (SKUs) by absolute profit.
*   **Analytical Conclusion:**
    *   Leader — *Canon imageCLASS* (printer/copier).
    *   The Top 10 products are almost exclusively **Technology**.
    *   This confirms the matrix conclusion: Technology is our most valuable asset, generating real profit for the company.

---

## Page 3: Customer Insights

Analysis of buyer behavior and identification of "toxic" clients.

### 1. Scatter Plot "Sales vs Profit" (Profitability Matrix)
*   **What it shows:** Correlation between Revenue (X-axis) and Profit (Y-axis). Each dot is a client. Colors represent segments.
*   **Analytical Conclusion:**
    *   Generally a positive trend (more bought -> more profit).
    *   **Anomaly (Bottom Right Corner):** There are clients far to the right (huge purchases) but **below zero** on the Y-axis.
    *   **Example:** A client who bought 100k+ but generated a loss.
    *   **Reason:** Likely, these clients buy only deeply discounted items (promo-hunters) or frequently return goods.

### 2. Histogram "Order Count by Receipt Range"
*   **What it shows:** Distribution of order counts by receipt value ranges.
*   **Analytical Conclusion:**
    *   The graph has a "long tail" shape.
    *   **Small orders dominate:** The highest bar represents receipts from **0 to $250**.
    *   Orders over $1000 are extremely rare.
    *   This characterizes the business as **Mass Market** with a low transaction value. We earn on volume, not VIP sales.

### 3. Table "Customer Details"
*   **What it shows:** Specific figures by customer to confirm hypotheses from the Scatter Plot.
*   **Analytical Conclusion (Specific Cases):**
    *   **Adrian Barton:** Ideal client. Bought **130k**, profit **49k**.
    *   **Aaron Smayling:** "Toxic" client. Bought **21k**, but brought a loss of **-1.7k**.
    *   **Recommendation:** Managers must be forbidden from giving personal discounts to Aaron Smayling and similar clients from the "bottom zone" of the chart.

---

### Final Summary
The report showed that **Superstore** is a seasonal mass-market business that is stagnating (0.04% growth). The main problems are the unprofitability of the "Furniture" category (especially Tables) and the presence of a group of unprofitable large clients. Growth points: optimizing furniture logistics and stimulating sales in Q1.
