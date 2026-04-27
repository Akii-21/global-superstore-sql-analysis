-- ============================================================
-- Global Superstore Sales Analysis
-- Tool: MySQL
-- Dataset: 51,290 rows | 7 Markets | 2011-2014
-- Author: Aakash Saini
-- ============================================================

CREATE DATABASE global_superstore;
USE global_superstore;


-- ============================================================
-- SECTION 1: OVERVIEW
-- Quick sanity check on total rows and overall business health
-- ============================================================

SELECT COUNT(*) AS Total_Rows FROM sales;

SELECT
    ROUND(SUM(Sales), 2)                    AS Total_Revenue,
    ROUND(SUM(Profit), 2)                   AS Total_Profit,
    COUNT(*)                                AS Total_Orders,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS Profit_Margin_Pct
FROM sales;


-- ============================================================
-- SECTION 2: MARKET-LEVEL PROFITABILITY
-- Compare all 7 markets across key metrics to identify
-- which markets are worth investing in
-- ============================================================

-- 2a. Simple profit ranking by market
SELECT
    Market,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales
GROUP BY Market
ORDER BY Total_Profit DESC;


-- 2b. Full market comparison:
-- Orders, Revenue, Profit, Margin %, and Profit Per Order
-- This is the primary filter — EMEA was eliminated here
SELECT
    Market,
    COUNT(*)                                    AS Total_Orders,
    ROUND(SUM(Sales), 2)                        AS Total_Revenue,
    ROUND(SUM(Profit), 2)                       AS Total_Profit,
    ROUND(AVG(Sales), 2)                        AS Avg_Order_Value,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)   AS Profit_Margin_Pct,
    ROUND(SUM(Profit) / COUNT(*), 2)            AS Profit_Per_Order
FROM sales
GROUP BY Market
ORDER BY Profit_Margin_Pct DESC;


-- ============================================================
-- SECTION 3: DATE COLUMN PREPARATION
-- Order Date is stored as text (string) — converting it to
-- a proper DATE type for time-series analysis.
-- A new column is added as a safety net so the original
-- data is never overwritten.
-- ============================================================

ALTER TABLE sales
ADD COLUMN Order_Date_Clean DATE;

-- Temporarily disable safe update mode to allow the UPDATE
SET SQL_SAFE_UPDATES = 0;

UPDATE sales
SET Order_Date_Clean = STR_TO_DATE(`Order Date`, '%d-%m-%Y');

-- Re-enable safe update mode immediately after
SET SQL_SAFE_UPDATES = 1;


-- ============================================================
-- SECTION 4: YEAR-OVER-YEAR TREND ANALYSIS
-- Track profit growth from 2011-2014 for the 6 viable markets
-- (EMEA excluded after Section 2 analysis)
-- ============================================================

SELECT
    Market,
    YEAR(Order_Date_Clean) AS Year,
    ROUND(SUM(Profit), 2)  AS Total_Profit
FROM sales
WHERE Market IN ('US', 'EU', 'APAC', 'Canada', 'Africa', 'LATAM')
GROUP BY Market, YEAR(Order_Date_Clean)
ORDER BY Market, Year;


-- ============================================================
-- SECTION 5: LAG WINDOW FUNCTION — YoY GROWTH %
-- Using CTE + LAG() to calculate precise year-over-year
-- growth percentages per market.
-- Africa's 124% growth in 2013 changed the final recommendation.
-- ============================================================

WITH yearly_profit AS (
    SELECT
        Market,
        YEAR(Order_Date_Clean)  AS Year,
        ROUND(SUM(Profit), 2)   AS Total_Profit
    FROM sales
    WHERE Market IN ('US', 'EU', 'APAC', 'Canada', 'Africa', 'LATAM')
    GROUP BY Market, Year
)
SELECT
    Market,
    Year,
    Total_Profit,
    LAG(Total_Profit) OVER (PARTITION BY Market ORDER BY Year) AS Prev_Year_Profit,
    ROUND(
        (Total_Profit - LAG(Total_Profit) OVER (PARTITION BY Market ORDER BY Year))
        / LAG(Total_Profit) OVER (PARTITION BY Market ORDER BY Year) * 100,
    2) AS YoY_Growth_Pct
FROM yearly_profit;


-- ============================================================
-- SECTION 6: CATEGORY BREAKDOWN — APAC & AFRICA
-- Drilling into category-level performance for the two
-- recommended markets to understand what is driving growth
-- ============================================================

-- 6a. APAC — Category breakdown by year
SELECT
    Market,
    Category,
    YEAR(Order_Date_Clean)      AS Year,
    COUNT(*)                    AS Total_Orders,
    ROUND(SUM(Profit), 0)       AS Total_Profit
FROM sales
WHERE Market = 'APAC'
GROUP BY Market, Category, Year
ORDER BY Category, Year;


-- 6b. Africa — Category breakdown by year
SELECT
    Market,
    Category,
    YEAR(Order_Date_Clean)      AS Year,
    COUNT(*)                    AS Total_Orders,
    ROUND(SUM(Profit), 0)       AS Total_Profit
FROM sales
WHERE Market = 'Africa'
GROUP BY Market, Category, Year
ORDER BY Category, Year;


-- ============================================================
-- SECTION 7: SUB-CATEGORY DEEP DIVES
-- Root cause investigation on two flagged anomalies:
-- 1. APAC Furniture profit flatline in 2014
-- 2. Africa Technology profit drop in 2012
-- ============================================================

-- 7a. APAC Furniture — Sub-category breakdown
-- Finding: 'Tables' was consistently loss-making,
-- dragging down the entire Furniture category margin
SELECT
    Market,
    `Sub-Category`,
    YEAR(Order_Date_Clean)      AS Year,
    ROUND(SUM(Profit), 0)       AS Total_Profit,
    COUNT(*)                    AS Total_Orders
FROM sales
WHERE Market = 'APAC'
  AND Category = 'Furniture'
GROUP BY Market, `Sub-Category`, Year
ORDER BY `Sub-Category`, Year;


-- 7b. Africa Technology — Sub-category breakdown
-- Finding: 'Machines' caused the 2012 dip
SELECT
    Market,
    `Sub-Category`,
    YEAR(Order_Date_Clean)      AS Year,
    ROUND(SUM(Profit), 0)       AS Total_Profit,
    COUNT(*)                    AS Total_Orders
FROM sales
WHERE Market = 'Africa'
  AND Category = 'Technology'
GROUP BY Market, `Sub-Category`, Year
ORDER BY `Sub-Category`, Year;


-- ============================================================
-- SECTION 8: ROOT CAUSE — AFRICA MACHINES 2012
-- Testing the discount hypothesis:
-- Were higher discounts responsible for the 2012 loss?
-- Result: Discounts were actually LOWER in 2012.
-- Cause remains outside this dataset (supply chain / market shock).
-- Market recovered fully in 2013 — confirmed structural resilience.
-- ============================================================

SELECT
    YEAR(Order_Date_Clean)          AS Year,
    ROUND(AVG(Discount) * 100, 2)   AS Avg_Discount_Pct,
    ROUND(SUM(Profit), 0)           AS Total_Profit,
    COUNT(*)                        AS Total_Orders
FROM sales
WHERE Market = 'Africa'
  AND Category = 'Technology'
  AND `Sub-Category` = 'Machines'
GROUP BY Year
ORDER BY Year;