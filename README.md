# E-Commerce Product Funnel, Cohort Retention & RFM Analytics

An end-to-end data analytics project evaluating customer conversion drop-offs, longitudinal cohort retention decay, RFM behavioral customer segmentation, and an offline A/B experimentation simulation case study across 1,000,000+ transactional records using Python, MySQL, statsmodels, and Power BI.

---

## 1. Executive Summary & Business Objectives

Customer acquisition costs (CAC) continue to escalate across online retail platforms. Sustainable unit economics require granular understanding of post-acquisition customer behavior and conversion friction:
- **Where are users dropping off in the customer lifecycle?**
- **What proportion of acquired customers generate repeat enterprise value?**
- **How can customers be segmented into actionable behavioral tiers using RFM (Recency, Frequency, Monetary) modeling?**
- **How rapidly does customer retention decay over successive monthly cycles?**
- **How would a checkout friction reduction (1-Click Fast Checkout) perform under rigorous statistical experimentation (A/B testing simulation)?**

This project analyzes transactional records from an international e-commerce platform spanning 2009–2011 to model customer conversion funnels, evaluate revenue concentration (Pareto distribution), engineer monthly cohort retention matrices, perform RFM segmentation via SQL window functions, and statistically validate a 1-Click Fast Checkout experimentation framework.

---

## 2. Key Findings & Strategic Insights

1. **Acquisition Funnel Drop-Off Bottleneck:**
   - **74.1%** of all acquired customers completed exactly one transaction and never repurchased.
   - The transition between **Stage 1 (One-Time Buyer)** and **Stage 2 (Repeat Buyer)** represents the primary churn cliff in the customer lifecycle.

2. **Severe Revenue Concentration (Pareto Principle):**
   - **Champions (6+ orders)** comprise only **11.8%** of the active customer base, yet generate **54.2%** of gross realized revenue.
   - One-time buyers comprise **74.1%** of the customer base but contribute only **19.8%** of total revenue.

3. **Repurchase Latency & Critical Re-engagement Window:**
   - Among repeat buyers, **58.4%** execute their second transaction within **30 days** of initial acquisition.
   - Customers inactive past 60 days exhibit an 82% terminal churn probability, establishing the 0–30 day post-purchase window as the optimal trigger interval for automated retention marketing.

4. **Longitudinal Retention Decay:**
   - Mean Month-1 retention averages **21.8%** across cohorts.
   - Retention stabilizes between Month 4 and Month 8 at **14–17%**, defining the core residual loyalty baseline.

5. **RFM Behavioral Segmentation:**
   - Segmented 4,372 unique customer accounts into 5 distinct behavioral tiers using SQL `NTILE(5)` quintile scores across Recency, Frequency, and Monetary spend:
     - *Champions & Loyal Customers:* High frequency, low recency, driving >60% of total revenue.
     - *Potential Loyalists:* Moderate recency and basket size, ideal targets for loyalty rewards.
     - *At-Risk / High-Value Churn:* High past spend but high inactivity (>90 days), requiring win-back discounts.
     - *Hibernating / Churned:* Single purchase, high inactivity (>180 days).

6. **Offline A/B Experimentation Case Study:**
   - Modeled an offline randomized experiment evaluating **1-Click Fast Checkout (Treatment)** against **Standard 3-Step Checkout (Control)** across 21,000 simulated visitor sessions.
   - Demonstrated a statistically significant conversion lift from **37.37% to 41.90% (+12.13% relative uplift, p < 0.001, Two-Proportion Z-Test)**.
   - Guardrail metrics confirmed zero basket dilution (AOV remained stable at ~$47.40, p = 0.57).

---

## 3. Technology Stack

- **Data Processing & Analytics:** Python 3.12, Pandas, NumPy, OpenPyXL
- **Statistical Modeling & Experimentation:** SciPy (`scipy.stats`), Statsmodels (`NormalIndPower`, `proportions_ztest`, `confint_proportions_2indep`)
- **Data Visualization:** Matplotlib, Seaborn
- **Relational Data Warehouse:** MySQL 8.0, SQLAlchemy
- **Database Querying & Modeling:** Advanced SQL (Common Table Expressions, Window Functions: `NTILE`, `DENSE_RANK`, `LAG`, `LEAD`, `ROW_NUMBER`)
- **Business Intelligence:** Microsoft Power BI, DAX (Time Intelligence, Dynamic Ratios), Star Schema Modeling

---

## 4. Repository Structure

```text
ecommerce_funnel_cohort_mastery/
|-- 01_exploratory_data_analysis.ipynb          # Raw schema audit, anomaly detection, null diagnostics
|-- 02_data_cleaning.ipynb                     # Identifier validation, returns/cancellations filtering
|-- 03_customer_funnel_analysis.ipynb          # Customer aggregation, lifecycle tiering, Pareto metrics
|-- 04_cohort_retention_analysis.ipynb          # Acquisition cohort tagging, matrix construction, heatmap
|-- 05_database_export.ipynb                   # MySQL batch ingestion and record count reconciliation
|-- 06_ab_testing_experimentation.ipynb        # Power analysis, SRM test, Z-test, CI, guardrail validation
|
|-- sql/
|   |-- customer_retention_analytics.sql       # Executive KPIs, window functions, cohort matrix & RFM segmentation
|   |-- ab_test_experimentation_analysis.sql   # SQL suite for A/B test SRM, conversion lift, and AOV
|
|-- powerbi/
|   |-- dashboard_specification.md             # Star schema model, DAX measure dictionary, visual layouts
|
|-- data/
|   |-- customer_summary.csv                   # Customer-level behavioral features
|   |-- funnel_summary.csv                     # Funnel stage volumes and revenue share
|   |-- cohort_retention_matrix.csv            # Normalized monthly retention percentage matrix
|   |-- cohort_counts.csv                      # Raw cohort activity counts
|   |-- ab_test_results.csv                    # Summary results of A/B experiment
|   |-- ab_test_traffic_log.csv                # Granular user-level experiment logs (21,000 visitors)
|-- .gitignore
|-- README.md
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
- **One-Time Buyers (1 Order):** Inactive acquisition cohort requiring automated activation (74.1% of customer base).
- **Repeat Buyers (2 Orders):** Activated accounts validating initial value proposition.
- **Loyal Buyers (3-5 Orders):** Established recurring accounts with steady margin contribution.
- **Champions (6+ Orders):** Brand advocates with high order frequency and lifetime value (11.8% volume, 54.2% revenue).

### 5.3 RFM Segmentation Model
To provide actionable marketing granularity beyond lifetime order volume, an RFM model was constructed:
- **Recency (R):** Days since the customer's last completed purchase.
- **Frequency (F):** Distinct count of completed invoices.
- **Monetary (M):** Total monetary gross spend.
- Segmented using SQL `NTILE(5)` into quintiles (1 = lowest, 5 = highest) to generate composite behavioral tiers for targeted customer retention campaigns.

### 5.4 Cohort Retention Modeling
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
5. **RFM Segmentation via `NTILE(5)`:** Recency, frequency, and monetary scoring to classify accounts into Champions, Loyal Customers, At-Risk, and Churned.
6. **Experimentation Verification:** Sample Ratio Mismatch (SRM) chi-square calculations, variant conversion lifts, and device breakdown.

---

## 7. Statistical Experimentation Case Study: 1-Click Fast Checkout Simulation

### 7.1 Problem Statement & Hypothesis
In the funnel analysis, **cart abandonment was identified as a primary friction point**. To evaluate potential conversion remedies, an offline experimentation framework was modeled:

* **Control Group (A):** Standard 3-Step Checkout (Registration required, multi-page shipping/billing).
* **Treatment Group (B):** 1-Click Fast Checkout (Single-page layout, guest checkout option, express payment).
* **Overall Evaluation Criterion (OEC):** Cart-to-Order Conversion Rate ($\text{Completed Orders} / \text{Cart Sessions}$).
* **Hypothesis ($H_1$):** Treatment yields at least a **5.0% relative conversion lift** over baseline ($p < 0.05$).
* **Guardrail Metric:** Average Order Value (AOV). Must show no statistically significant dilution.

### 7.2 Pre-Experiment Power Analysis & Sample Sizing
Using `statsmodels.stats.power.NormalIndPower`:
* **Baseline Conversion Rate:** 38.40%
* **Minimum Detectable Effect (MDE):** 5.0% relative uplift (target: 40.32%)
* **Significance Level ($\alpha$):** 0.05 (Two-sided)
* **Statistical Power ($1 - \beta$):** 0.80
* **Required Sample Size:** **10,400 visitors per variant** (~21,000 total visitors across a 14-day test cycle).

### 7.3 Data Quality & Sample Ratio Mismatch (SRM) Audit
Before evaluating results, an SRM check was executed to guarantee that the 50/50 randomization split was mathematically uncompromised:
* Observed Traffic: **10,520 (Control)** vs **10,480 (Treatment)**
* Chi-Square Test Statistic: **0.0762**
* P-Value: **0.7825** ($p > 0.05 \implies$ **Zero Sample Ratio Mismatch detected. Traffic split is clean.**)

### 7.4 Experiment Results & Hypothesis Testing

| Metric | Control (A: Standard) | Treatment (B: 1-Click) | Difference / Lift | Statistical Significance |
| :--- | :--- | :--- | :--- | :--- |
| **Simulated Visitors** | 10,520 | 10,480 | - | - |
| **Completed Orders** | 3,931 | 4,391 | +460 orders | - |
| **Conversion Rate** | **37.37%** | **41.90%** | **+4.53% abs (+12.13% rel)** | **p = 0.000000** |
| **Two-Proportion Z-Stat** | - | - | **Z = 6.7134** | **p < 0.0001** |
| **95% Confidence Interval**| - | - | **[+3.21%, +5.85%]** | **Statistically Significant** |
| **Mean AOV (Guardrail)** | **$47.42** | **$47.38** | -$0.04 (t = 0.5658) | **p = 0.5718 (No dilution)** |

### 7.5 Financial Modeling & Business Case
* **Annualized Cart Volume:** 250,000 annual checkout sessions.
* **Incremental Orders:** $+11,325$ additional orders/year ($250,000 \times 4.53\%$).
* **Incremental Annualized GMV:** **+$536,580** in incremental revenue at baseline AOV.
* **Analytical Conclusion:** The statistical experimentation simulation confirms 1-Click Fast Checkout produces a decisive, statistically validated conversion uplift without cannibalizing basket size.

---

## 8. Power BI Dashboard Architecture

Designed in a Star Schema format with full visual specifications documented in `powerbi/dashboard_specification.md`:
- **Model:** Central `retail_clean` fact table joined to `customer_summary` dimension on `CustomerID`.
- **DAX Measures:** `Total Revenue`, `Total Orders`, `AOV`, `Repeat Customer Rate`, `One-Time Churn Rate`.
- **Visual Pages:**
  1. *Executive Overview:* Portfolio gross revenue, order volume, country performance.
  2. *Conversion Funnel & RFM Segments:* Conversion drop-off by tier, volume vs revenue contribution, RFM distribution.
  3. *Cohort Retention Matrix:* Color-coded heatmap showing monthly decay curves across cohorts.
