-- =====================================================================
-- 09_checkout_error_impact.sql
-- Business Question: What is the exact quantified financial impact of the
-- shipping step validation error on completion rate and lost revenue?
-- =====================================================================

WITH checkout_cohorts AS (
    SELECT
        device_category,
        shipping_step_error,
        COUNT(session_id) AS checkout_sessions,
        SUM(purchased) AS completed_orders,
        ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS completion_rate_pct,
        ROUND(SUM(order_revenue_usd), 2) AS realized_revenue_usd,
        ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS realized_aov_usd
    FROM read_csv_auto('data/ga4_sessions.csv')
    WHERE began_checkout = 1
    GROUP BY device_category, shipping_step_error
),
benchmarks AS (
    SELECT
        device_category,
        completion_rate_pct AS unblocked_completion_rate,
        realized_aov_usd AS unblocked_aov
    FROM checkout_cohorts
    WHERE shipping_step_error = 0
)
SELECT
    c.device_category,
    CASE WHEN c.shipping_step_error = 1 THEN 'Encountered Shipping Error' ELSE 'Clean Checkout Flow' END AS checkout_experience,
    c.checkout_sessions,
    c.completed_orders,
    c.completion_rate_pct,
    c.realized_revenue_usd,
    CASE
        WHEN c.shipping_step_error = 1 THEN
            ROUND(
                (c.checkout_sessions * (b.unblocked_completion_rate / 100.0) - c.completed_orders) * b.unblocked_aov,
                2
            )
        ELSE 0.0
    END AS estimated_lost_revenue_usd
FROM checkout_cohorts c
JOIN benchmarks b ON c.device_category = b.device_category
ORDER BY c.device_category, c.shipping_step_error;
