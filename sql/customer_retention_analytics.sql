-- ==============================================================
-- E-Commerce Customer Retention & Funnel Analytics
-- Script: customer_retention_analytics.sql
-- Database: retail_analysis
-- Schema: MySQL 8.0+
-- ==============================================================

USE retail_analysis;


-- ==============================================================
-- 1. EXECUTIVE SUMMARY & PORTFOLIO KPIS
-- ==============================================================

-- Core business metrics: order volume, active customer base, gross revenue, AOV
SELECT 
    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT CustomerID) AS total_customers,
    ROUND(SUM(TotalRevenue), 2) AS gross_revenue,
    ROUND(SUM(TotalRevenue) / COUNT(DISTINCT Invoice), 2) AS average_order_value,
    ROUND(SUM(TotalRevenue) / COUNT(DISTINCT CustomerID), 2) AS customer_lifetime_value
FROM retail_clean;


-- ==============================================================
-- 2. GEOGRAPHICAL & MARKET PERFORMANCE
-- ==============================================================

-- Top international markets by revenue and order concentration
SELECT 
    Country,
    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT CustomerID) AS customer_count,
    ROUND(SUM(TotalRevenue), 2) AS total_revenue,
    ROUND(SUM(TotalRevenue) / COUNT(DISTINCT Invoice), 2) AS market_aov,
    ROUND(SUM(TotalRevenue) * 100.0 / SUM(SUM(TotalRevenue)) OVER(), 2) AS revenue_share_pct
FROM retail_clean
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;


-- Product catalog velocity: Top 10 revenue-generating SKUs
SELECT 
    StockCode,
    Description,
    SUM(Quantity) AS units_sold,
    ROUND(SUM(TotalRevenue), 2) AS realized_revenue,
    ROUND(SUM(TotalRevenue) / SUM(Quantity), 2) AS effective_unit_price
FROM retail_clean
GROUP BY StockCode, Description
ORDER BY realized_revenue DESC
LIMIT 10;


-- ==============================================================
-- 3. CUSTOMER FUNNEL CONVERSION & REVENUE CONCENTRATION
-- ==============================================================

-- Conversion funnel tiering: Customer count vs revenue contribution (Pareto Analysis)
WITH CustomerAggregates AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT Invoice) AS order_frequency,
        ROUND(SUM(TotalRevenue), 2) AS customer_spend
    FROM retail_clean
    GROUP BY CustomerID
),
ClassifiedFunnel AS (
    SELECT 
        CustomerID,
        order_frequency,
        customer_spend,
        CASE 
            WHEN order_frequency = 1 THEN '1. One-Time Buyer'
            WHEN order_frequency = 2 THEN '2. Repeat Buyer'
            WHEN order_frequency BETWEEN 3 AND 5 THEN '3. Loyal Buyer'
            ELSE '4. Champion'
        END AS funnel_tier
    FROM CustomerAggregates
)
SELECT 
    funnel_tier,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS customer_percentage,
    ROUND(SUM(customer_spend), 2) AS tier_revenue,
    ROUND(SUM(customer_spend) * 100.0 / SUM(SUM(customer_spend)) OVER(), 2) AS revenue_percentage,
    ROUND(AVG(customer_spend), 2) AS avg_spend_per_customer
FROM ClassifiedFunnel
GROUP BY funnel_tier
ORDER BY funnel_tier ASC;


-- ==============================================================
-- 4. ADVANCED WINDOW ANALYSIS
-- ==============================================================

-- 4.1 Month-over-Month (MoM) Revenue Growth Rate using LAG()
WITH MonthlyFinancials AS (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS reporting_month,
        COUNT(DISTINCT Invoice) AS order_volume,
        COUNT(DISTINCT CustomerID) AS active_buyers,
        ROUND(SUM(TotalRevenue), 2) AS monthly_revenue
    FROM retail_clean
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT 
    reporting_month,
    order_volume,
    active_buyers,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY reporting_month) AS previous_month_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY reporting_month))
        / LAG(monthly_revenue, 1) OVER (ORDER BY reporting_month) * 100, 
    2) AS mom_growth_rate_pct,
    CASE 
        WHEN monthly_revenue > LAG(monthly_revenue, 1) OVER (ORDER BY reporting_month) THEN 'Growth'
        WHEN monthly_revenue < LAG(monthly_revenue, 1) OVER (ORDER BY reporting_month) THEN 'Contraction'
        ELSE 'Neutral'
    END AS trajectory
FROM MonthlyFinancials
ORDER BY reporting_month ASC;


-- 4.2 Customer Spend Ranking and Decile Distribution using DENSE_RANK() & NTILE()
WITH CustomerLifetimeSpend AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT Invoice) AS order_count,
        ROUND(SUM(TotalRevenue), 2) AS gross_spend
    FROM retail_clean
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    order_count,
    gross_spend,
    DENSE_RANK() OVER (ORDER BY gross_spend DESC) AS spending_rank,
    NTILE(10) OVER (ORDER BY gross_spend DESC) AS spend_decile
FROM CustomerLifetimeSpend
ORDER BY gross_spend DESC
LIMIT 25;


-- 4.3 Repurchase Latency (Days to Second Purchase) using LEAD() & ROW_NUMBER()
WITH OrderedCustomerTransactions AS (
    SELECT 
        CustomerID,
        InvoiceDate,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID 
            ORDER BY InvoiceDate ASC
        ) AS order_rank
    FROM retail_clean
    GROUP BY CustomerID, InvoiceDate
),
FirstAndSecondOrders AS (
    SELECT 
        CustomerID,
        InvoiceDate AS initial_purchase_date,
        LEAD(InvoiceDate, 1) OVER (
            PARTITION BY CustomerID 
            ORDER BY InvoiceDate ASC
        ) AS second_purchase_date
    FROM OrderedCustomerTransactions
    WHERE order_rank <= 2
)
SELECT 
    CustomerID,
    DATE(initial_purchase_date) AS first_order,
    DATE(second_purchase_date) AS second_order,
    DATEDIFF(second_purchase_date, initial_purchase_date) AS repurchase_latency_days,
    CASE 
        WHEN DATEDIFF(second_purchase_date, initial_purchase_date) <= 30 THEN 'Within 30 Days'
        WHEN DATEDIFF(second_purchase_date, initial_purchase_date) <= 60 THEN '31-60 Days'
        WHEN DATEDIFF(second_purchase_date, initial_purchase_date) <= 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS activation_window
FROM FirstAndSecondOrders
WHERE second_purchase_date IS NOT NULL
ORDER BY repurchase_latency_days ASC
LIMIT 50;


-- ==============================================================
-- 5. COHORT RETENTION REPORTING MATRIX
-- ==============================================================

-- Reconstruct monthly cohort retention summary in SQL
WITH CustomerAcquisition AS (
    SELECT 
        CustomerID,
        DATE_FORMAT(MIN(InvoiceDate), '%Y-%m') AS cohort_month
    FROM retail_clean
    GROUP BY CustomerID
),
CohortActivity AS (
    SELECT 
        r.CustomerID,
        c.cohort_month,
        DATE_FORMAT(r.InvoiceDate, '%Y-%m') AS activity_month,
        PERIOD_DIFF(
            DATE_FORMAT(r.InvoiceDate, '%Y%m'),
            DATE_FORMAT(c.cohort_month, '%Y%m')
        ) AS cycle_index
    FROM retail_clean r
    JOIN CustomerAcquisition c ON r.CustomerID = c.CustomerID
)
SELECT 
    cohort_month,
    COUNT(DISTINCT CASE WHEN cycle_index = 0 THEN CustomerID END) AS cohort_size,
    COUNT(DISTINCT CASE WHEN cycle_index = 1 THEN CustomerID END) AS month_1_retained,
    COUNT(DISTINCT CASE WHEN cycle_index = 2 THEN CustomerID END) AS month_2_retained,
    COUNT(DISTINCT CASE WHEN cycle_index = 3 THEN CustomerID END) AS month_3_retained,
    COUNT(DISTINCT CASE WHEN cycle_index = 6 THEN CustomerID END) AS month_6_retained,
    ROUND(
        COUNT(DISTINCT CASE WHEN cycle_index = 1 THEN CustomerID END) * 100.0 / 
        COUNT(DISTINCT CASE WHEN cycle_index = 0 THEN CustomerID END), 
    1) AS m1_retention_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN cycle_index = 3 THEN CustomerID END) * 100.0 / 
        COUNT(DISTINCT CASE WHEN cycle_index = 0 THEN CustomerID END), 
    1) AS m3_retention_pct
FROM CohortActivity
GROUP BY cohort_month
ORDER BY cohort_month ASC;
