-- =====================================================================
-- 03_device_funnel_rca.sql
-- Business Question: Root-Cause Analysis — Which device category drove the November
-- checkout drop, and how does shipping error rate correlate with completion?
-- =====================================================================

SELECT
    month_name,
    CASE month_name WHEN 'Sep' THEN 9 WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 END AS month_num,
    device_category,
    COUNT(session_id) AS total_sessions,
    SUM(began_checkout) AS checkout_sessions,
    SUM(purchased) AS purchased_sessions,
    ROUND(CAST(SUM(purchased) AS DOUBLE) / NULLIF(SUM(began_checkout), 0) * 100.0, 2) AS checkout_to_purch_conv_pct,
    ROUND((1.0 - CAST(SUM(purchased) AS DOUBLE) / NULLIF(SUM(began_checkout), 0)) * 100.0, 2) AS checkout_abandonment_pct,
    SUM(shipping_step_error) AS total_shipping_errors,
    ROUND(CAST(SUM(shipping_step_error) AS DOUBLE) / NULLIF(SUM(began_checkout), 0) * 100.0, 2) AS shipping_error_rate_pct
FROM read_csv_auto('data/ga4_sessions.csv')
GROUP BY month_name, month_num, device_category
ORDER BY month_num, device_category;
