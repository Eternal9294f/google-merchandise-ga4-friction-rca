-- =====================================================================
-- 05_new_vs_returning_cohorts.sql
-- Business Question: How do user cohorts (First-Time vs. Returning) differ in
-- funnel progression, conversion likelihood, and Average Order Value?
-- =====================================================================

SELECT
    user_type,
    COUNT(session_id) AS total_sessions,
    ROUND(CAST(COUNT(session_id) AS DOUBLE) / (SELECT COUNT(*) FROM read_csv_auto('data/ga4_sessions.csv')) * 100.0, 1) AS share_of_sessions_pct,
    ROUND(CAST(SUM(viewed_item) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS view_rate_pct,
    ROUND(CAST(SUM(added_to_cart) AS DOUBLE) / NULLIF(SUM(viewed_item), 0) * 100.0, 2) AS cart_rate_pct,
    ROUND(CAST(SUM(began_checkout) AS DOUBLE) / NULLIF(SUM(added_to_cart), 0) * 100.0, 2) AS checkout_rate_pct,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / NULLIF(SUM(began_checkout), 0) * 100.0, 2) AS checkout_to_purch_conv_pct,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS overall_conv_rate_pct,
    ROUND(SUM(order_revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS aov_usd
FROM read_csv_auto('data/ga4_sessions.csv')
GROUP BY user_type
ORDER BY overall_conv_rate_pct DESC;
