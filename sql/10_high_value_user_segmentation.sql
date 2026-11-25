-- =====================================================================
-- 10_high_value_user_segmentation.sql
-- Business Question: How do purchasing customers distribute across spend
-- quartiles (NTILE(4)), and what is the concentration of gross revenue?
-- =====================================================================

WITH customer_spend AS (
    SELECT
        user_pseudo_id,
        user_type,
        COUNT(session_id) AS total_sessions,
        SUM(purchased) AS total_orders,
        ROUND(SUM(order_revenue_usd), 2) AS total_customer_spend_usd
    FROM read_csv_auto('data/ga4_sessions.csv')
    WHERE purchased = 1
    GROUP BY user_pseudo_id, user_type
),
ranked_customers AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_customer_spend_usd DESC) AS spend_quartile
    FROM customer_spend
)
SELECT
    spend_quartile,
    CASE spend_quartile
        WHEN 1 THEN 'Tier 1 - Platinum VIP (Top 25%)'
        WHEN 2 THEN 'Tier 2 - Gold High-Value'
        WHEN 3 THEN 'Tier 3 - Silver Mid-Tier'
        WHEN 4 THEN 'Tier 4 - Bronze Entry-Tier'
    END AS tier_label,
    COUNT(user_pseudo_id) AS customer_count,
    ROUND(MIN(total_customer_spend_usd), 2) AS min_spend_usd,
    ROUND(MAX(total_customer_spend_usd), 2) AS max_spend_usd,
    ROUND(AVG(total_customer_spend_usd), 2) AS avg_spend_usd,
    ROUND(SUM(total_customer_spend_usd), 2) AS total_quartile_spend_usd,
    ROUND(
        SUM(total_customer_spend_usd) / (SELECT SUM(total_customer_spend_usd) FROM ranked_customers) * 100.0,
        2
    ) AS revenue_share_pct
FROM ranked_customers
GROUP BY spend_quartile
ORDER BY spend_quartile;
