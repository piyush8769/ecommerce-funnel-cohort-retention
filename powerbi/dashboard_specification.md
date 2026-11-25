# E-Commerce Product Funnel, Cohort Retention & RFM Analytics
## Power BI Dashboard Production Specification & Data Verification Report

---

## 1. Executive Summary & Core Metrics

This document outlines the architecture, data model, DAX measures, visual layouts, and analytical findings implemented in the production Power BI reporting suite: **`Customer_Retention_Analytics.pbix`**.

The dashboard models over **1,067,000+ raw e-commerce transaction lines** (sanitized to **779,425 verified transactions**), tracking **36,969 unique orders** across **5,878 distinct customer accounts** from an international direct-to-consumer (D2C) retailer spanning December 2009 through December 2011.


## 2. Semantic Data Model & Relational Schema

The semantic model in Power BI is built on an optimized Star/Snowflake Schema to support dynamic cross-filtering, slicing, and drill-through analysis:

```
                  ┌──────────────────────────────┐
                  │      Fact_Transactions       │
                  │   (779,425 Granular Rows)    │
                  ├──────────────────────────────┤
                  │ Invoice                      │
                  │ StockCode                    │
                  │ Description                  │
                  │ Quantity                     │
                  │ InvoiceDate                  │
                  │ Price                        │
                  │ CustomerID          (FK)     │──┐
                  │ Country                      │  │
                  │ InvoiceMonth                 │  │
                  │ TotalRevenue                 │  │
                  └──────────────────────────────┘  │
                                                    │ Many-to-One (*:1)
                                                    │ Both Directions
                                                    ▼
                  ┌──────────────────────────────┐
                  │        Dim_Customers         │
                  │     (5,878 Customer Grain)   │
                  ├──────────────────────────────┤
                  │ CustomerID          (PK)     │◀─┐
                  │ TotalOrders                  │  │
                  │ TotalSpend                   │  │
                  │ TotalItems                   │  │
                  │ FirstPurchaseDate            │  │
                  │ LastPurchaseDate             │  │
                  │ TenureDays                   │  │
                  │ AvgOrderValue                │  │
                  │ LifecycleStage               │  │
                  │ LifecycleSortOrder           │  │ One-to-One (1:1)
                  │ TenureBand                   │  │ Both Directions
                  └──────────────────────────────┘  │
                                                    ▼
                  ┌──────────────────────────────┐
                  │           Dim_RFM            │
                  │     (5,878 Behavioral Grain) │
                  ├──────────────────────────────┤
                  │ CustomerID          (PK)     │
                  │ Recency                      │
                  │ Frequency                    │
                  │ Monetary                     │
                  │ R_Score (1-5)                │
                  │ F_Score (1-5)                │
                  │ M_Score (1-5)                │
                  │ RFM_Code (e.g. 555)          │
                  │ RFM_Avg                      │
                  │ Segment                      │
                  │ SegmentSortOrder             │
                  └──────────────────────────────┘

  ┌─────────────────────────────────┐       ┌─────────────────────────────────┐
  │           Dim_Cohort            │       │           Dim_Funnel            │
  │     (Unpivoted Retention)       │       │    (4-Tier Lifecycle Table)     │
  ├─────────────────────────────────┤       ├─────────────────────────────────┤
  │ CohortMonth                     │       │ LifecycleStage                  │
  │ MonthIndex (0 to 24)            │       │ CustomerCount                   │
  │ RetentionRate (%)               │       │ RevenueShare_%                  │
  └─────────────────────────────────┘       └─────────────────────────────────┘
```

---

## 3. Production DAX Measure Dictionary

All core portfolio calculations are stored inside a dedicated `_Measures` table:

### 3.1 Volume & Revenue Measures
```dax
// Total Disbursed Gross Revenue across line items
Total Revenue = 
SUM(Fact_Transactions[TotalRevenue])

// Distinct Completed Invoices (Excluding returns/cancellations)
Total Orders = 
DISTINCTCOUNT(Fact_Transactions[Invoice])

// Total Unique Active Customer Accounts
Total Customers = 
DISTINCTCOUNT(Fact_Transactions[CustomerID])

// Average Order Value (Basket Size)
Average Order Value = 
DIVIDE([Total Revenue], [Total Orders], 0)

// Customer Lifetime Value (CLV Benchmark)
Customer Lifetime Value = 
DIVIDE([Total Revenue], [Total Customers], 0)
```

### 3.2 Funnel & Churn Dynamics
```dax
// Repeat Customer Rate (Customers with 2+ completed orders)
Repeat Customer Rate = 
VAR RepeatCust = 
    CALCULATE(
        DISTINCTCOUNT(Dim_Customers[CustomerID]),
        Dim_Customers[TotalOrders] > 1
    )
RETURN
    DIVIDE(RepeatCust, [Total Customers], 0)

// One-Time Churn Rate (Bottleneck single transaction buyers)
One Time Churn Rate = 
VAR SingleBuyers = 
    CALCULATE(
        DISTINCTCOUNT(Dim_Customers[CustomerID]),
        Dim_Customers[TotalOrders] = 1
    )
RETURN
    DIVIDE(SingleBuyers, [Total Customers], 0)
```

### 3.3 RFM Behavioral Measures
```dax
// Gross Spend generated exclusively by Champion accounts
Champions Revenue = 
CALCULATE(
    SUM(Dim_RFM[Monetary]),
    Dim_RFM[Segment] = "Champions"
)

// Inactive capital at risk of permanent attrition (>90 days lapsed)
At Risk Capital = 
CALCULATE(
    SUM(Dim_RFM[Monetary]),
    Dim_RFM[Segment] = "At Risk / High Value Churn"
)

// Highly engaged core customer count (R_Score >= 4 and F_Score >= 4)
Core Retained Count = 
CALCULATE(
    COUNTROWS(Dim_RFM),
    Dim_RFM[R_Score] >= 4 && Dim_RFM[F_Score] >= 4
)
```

---

## 4. Multi-Page Architecture & Visual Walkthrough

### Page 1: Home (E-Commerce D2C Growth Command Center)
* **KPI Ribbon (5 Top Cards):**
  1. `Total Revenue`: **£1,73,74,804.25** (Emerald Green accent)
  2. `Total Orders`: **36,969** (Indigo accent)
  3. `Total Customers`: **5,878** (Teal accent)
  4. `Average Order Value`: **£469.98** (Amber accent)
  5. `One Time Churn Rate`: **27.61%** (Coral Red accent)
* **Slicer Ribbon:**
  * Dropdown: `Country`
  * Dropdown: `LifecycleStage`
  * Slider: `InvoiceDate` Range (01-12-2009 to 01-12-2011)
* **Visual 1 (Area Chart - Monthly Gross Revenue Velocity):**
  * X-Axis: `InvoiceMonth` (January through December)
  * Values: `Total Revenue`
  * Trend highlights: Solid baseline through Q1-Q3 with seasonal spike peaking in **November (£2.32M)** before year-end.
* **Visual 2 (Horizontal Bar Chart - Top International Markets):**
  * Category: `Country`
  * Values: `Total Revenue`
  * Dominance: **United Kingdom (£14.4M / 82.8%)**, followed by EIRE (£0.6M), Netherlands (£0.6M), Germany (£0.4M), France (£0.3M).
* **Navigation Header:** Quick-jump buttons to `Funnel`, `Cohort`, and `RFM`.

---

### Page 2: Funnel & Pareto (Customer Lifecycle Drop-off Analysis)
* **Visual 1 (Customer Conversion Funnel):**
  * Displays account volume by `LifecycleStage`:
    * `1. One-Time Buyer (1)`: 1,623 accounts (Top of Funnel drop-off)
    * `2. Repeat Buyer (2)`: 944 accounts (Validation stage)
    * `3. Loyal Buyer (3-5)`: 1,510 accounts (Recurring mid-tier)
    * `4. Champion (6+)`: 1,801 accounts (Core high-value engine)
* **Visual 2 (Donut Chart - RFM Customer Account Distribution):**
  * Slices: Hibernating/Churned (25.91%), Loyal (23.92%), Champions (22.07%), At Risk (14.02%), Potential Loyalists (11.23%), Recent New (2.86%).
  * Total Center Callout: **5,878 accounts**.
* **Visual 3 (Granular Account Audit Table):**
  * Columns: `CustomerID`, `LifecycleStage`, `Orders`, `Spend`, `AOV`, `Tenure (Days)`.
  * In-cell conditional data bars highlighting individual customer spend volume.
* **Navigation Header:** Navigation pills back to `Home`, `Cohort`, and `RFM`.

---

### Page 3: Cohort Retention Lab (Longitudinal Decay Analysis)
* **KPI Header Cards:**
  1. `Month-1 Cliff`: **21.8%** (Red warning callout — critical initial drop-off)
  2. `30-Day Window`: **58.4%** (Amber callout — second order repurchase velocity)
  3. `Residual Baseline`: **14% – 17%** (Blue callout — long-term sticky loyalty)
  4. `Count of CohortMonth`: **25 Cohorts** tracked longitudinally.
* **Visual 1 (Cohort Retention Matrix Heatmap):**
  * Rows: Acquisition Months (`January` to `December` cohorts)
  * Columns: `MonthIndex` (Elapsed intervals M0 through M24)
  * Heatmap gradient: Green (`100%` at M0) scaling down to soft salmon/red highlighting decay rate.
* **Visual 2 (Mean Retention Decay Curve):**
  * X-Axis: `MonthIndex` (0 to 24)
  * Y-Axis: `Average RetentionRate`
  * Displays the steep cliff from 100% to 21.8% in Month 1, stabilizing into the flat 14–17% residual curve from Month 4 onwards.
* **Navigation Header:** Navigation pills back to `Home`, `Funnel`, and `RFM`.

---

### Page 4: RFM Segmentation Matrix (Behavioral Quintile Deep Dive)
* **KPI Header Cards:**
  1. `Champions Revenue`: **£11.86M** (Top 22% customers driving 68.3% of RFM monetary spend)
  2. `Average of Recency`: **201.33 Days** (Inactivity benchmark across total base)
  3. `At Risk Capital`: **£1.59M** (High-lifetime value customers currently inactive)
  4. `Core Retained Count`: **1,482 Accounts** (Customers with R_Score ≥ 4 and F_Score ≥ 4)
* **Visual 1 (5×5 R-Score × F-Score Heatmap Matrix):**
  * Rows: `R_Score` (1 to 5, sorted descending so R5 is at top)
  * Columns: `F_Score` (1 to 5)
  * Values: `DistinctCount of CustomerID`
  * Highlights:
    * **R5 × F5 Cell**: Deep green callout showing **571 elite champions** (most recent, highest frequency).
    * **R1 × F1 Cell**: Red/yellow callout showing **513 deeply churned buyers** (long-term inactive, single order).
* **Visual 2 (Behavioral Cluster Scatter Plot):**
  * X-Axis: `Average of Recency` (0 to 500+ Days)
  * Y-Axis: `Average of Frequency` (0 to 20 Orders)
  * Bubble Size: `Average of Monetary` (Gross Spend)
  * Legend: `Segment`
  * Clearly separates the high-frequency/recent Champion cluster from the high-recency At-Risk and Hibernating clusters.
* **Visual 3 (RFM Behavioral Tier Profiles & Benchmark Table):**
  * Columns: `Segment`, `CustomerID` (Count), `Avg Recency (Days)`, `Avg Orders`, `Average of Monetary`, `Sum of Monetary`.
  * In-cell conditional green data bars on Total Monetary spend and colored font indicators on Recency days.
* **Visual 4 (Gross Spend by Segment Horizontal Bar Chart):**
  * Proves the Pareto distribution: Champions (£11.9M), Loyal (£2.7M), At Risk (£1.6M), Hibernating (£0.7M), Potential Loyalists (£0.5M), Recent New (£0.1M).
* **Navigation Header:** Navigation pills back to `Home`, `Funnel`, and `Cohort`.

