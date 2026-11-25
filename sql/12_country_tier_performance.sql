-- =====================================================================
-- 12_country_tier_performance.sql
-- Business Question: How do international geographic markets perform in terms
-- of session volume, checkout conversion efficiency, and gross revenue?
-- =====================================================================

SELECT
    country,
    COUNT(session_id) AS total_sessions,
    ROUND(CAST(COUNT(session_id) AS DOUBLE) / (SELECT COUNT(*) FROM read_csv_auto('data/ga4_sessions.csv')) * 100.0, 2) AS session_share_pct,
    SUM(began_checkout) AS checkout_sessions,
    SUM(purchased) AS total_purchases,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS overall_conv_rate_pct,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / NULLIF(SUM(began_checkout), 0) * 100.0, 2) AS checkout_to_purch_conv_pct,
    ROUND(SUM(order_revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS aov_usd
FROM read_csv_auto('data/ga4_sessions.csv')
GROUP BY country
ORDER BY total_revenue_usd DESC;
