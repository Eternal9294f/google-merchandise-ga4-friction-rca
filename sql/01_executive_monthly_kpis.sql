-- =====================================================================
-- 01_executive_monthly_kpis.sql
-- Business Question: How did top-line store performance evolve month-over-month
-- across sessions, conversion efficiency, gross revenue, and AOV?
-- =====================================================================

WITH monthly_aggregates AS (
    SELECT
        month_name,
        CASE month_name
            WHEN 'Sep' THEN 9
            WHEN 'Oct' THEN 10
            WHEN 'Nov' THEN 11
        END AS month_num,
        COUNT(session_id) AS total_sessions,
        SUM(purchased) AS total_buyers,
        ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS conversion_rate_pct,
        ROUND(SUM(order_revenue_usd), 2) AS total_revenue_usd,
        ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS aov_usd
    FROM read_csv_auto('data/ga4_sessions.csv')
    GROUP BY month_name, month_num
)
SELECT
    month_name,
    total_sessions,
    total_buyers,
    conversion_rate_pct,
    total_revenue_usd,
    aov_usd,
    ROUND(
        (conversion_rate_pct - LAG(conversion_rate_pct) OVER (ORDER BY month_num)),
        2
    ) AS cr_mom_diff_pts,
    ROUND(
        (total_revenue_usd - LAG(total_revenue_usd) OVER (ORDER BY month_num)) / 
        LAG(total_revenue_usd) OVER (ORDER BY month_num) * 100.0,
        2
    ) AS revenue_mom_pct
FROM monthly_aggregates
ORDER BY month_num;
