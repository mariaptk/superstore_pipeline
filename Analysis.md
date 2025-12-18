# Part 1. Analytics Approach (Data Modeling Method)

## How I Built the Analytics

First, I uploaded the data according to the requirements for the task.

**Star Schema:**
- All the hard work with data was done in SQL (Mart layer)
- In Power BI, I loaded ready-to-use fact table (fact_sales) and dimension tables (dim_products, dim_customers)
- This made the report fast and simple

**Point-in-Time Logic (SCD2):**
- The special feature: sales connect to the region where the customer lived at purchase time
- Not where they live now
- This makes historical data accurate

**Calendar Table:**
- I created a separate date table using DAX
- This allows correct time comparisons (like last year vs this year)

# Part 2. DAX Measures

I didn't use simple field dragging. I created special measures for flexibility.

## 1. Basic Metrics: SUM vs SUMX
**Measure:** Total Sales = SUM(fact_sales[sales])
**Measure:** Total Sales (Iterative) = SUMX(fact_sales, fact_sales[sales])

- SUM is fast - main measure
- SUMX was required in the task. It goes row by row
- In real life, you use it when you need to calculate something for each row before adding

## 2. Relative Metrics (Profit Margin)
**Measure:** Profit Margin % = DIVIDE([Total Profit], [Total Sales], 0)

- Big profit numbers can be misleading
- Margin shows real business efficiency
- How many cents of profit we get from each dollar of sales

## 3. Time Analysis
**Measures:** Sales YTD (year-to-date), Sales SPLY (same period last year)
**Measure:** Sales YoY % (year-over-year growth)

- Business needs to know: "Are we growing or falling?"
- Example: 0.17% growth (in your screenshot) shows stagnation

## 4. Context Manipulation
**Measure:** % of Total Sales = DIVIDE([Total Sales], CALCULATE([Total Sales], ALL(fact_sales)))

- Shows category contribution to total
- Ignores filters
- Example: Technology gives 35% of all company revenue

# Part 3. Detailed Analysis Results

## Page 1: Sales Overview

**Seasonality:**
- Sales peaks: September, November, December (holidays, Black Friday)
- Low sales: January, February
- **Recommendation:** Boost marketing in Q1

**Geography (SCD2):**
- Map shows correct historical data
- If customer moved from California to Texas, old sales stay in California
- West and East coasts are main markets

## Page 2: Product Performance

**Leaders:**
- Technology category: $6.2M revenue, 18.65% margin ("cash cow")

**Problem (Insight!):**
- Furniture category: $5.7M revenue, but only 3.43% margin
- Tables subcategory is the problem
- **Conclusion:** Delivery costs eat profit. Need to review prices or stop unprofitable models

## Page 3: Customer Insights

**Scatter Plot:**
- Clear rule: more sales = more profit
- **Anomaly:** Some customers have big sales (over $100k) but negative profit (loss up to $15k)
- **Conclusion:** These are "toxic" VIP customers. They buy with big discounts or return often. Need to change terms.

**Histogram:**
- Most orders are small (under $500)
- Orders over $1500 are rare
- **Conclusion:** We are in mass market. Need to increase purchase frequency or raise average order to at least $700

# Summary

"In Power BI, I focused on finding business insights, not just showing tables.
- Used SCD Type 2 for historically correct sales map
- Found furniture margin problem
- Discovered unprofitable customers through Scatter Plot
- Built with Star Schema and advanced DAX measures"