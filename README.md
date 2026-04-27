# 🌍 Global Superstore Sales Analysis
> End-to-end SQL analysis on **51,290 rows** of global retail data to identify the most profitable markets for business expansion.

---

## 📦 Dataset

| Property | Detail |
|---|---|
| **Rows** | 51,290 orders |
| **Markets** | APAC, EU, US, LATAM, Africa, Canada, EMEA |
| **Key Columns** | Sales, Profit, Discount, Category, Sub-Category, Market, Order Date |
| **Time Period** | 2011 – 2014 |

---

## 🛠️ Tools & Techniques

- **MySQL** — all querying and analysis
- **Aggregate functions** — `SUM`, `COUNT`, `AVG`, `ROUND`
- **Window functions** — `LAG() OVER (PARTITION BY Market ORDER BY Year)` for YoY growth
- **CTEs** — `WITH` clause for clean, multi-step queries
- **Date handling** — `STR_TO_DATE`, `YEAR()`, `ALTER TABLE` with safe update controls
- **Multi-level GROUP BY** — Market → Category → Sub-Category

---

## 🔍 Analysis Layers

### Layer 1 — Market-Level Profitability

Ran a comprehensive market comparison across all 7 markets: Total Orders, Total Revenue, Total Profit, Profit Margin %, and Profit Per Order.

```sql
SELECT Market,
    COUNT(*) AS Total_Orders,
    ROUND(SUM(Sales),2) AS Total_Revenue,
    ROUND(SUM(Profit),2) AS Total_Profit,
    ROUND(AVG(Sales),2) AS AVG_Total_Sales,
    ROUND(SUM(Profit)/SUM(Sales)*100,2) AS Profit_Margin,
    ROUND(SUM(Profit)/COUNT(*),2) AS Profit_Per_Order
FROM sales
GROUP BY Market
ORDER BY Profit_Margin DESC;
```

**Key Findings:**

| Market | Insight |
|---|---|
| **APAC** | Highest total revenue and profit. 11,002 orders. 2nd highest profit per order. Clear scale leader. |
| **Canada** | Highest profit margin (26.62%) and profit per order (₹46.4). Only 384 orders — hyper-efficient but tiny volume. |
| **US / EU** | Strong margins (~12%), large volume, proven markets. |
| **Africa / LATAM** | Solid margins, growing volume. |
| **EMEA** | Weakest across all metrics. ❌ Eliminated from further analysis. |

---

### Layer 2 — Year-over-Year Trend Analysis

Tracked profit growth from 2011–2014 for all 6 remaining markets. Every market showed growth — no declining trends.

```sql
SELECT Market,
    YEAR(Order_Date_Clean) AS Year,
    ROUND(SUM(Profit),2) AS Total_Profit
FROM sales
WHERE Market IN ('US','EU','APAC','Canada','Africa','LATAM')
GROUP BY Market, YEAR(Order_Date_Clean)
ORDER BY Market;
```

| Market | 2011 | 2012 | 2013 | 2014 |
|---|---|---|---|---|
| APAC | ₹83,031 | ₹89,410 | ₹1,23,103 | ₹1,40,454 |
| EU | ₹61,625 | ₹83,984 | ₹98,275 | ₹1,28,944 |
| US | ₹49,543 | ₹61,618 | ₹81,726 | ₹93,507 |
| Africa | ₹10,944 | ₹11,908 | ₹26,687 | ₹39,331 |
| LATAM | ₹36,708 | ₹50,184 | ₹61,415 | ₹73,334 |
| Canada | ₹1,807 | ₹4,887 | ₹5,129 | ₹5,993 |

---

### Layer 3 — LAG Window Function (YoY Growth %)

Used a CTE + `LAG()` window function to calculate precise year-over-year growth percentages. **Africa's growth story changed the final recommendation.**

```sql
WITH yearly_profit AS (
    SELECT Market,
        YEAR(Order_Date_Clean) AS Year,
        ROUND(SUM(Profit),2) AS Total_Profit
    FROM sales
    WHERE Market IN ('US','EU','APAC','Canada','Africa','LATAM')
    GROUP BY Market, Year
)
SELECT Market, Year, Total_Profit,
    LAG(Total_Profit) OVER(PARTITION BY Market ORDER BY Year) AS Prev_Year_Profit,
    ROUND(
        (Total_Profit - LAG(Total_Profit) OVER (PARTITION BY Market ORDER BY Year))
        / LAG(Total_Profit) OVER (PARTITION BY Market ORDER BY Year) * 100, 2
    ) AS YoY_Growth_Pct
FROM yearly_profit;
```

**Africa Growth Numbers:**

| Year | YoY Growth |
|---|---|
| 2012 | +8.8% |
| 2013 | **+124%** — market doubled in one year |
| 2014 | +47% |

> Africa's 124% profit growth in 2013 followed by +47% in 2014 shifted the final recommendation from APAC + Canada → **APAC + Africa**.

---

### Layer 4 — Category Breakdown (APAC & Africa)

**APAC:**
- **Technology** — strong, consistent growth every year (₹41k → ₹62k)
- **Office Supplies** — steady growth, minor 2012 dip then recovered strongly
- **Furniture** — grew well through 2013, profit flatlined in 2014 despite higher sales ⚠️ flagged for investigation

**Africa:**
- **Furniture** — steady growth all 4 years
- **Office Supplies** — steady growth all 4 years
- **Technology** — strong overall growth, but 2012 showed profit drop despite higher sales ⚠️ flagged for investigation

---

### Layer 5 — Sub-Category Deep Dives & Root Cause Investigation

#### APAC Furniture — Why did profit flatline in 2014?

Broke down APAC Furniture into sub-categories by year. **Tables** was the culprit — consistently loss-making or near-zero, dragging down the entire category's margin even as Chairs and Bookcases grew.

**Inventory Strategy:** Minimize Tables stock. Keep a small anchor inventory — customers buying Tables often also buy Chairs (loss-leader effect). Invest heavily in Chairs and Bookcases which carry real margin.

---

#### Africa Technology — Why did profit drop in 2012 despite higher sales?

Tested the discount hypothesis on the **Machines** sub-category:

```sql
SELECT YEAR(Order_Date_Clean) AS Year,
    ROUND(AVG(Discount)*100,2) AS Avg_Discount_Pct,
    ROUND(SUM(Profit),0) AS Total_Profit,
    COUNT(*) AS Total_Sales
FROM sales
WHERE Market = 'Africa'
    AND Category = 'Technology'
    AND `Sub-Category` = 'Machines'
GROUP BY Year
ORDER BY Year;
```

| Year | Avg Discount % | Total Profit | Total Sales |
|---|---|---|---|
| 2011 | 20.71% | ₹1,834 | 42 |
| 2012 | 20.26% | ₹-1,125 | 38 |
| 2013 | 16.78% | ₹2,924 | 59 |
| 2014 | 12.5% | ₹2,315 | 68 |

**Result:** Discounts were actually *lower* in 2012 — not the cause. The cause lies outside the available dataset (supply chain disruption, market shock, etc.). The key signal is that the market fully recovered in 2013 and continued growing in 2014. A market that bounces back from a shock demonstrates structural resilience, not weakness.

**Africa Technology Sub-Category Summary:**
- **Copiers & Phones** — star sub-categories, growing every year
- **Machines 2012** — one-time anomaly, fully recovered by 2013
- **Overall Africa Technology profit** — nearly tripled from 2011 to 2014

---

## ✅ Final Recommendation

| | PRIMARY — APAC | EXPANSION — AFRICA |
|---|---|---|
| **Scale** | 11,002 orders — proven scale | 4,587 orders — fastest growing |
| **Profit** | Highest absolute profit generator | Profit nearly 4x from 2011–2014 |
| **Categories** | Clear inventory strategy per category | All 3 categories growing |
| **Stability** | Consistent year-on-year growth | Resilient after 2012 anomaly |

**Portfolio Logic:** APAC is the safe, high-probability scale bet. Africa is the high-efficiency, high-growth emerging market. Together they balance risk and reward — one guarantees returns, the other unlocks a new frontier with greater profit potential.

---

## ⚠️ Limitations

- The 2012 Africa Machines profit drop could not be explained by discount data alone. Returns data, supplier costs, or external market factors would be needed to fully diagnose it.
- Dataset covers only 2011–2014. More recent data would strengthen trend conclusions.
- No customer segmentation data — analysis is at order and market level only.

---

## 💡 Key Takeaways

1. **Surface metrics lie** — Total profit alone would point to APAC and ignore Africa entirely. Margin + growth rate + trend analysis tells the full story.
2. **Sample size matters** — Partial data can completely reverse conclusions. Always validate on the full dataset before making any recommendation.
3. **One bad year ≠ structural problem** — Africa Machines 2012 looked alarming until recovery data proved otherwise. Context is everything.
4. **Window functions unlock real insight** — `LAG()` over partitioned data turned raw profit numbers into a growth story that changed the entire final recommendation.

---

*Global Superstore Sales Analysis • MySQL • 51,290 rows • 2011–2014*

