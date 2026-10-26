-- =========================================================================
-- E-COMMERCE A/B TESTING & CONVERSION OPTIMIZATION ANALYSIS
-- Feature: 1-Click Guest Checkout (Treatment) vs 3-Step Standard (Control)
-- Database Engine: MySQL 8.0+
-- =========================================================================

-- 1. Sample Ratio Mismatch (SRM) & Traffic Randomization Audit
WITH traffic_split AS (
    SELECT 
        variant,
        COUNT(DISTINCT user_id) AS visitors,
        COUNT(DISTINCT user_id) / SUM(COUNT(DISTINCT user_id)) OVER () AS actual_ratio,
        0.5000 AS expected_ratio
    FROM ab_test_traffic_log
    GROUP BY variant
)
SELECT 
    variant,
    visitors,
    ROUND(actual_ratio * 100, 2) AS traffic_share_pct,
    ROUND(expected_ratio * 100, 2) AS expected_share_pct,
    -- Chi-square contribution: (O - E)^2 / E
    POWER(visitors - (SUM(visitors) OVER () * 0.5), 2) / (SUM(visitors) OVER () * 0.5) AS chi_square_component
FROM traffic_split;

-- 2. Executive Conversion Rate & Relative Lift Calculation
WITH experiment_summary AS (
    SELECT 
        variant,
        COUNT(DISTINCT user_id) AS total_visitors,
        SUM(converted) AS total_conversions,
        ROUND(SUM(converted) * 1.0 / COUNT(DISTINCT user_id), 4) AS conversion_rate,
        ROUND(SUM(order_amount), 2) AS gross_revenue,
        ROUND(SUM(order_amount) / NULLIF(SUM(converted), 0), 2) AS average_order_value
    FROM ab_test_traffic_log
    GROUP BY variant
)
SELECT 
    variant,
    total_visitors,
    total_conversions,
    ROUND(conversion_rate * 100, 2) AS conversion_rate_pct,
    ROUND((conversion_rate - LAG(conversion_rate) OVER (ORDER BY variant DESC)) 
          / NULLIF(LAG(conversion_rate) OVER (ORDER BY variant DESC), 0) * 100, 2) AS relative_lift_pct,
    gross_revenue,
    average_order_value
FROM experiment_summary;

-- 3. Device Stratification Breakdown (Mobile vs Desktop)
SELECT 
    device,
    variant,
    COUNT(DISTINCT user_id) AS visitors,
    SUM(converted) AS orders,
    ROUND(SUM(converted) * 100.0 / COUNT(DISTINCT user_id), 2) AS conversion_rate_pct,
    ROUND(SUM(order_amount) / NULLIF(SUM(converted), 0), 2) AS aov
FROM ab_test_traffic_log
GROUP BY device, variant
ORDER BY device, variant;

-- 4. Cumulative Day-over-Day Experiment Trajectory
WITH daily_conversions AS (
    SELECT 
        day,
        variant,
        COUNT(DISTINCT user_id) AS daily_visitors,
        SUM(converted) AS daily_conversions,
        SUM(order_amount) AS daily_revenue
    FROM ab_test_traffic_log
    GROUP BY day, variant
)
SELECT 
    day,
    variant,
    daily_visitors,
    daily_conversions,
    SUM(daily_visitors) OVER (PARTITION BY variant ORDER BY day) AS cum_visitors,
    SUM(daily_conversions) OVER (PARTITION BY variant ORDER BY day) AS cum_conversions,
    ROUND(SUM(daily_conversions) OVER (PARTITION BY variant ORDER BY day) * 100.0 / 
          SUM(daily_visitors) OVER (PARTITION BY variant ORDER BY day), 2) AS cum_conversion_rate_pct
FROM daily_conversions
ORDER BY day, variant;
