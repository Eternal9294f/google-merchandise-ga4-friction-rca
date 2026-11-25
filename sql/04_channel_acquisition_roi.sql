-- =====================================================================
-- 04_channel_acquisition_roi.sql
-- Business Question: Which marketing acquisition channels deliver the highest
-- conversion efficiency and gross revenue per session?
-- =====================================================================

SELECT
    traffic_source,
    COUNT(session_id) AS total_sessions,
    SUM(purchased) AS total_purchases,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS conversion_rate_pct,
    ROUND(SUM(order_revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS aov_usd,
    ROUND(SUM(order_revenue_usd) / COUNT(session_id), 2) AS revenue_per_session_usd
FROM read_csv_auto('data/ga4_sessions.csv')
GROUP BY traffic_source
ORDER BY total_revenue_usd DESC;
