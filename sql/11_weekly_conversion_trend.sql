-- =====================================================================
-- 11_weekly_conversion_trend.sql
-- Business Question: What was the weekly trajectory of session volume,
-- conversion rate, and revenue, pinpointing the week of friction onset?
-- =====================================================================

SELECT
    DATE_TRUNC('week', CAST(event_date AS DATE)) AS week_start_date,
    COUNT(session_id) AS total_sessions,
    SUM(began_checkout) AS checkout_sessions,
    SUM(purchased) AS completed_orders,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS overall_conv_rate_pct,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / NULLIF(SUM(began_checkout), 0) * 100.0, 2) AS checkout_to_purch_conv_pct,
    SUM(shipping_step_error) AS shipping_errors,
    ROUND(CAST(SUM(shipping_step_error) AS DOUBLE) / NULLIF(SUM(began_checkout), 0) * 100.0, 2) AS shipping_error_rate_pct,
    ROUND(SUM(order_revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS aov_usd
FROM read_csv_auto('data/ga4_sessions.csv')
GROUP BY week_start_date
ORDER BY week_start_date;
