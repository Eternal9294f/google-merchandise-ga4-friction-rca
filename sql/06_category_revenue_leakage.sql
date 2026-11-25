-- =====================================================================
-- 06_category_revenue_leakage.sql
-- Business Question: Which merchandise product categories suffer the largest
-- absolute cart abandonment and revenue leakage?
-- =====================================================================

WITH category_metrics AS (
    SELECT
        item_category,
        COUNT(session_id) AS total_item_interactions,
        SUM(CASE WHEN added_to_cart = 1 THEN 1 ELSE 0 END) AS cart_additions,
        SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) AS units_purchased,
        ROUND(SUM(CASE WHEN purchased = 1 THEN item_revenue_usd ELSE 0.0 END), 2) AS realized_revenue_usd,
        ROUND(SUM(CASE WHEN added_to_cart = 1 AND purchased = 0 THEN item_price_usd * quantity ELSE 0.0 END), 2) AS abandoned_cart_value_usd
    FROM read_csv_auto('data/ga4_product_items.csv')
    GROUP BY item_category
)
SELECT
    item_category,
    total_item_interactions,
    cart_additions,
    units_purchased,
    ROUND(CAST(units_purchased AS DOUBLE) / NULLIF(cart_additions, 0) * 100.0, 2) AS cart_to_purchase_conv_pct,
    ROUND((1.0 - CAST(units_purchased AS DOUBLE) / NULLIF(cart_additions, 0)) * 100.0, 2) AS cart_abandonment_pct,
    realized_revenue_usd,
    abandoned_cart_value_usd,
    ROUND(abandoned_cart_value_usd / NULLIF(realized_revenue_usd + abandoned_cart_value_usd, 0) * 100.0, 2) AS leakage_share_pct
FROM category_metrics
ORDER BY abandoned_cart_value_usd DESC;
