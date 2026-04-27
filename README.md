# Global Superstore Sales & Profitability Analysis

## Overview
This project explores the Global Superstore dataset (51,290 rows) using MySQL to identify highly profitable markets, track year-over-year growth, and perform root-cause analysis on profit anomalies. The analysis moves from high-level market evaluations down to granular sub-category investigations.

**Tools:** MySQL, CTEs, Window Functions, STR_TO_DATE

## Key Insights
* **Market Consolidation:** EMEA was eliminated early in the analysis due to poor profit margins and low profit-per-order ratios compared to the other 6 markets.
* **Explosive Growth in Africa:** The African market saw a massive 124% year-over-year profit growth in 2013, solidifying it as a high-value region alongside APAC.
* **APAC Furniture Drag:** Despite overall strength in APAC, the 'Furniture' category flatlined in 2014. Drill-down analysis revealed that the 'Tables' sub-category was consistently operating at a loss, dragging down the entire category's margin.
* **Africa 2012 Profit Anomaly:** A noticeable profit drop in Africa's Technology sector in 2012 was isolated to the 'Machines' sub-category. Hypothesis testing showed this was not driven by excessive discounting (discounts were actually lower that year), pointing to external supply chain or market shocks. The market structurally recovered in 2013.

## Technical Skills Demonstrated
* **Data Cleaning & Standardization:** Safe column additions and `STR_TO_DATE` conversions without mutating raw source data.
* **Advanced Aggregations:** Complex `GROUP BY` rollups for revenue, profit margins, and average order values.
* **Window Functions:** Utilizing CTEs and `LAG()` to calculate precise YoY growth percentages across different partitions.
* **Hypothesis Testing in SQL:** Using querying to isolate root causes of financial dips by cross-referencing sub-categories with discount rates.

## Project Structure
The analysis is structured logically within the SQL script:
1. **Overview & Market Rankings** — High-level health checks and market filtering.
2. **Data Preparation** — Converting string-based dates to proper temporal formats.
3. **Trend Analysis** — YoY profit growth using Window Functions.
4. **Deep Dives & Root Cause** — Category breakdowns and hypothesis testing for specific revenue drops.

## How to Run
1. Create a MySQL database named `global_superstore`.
2. Import the raw dataset (`global_superstore_orders.csv`) into a table named `sales`.
3. Execute `analysis.sql` to replicate the data cleaning, transformations, and analytical queries.

## Dataset
Raw dataset included in this repository (`global_superstore_orders.csv`).
