-- =====================================================================
-- 08_day_of_week_patterns.sql
-- Business Question: What are the daily traffic and conversion patterns
-- across days of the week, and when is purchasing activity concentrated?
-- =====================================================================

SELECT
    EXTRACT(DOW FROM CAST(event_date AS DATE)) AS day_of_week_num,
    STRFTIME(CAST(event_date AS DATE), '%A') AS day_name,
    COUNT(session_id) AS total_sessions,
    SUM(purchased) AS total_purchases,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS conversion_rate_pct,
    ROUND(SUM(order_revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS aov_usd,
    ROUND(SUM(order_revenue_usd) / COUNT(session_id), 2) AS revenue_per_session_usd
FROM read_csv_auto('data/ga4_sessions.csv')
GROUP BY day_of_week_num, day_name
ORDER BY day_of_week_num;
