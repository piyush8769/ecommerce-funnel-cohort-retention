# Power BI Business Intelligence Specification

### Project: E-Commerce Customer Funnel & Cohort Retention Dashboard

---

## 1. Architecture & Data Model

The data model is structured in a **Star Schema** to optimize query performance and dynamic DAX evaluations.

### Tables & Roles:
- **`retail_clean` (Fact Table):** Granular line-item transactions containing `Invoice`, `StockCode`, `InvoiceDate`, `Quantity`, `Price`, `TotalRevenue`, and `CustomerID`.
- **`customer_summary` (Dimension Table):** Customer grain attributes containing `CustomerID`, `TotalOrders`, `TotalSpend`, `TenureDays`, and `LifecycleStage`.
- **`cohort_counts` (Dimension Table):** Aggregated cohort activity pairs containing `CohortMonth`, `CohortIndex`, and `ActiveCustomers`.

### Relationships:
- `customer_summary[CustomerID]` `(1)` ---> `(*) retail_clean[CustomerID]` (Single directional filter)
- `cohort_counts[CohortMonth]` `<--->` Temporal dimension (if Date Table is implemented)

---

## 2. DAX Measure Dictionary

### 2.1 Core Revenue & Volume Measures

```dax
Total Revenue = 
SUM(retail_clean[TotalRevenue])
```

```dax
Total Orders = 
DISTINCTCOUNT(retail_clean[Invoice])
```

```dax
Total Customers = 
DISTINCTCOUNT(retail_clean[CustomerID])
```

```dax
Average Order Value (AOV) = 
DIVIDE([Total Revenue], [Total Orders], 0)
```

```dax
Customer Lifetime Value (CLV) = 
DIVIDE([Total Revenue], [Total Customers], 0)
```

### 2.2 Retention & Recurrence Measures

```dax
Repeat Customer Rate = 
VAR RepeatCustomers = 
    CALCULATE(
        DISTINCTCOUNT(customer_summary[CustomerID]),
        customer_summary[TotalOrders] > 1
    )
RETURN
    DIVIDE(RepeatCustomers, [Total Customers], 0)
```

```dax
One-Time Churn Rate = 
VAR SingleBuyers = 
    CALCULATE(
        DISTINCTCOUNT(customer_summary[CustomerID]),
        customer_summary[TotalOrders] = 1
    )
RETURN
    DIVIDE(SingleBuyers, [Total Customers], 0)
```

---

## 3. Visual Layout & Report Specifications

### Page 1: Executive Overview
- **Header:** Platform Executive Overview & Realized Gross Revenue
- **KPI Cards (Top Bar):** `Total Revenue`, `Total Orders`, `Total Customers`, `Average Order Value (AOV)`
- **Visual 1 (Area / Line Chart):** Monthly Realized Gross Revenue over time (`retail_clean[InvoiceDate]` vs `[Total Revenue]`).
- **Visual 2 (Clustered Bar Chart):** Top 10 International Revenue Markets (`retail_clean[Country]` vs `[Total Revenue]`).
- **Slicers:** Date Range Picker, Country Multi-Select.

### Page 2: Customer Conversion Funnel
- **Header:** Lifecycle Tiering & Funnel Drop-off Analysis
- **Visual 1 (Funnel Visual):** Customer Conversion Volume (`funnel_summary[LifecycleStage]` vs `Sum of CustomerCount`).
- **Visual 2 (100% Stacked Bar Chart):** Customer Share vs Revenue Share comparison across lifecycle stages (`customer_summary[LifecycleStage]`).
- **Visual 3 (Data Table):** Top 25 Highest-Value Accounts (`CustomerID`, `TotalOrders`, `TotalSpend`, `TenureDays`, `LifecycleStage`).

### Page 3: Cohort Retention Heatmap
- **Header:** Longitudinal Cohort Retention Matrix (Decay Curves)
- **Visual 1 (Matrix Visual):** 
  - **Rows:** `CohortMonth`
  - **Columns:** `CohortIndex` (Months elapsed: 0 to 12)
  - **Values:** `ActiveCustomers` (or Retention Percentage)
  - **Conditional Formatting:** Gradient fill applied to background color (Min: Soft Red/Salmon, Mid: Soft Yellow, Max: Dark Green/Navy) to visually highlight decay velocity.
- **Visual 2 (Line Chart):** Mean Retention Curve over elapsed monthly intervals.

---

## 4. Ingestion Instructions

1. Launch **Power BI Desktop**.
2. To load via local CSV exports:
   - Click **Home -> Get Data -> Text/CSV**.
   - Select `data/retail_cleaned.csv`, `data/customer_summary.csv`, and `data/funnel_summary.csv`.
3. To load via MySQL Database:
   - Click **Home -> Get Data -> MySQL Database**.
   - Server: `localhost`, Database: `retail_analysis`.
   - Select tables: `retail_clean`, `customer_summary`, `cohort_counts`.
4. Copy the DAX formulas into new measures and construct visuals as specified above.
5. Save artifact as `Customer_Retention_Analytics.pbix`.
