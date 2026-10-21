# E-Commerce Customer Conversion Funnel & Longitudinal Cohort Retention Analytics

An end-to-end analytics project tracking customer lifecycle progression, conversion drop-off latency, and longitudinal retention decay across 1,000,000+ transaction records using Python, MySQL, and Power BI.

---

## 1. Executive Summary & Business Objectives

Customer acquisition costs (CAC) continue to escalate across online retail. Consequently, sustainable unit economics require understanding post-acquisition behavioral dynamics:
- **Where do customers churn in the purchase funnel?**
- **What proportion of acquired customers generate repeat enterprise value?**
- **How rapidly does monthly customer retention decay across historical cohorts?**

This project analyzes transactional records from an international e-commerce platform spanning 2009–2011 to model customer conversion funnels, evaluate revenue concentration (Pareto distribution), and engineer monthly cohort retention matrices.

---

## 2. Key Findings & Strategic Insights

1. **Acquisition Drop-Off Bottleneck:**
   - **74.1%** of all acquired customers completed exactly one transaction and never repeated.
   - The transition between **Stage 1 (One-Time Buyer)** and **Stage 2 (Repeat Buyer)** represents the primary churn cliff in the customer lifecycle.

2. **Severe Revenue Concentration (Pareto Principle):**
   - **Champions (6+ orders)** comprise only **11.8%** of the active customer base, yet generate **54.2%** of gross realized revenue.
   - One-time buyers comprise **74.1%** of volume but contribute only **19.8%** of total revenue.

3. **Repurchase Latency & Critical Re-engagement Window:**
   - Among repeat buyers, **58.4%** execute their second transaction within **30 days** of initial acquisition.
   - Customers inactive past 60 days exhibit an 82% terminal churn probability, establishing the 0–30 day post-purchase window as the optimal trigger interval for automated retention campaigns.

4. **Longitudinal Retention Decay:**
   - Mean Month-1 retention averages **21.8%** across cohorts.
   - Retention stabilizes between Month 4 and Month 8 at **14–17%**, defining the core residual loyalty baseline.

---

## 3. Technology Stack

- **Data Processing & Analytics:** Python 3.12, Pandas, NumPy, OpenPyXL
- **Data Visualization:** Matplotlib, Seaborn
- **Relational Data Warehouse:** MySQL 8.0, SQLAlchemy
- **Database Querying & Modeling:** Advanced SQL (Common Table Expressions, Window Functions: `DENSE_RANK`, `LAG`, `LEAD`, `NTILE`)
- **Business Intelligence:** Microsoft Power BI, DAX (Time Intelligence, Dynamic Ratios), Star Schema Modeling

---

## 4. Repository Structure

```
.
├── 01_exploratory_data_analysis.ipynb          # Raw schema audit, anomaly detection, null diagnostics
├── 02_data_cleaning.ipynb                     # Identifier validation, returns/cancellations filtering
├── 03_customer_funnel_analysis.ipynb          # Customer aggregation, lifecycle tiering, Pareto metrics
├── 04_cohort_retention_analysis.ipynb          # Acquisition cohort tagging, matrix construction, heatmap
├── 05_database_export.ipynb                   # MySQL batch ingestion and record count reconciliation
│
├── sql/
│   └── customer_retention_analytics.sql       # Executive KPIs, window functions, cohort calculations
│
├── powerbi/
│   └── dashboard_specification.md             # Star schema model, DAX measure dictionary, visual layouts
│
├── data/
│   ├── online_retail_II.xlsx                  # Raw multi-sheet transactional log (Git ignored)
│   ├── retail_cleaned.csv                     # Sanitized analytical fact dataset (Git ignored / generated via notebook 02)
│   ├── customer_summary.csv                   # Customer-level behavioral features
│   ├── funnel_summary.csv                     # Funnel stage volumes and revenue share
│   ├── cohort_retention_matrix.csv            # Normalized monthly retention percentage matrix
│   └── cohort_counts.csv                      # Raw cohort activity counts
├── .gitignore
└── README.md
```

---

## 5. Analytical Workflow & Methodology

### 5.1 Data Audit & Preprocessing
Raw transactional logs contained 1,067,371 rows across two sheets. Integrity checks established four essential filtering criteria:
- **Missing Identifiers:** Filtered 243,007 rows (~22.7%) lacking `CustomerID` (guest checkouts) to ensure deterministic longitudinal tracking.
- **Order Cancellations:** Excluded 19,494 transactions prefixed with invoice identifier `C`.
- **Negative / Zero Economics:** Filtered non-positive quantities (inventory returns, damaged stock adjustments) and items with unit price `<= 0` (samples, test entries).
- **Feature Engineering:** Calculated line-item gross revenue (`Quantity * Price`) and normalized transaction timestamps into month periods (`InvoiceMonth`).

### 5.2 Customer Funnel Architecture
Customers are grouped into four lifecycle tiers based on lifetime completed orders:
- **One-Time Buyers (1 Order):** Inactive acquisition cohort requiring automated activation.
- **Repeat Buyers (2 Orders):** Activated accounts validating initial value proposition.
- **Loyal Buyers (3–5 Orders):** Established recurring accounts with steady margin contribution.
- **Champions (6+ Orders):** Brand advocates with high order frequency and lifetime value.

### 5.3 Cohort Retention Modeling
- Tagged every customer with an acquisition cohort (`CohortMonth = MIN(InvoiceMonth)`).
- Calculated elapsed monthly intervals (`CohortIndex = InvoiceMonth - CohortMonth`).
- Constructed a dynamic matrix measuring active buyers per cohort per activity cycle.
- Normalized activity against in-cohort baseline volume (`CohortIndex = 0`) to generate monthly decay rates.

---

## 6. SQL Analytics Suite

The SQL suite in `sql/customer_retention_analytics.sql` provides production-grade queries organized by analytical domain:
1. **Executive Portfolio KPIs:** Distinct orders, customer base, realized revenue, average order value (AOV), and customer lifetime value (CLV).
2. **Geographical & Catalog Performance:** International revenue distribution and SKU sales velocity.
3. **Funnel Conversion Pareto Analysis:** Segment-level revenue share calculated via Common Table Expressions (`WITH`).
4. **Advanced Window Functions:**
   - **`LAG()`:** Month-over-Month (MoM) revenue growth trajectories.
   - **`DENSE_RANK()` & `NTILE(10)`:** Customer spend ranking and decile stratification.
   - **`LEAD()` & `ROW_NUMBER()`:** Repurchase latency in days between first and second transaction.
5. **Cohort Matrix Summary:** Reconstructing monthly retention cohorts natively inside the database.

---

## 7. Power BI Dashboard Architecture

Designed in a Star Schema format with documentation in `powerbi/dashboard_specification.md`:
- **Model:** Central `retail_clean` fact table joined to `customer_summary` dimension on `CustomerID`.
- **DAX Measures:** `Total Revenue`, `Total Orders`, `AOV`, `Repeat Customer Rate`, `One-Time Churn Rate`.
- **Visual Pages:**
  1. *Executive Overview:* Portfolio gross revenue, order volume, country performance.
  2. *Conversion Funnel:* Conversion drop-off by tier, volume vs revenue contribution.
  3. *Cohort Retention Matrix:* Color-coded heatmap showing monthly decay curves across cohorts.
