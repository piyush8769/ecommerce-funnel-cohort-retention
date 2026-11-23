# E-Commerce Product Funnel, Cohort Retention & RFM Analytics

An end-to-end data analytics project analyzing customer conversion drop-offs, longitudinal cohort retention, and RFM customer segmentation across 1,067,000+ transactional records using Python (Pandas), MySQL, and Power BI.

---

## Business Problem

Online retailers face high customer acquisition costs. Sustainable growth depends not just on acquiring first-time buyers, but on understanding repeat buying habits and maximizing customer lifetime value.

This project analyzes transactional data from an international retailer (2009–2011) to address four core business questions:
1. **Where do customers drop off?** What proportion of buyers churn after their very first order?
2. **Who drives revenue?** How heavily does the business rely on repeat customers versus one-time buyers?
3. **How does retention trend over time?** How quickly does customer activity decay month-over-month across acquisition cohorts?
4. **How can customers be segmented for targeted marketing?** How can RFM (Recency, Frequency, Monetary) quintile scoring identify high-value champions versus accounts at risk of churning?

---

## Key Findings

- **The One-Time Buyer Cliff:** **74.1%** of all acquired customers completed only a single transaction and never returned. Moving a customer from their first to their second purchase is the single largest churn bottleneck.
- **Revenue Concentration (80/20 Rule):** The top **11.8%** of customers (Champions with 6+ orders) generate **54.2%** of gross revenue. In contrast, one-time buyers make up nearly three-quarters of the customer base but contribute only 19.8% of sales.
- **The Critical 30-Day Window:** Among repeat buyers, **58.4%** place their second order within **30 days** of their first. Inactivity past 60 days results in an 82% churn probability, establishing the first 30 days as the most critical window for automated retention marketing.
- **Cohort Retention Baseline:** Mean Month-1 retention drops to **21.8%** across cohorts, before stabilizing between **14% and 17%** from Month 4 through Month 8, establishing the core residual loyalty baseline.
- **RFM Segmentation Tiers:** Segmented 4,372 customers into 5 distinct behavioral tiers using `NTILE(5)` quintiles across Recency, Frequency, and Monetary spend:
  - *Champions:* Recent, high-frequency, top-tier spenders generating the bulk of margin.
  - *Loyal Customers:* Consistent multi-order buyers with solid lifetime value.
  - *Potential Loyalists:* Recent buyers with moderate frequency, prime candidates for membership incentives.
  - *At Risk / High-Value Churn:* High lifetime spenders who have been inactive for over 90 days.
  - *Hibernating / Churned:* Single-order buyers with long inactivity (>180 days).

---

## Tools Used

- **Python (Pandas, NumPy, Matplotlib, Seaborn):** Data cleaning, missing value filtering, cohort matrices, and RFM quintile calculations.
- **MySQL:** Storing relational tables and running analytical queries with Common Table Expressions (CTEs) and window functions (`NTILE`, `LAG`, `LEAD`, `ROW_NUMBER`, `DENSE_RANK`).
- **Power BI:** Star schema data modeling, DAX measures for dynamic retention calculations, and report specifications for executive overview, funnel stages, and cohort heatmaps.

---

## Repository Structure

```
├── 01_exploratory_data_analysis.ipynb          # Raw data audit and null inspection
├── 02_data_cleaning.ipynb                     # Filtering missing CustomerIDs, returns, cancellations
├── 03_customer_funnel_analysis.ipynb          # Customer lifecycle grouping and Pareto revenue analysis
├── 04_cohort_retention_analysis.ipynb          # Monthly cohort tagging, retention matrix, and decay heatmap
├── 05_rfm_customer_segmentation.ipynb         # Recency, Frequency, Monetary calculation, quintiles, segment profiling
├── 06_database_export.ipynb                   # Loading clean transactions, dimensions, and RFM segments into MySQL
├── sql/
│   └── customer_retention_analytics.sql       # Executive KPIs, cohort matrix, window functions, and NTILE(5) RFM queries
├── powerbi/
│   └── dashboard_specification.md             # Star schema model, DAX measures dictionary, and visual layouts
├── data/
│   ├── customer_summary.csv                   # Customer-level behavioral metrics
│   ├── funnel_summary.csv                     # Funnel stage volumes and revenue share
│   ├── cohort_retention_matrix.csv            # Monthly retention percentage matrix
│   ├── cohort_counts.csv                      # Raw cohort activity counts
│   └── rfm_customer_segments.csv              # Customer RFM scores and behavioral segment classifications
├── .gitignore
└── README.md
```

---

## Analytical Steps

### 1. Data Cleaning (`01` & `02`)
Raw transaction logs contained 1,067,371 rows across two sheets:
- Filtered out 243,007 rows (~22.7%) lacking `CustomerID` (guest checkouts) to ensure accurate customer tracking.
- Excluded cancelled transactions (invoices prefixed with `C`) and non-positive quantities or unit prices (returns, damaged goods, sample adjustments).
- Calculated total line revenue (`Quantity * Price`) and normalized invoice timestamps to monthly periods.

### 2. Funnel & Lifecycle Grouping (`03`)
Segmented customer accounts into four lifecycle tiers based on lifetime completed orders:
- **One-Time Buyers (1 Order):** 74.1% of customer base, highest churn risk.
- **Repeat Buyers (2 Orders):** Customers validating initial product satisfaction.
- **Loyal Buyers (3–5 Orders):** Steady recurring accounts with consistent margin contribution.
- **Champions (6+ Orders):** Core high-value accounts (11.8% of users, 54.2% of total revenue).

### 3. Cohort Retention Heatmap (`04`)
- Tagged every customer with an acquisition cohort based on their first purchase month (`CohortMonth = MIN(InvoiceMonth)`).
- Measured elapsed monthly intervals (`CohortIndex = InvoiceMonth - CohortMonth`).
- Constructed a retention matrix tracking active buyers and percentage retention decay across 12 monthly cycles.

### 4. RFM Behavioral Segmentation (`05`)
- Calculated three behavioral metrics per customer:
  - **Recency (R):** Days since the customer's last purchase relative to the dataset reference date.
  - **Frequency (F):** Distinct count of completed orders.
  - **Monetary (M):** Total monetary gross spend.
- Divided customers into 5 equal buckets (quintiles 1 to 5) using `pd.qcut`.
- Mapped composite scores into actionable segments (*Champions*, *Loyal Customers*, *Potential Loyalists*, *At Risk*, and *Hibernating*).

---

## SQL Analytics Suite

The `sql/customer_retention_analytics.sql` script includes:
- **Portfolio KPIs:** Total Revenue, Completed Invoices, Distinct Customers, AOV, and Repeat Purchase Rate.
- **Funnel Conversion via CTEs:** Segment-level revenue and volume shares validating the Pareto distribution.
- **Window Functions:**
  - `LAG()`: Month-over-Month (MoM) revenue growth trends.
  - `DENSE_RANK()` & `NTILE(10)`: Customer spend deciles and top customer rankings.
  - `LEAD()` & `ROW_NUMBER()`: Repurchase latency in days between consecutive transactions.
- **SQL RFM Segmentation via `NTILE(5)`:**
  Calculates recency, frequency, and monetary scores directly in SQL to categorize accounts for automated marketing lists.

```sql
WITH CustomerBaseMetrics AS (
    SELECT 
        CustomerID,
        DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS recency_days,
        COUNT(DISTINCT Invoice) AS frequency_orders,
        ROUND(SUM(TotalRevenue), 2) AS monetary_spend
    FROM retail_clean
    GROUP BY CustomerID
),
RFMScores AS (
    SELECT 
        CustomerID,
        recency_days,
        frequency_orders,
        monetary_spend,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency_orders ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_spend ASC) AS m_score
    FROM CustomerBaseMetrics
)
SELECT 
    CustomerID,
    recency_days,
    frequency_orders,
    monetary_spend,
    r_score,
    f_score,
    m_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score < 2 THEN 'Recent New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk / High Value Churn'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating / Churned'
        ELSE 'Potential Loyalists'
    END AS customer_segment
FROM RFMScores;
```
