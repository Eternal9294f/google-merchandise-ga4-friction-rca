-- =====================================================================
-- 07_top_abandoned_products.sql
-- Business Question: What are the top 10 specific product items suffering the
-- greatest dollar volume of abandoned cart value?
-- =====================================================================

WITH product_leakage AS (
    SELECT
        item_id,
        item_name,
        item_category,
        item_price_usd,
        SUM(CASE WHEN added_to_cart = 1 THEN quantity ELSE 0 END) AS units_added_to_cart,
        SUM(CASE WHEN purchased = 1 THEN quantity ELSE 0 END) AS units_purchased,
        ROUND(SUM(CASE WHEN added_to_cart = 1 AND purchased = 0 THEN item_price_usd * quantity ELSE 0.0 END), 2) AS abandoned_cart_value_usd,
        ROUND(SUM(CASE WHEN purchased = 1 THEN item_revenue_usd ELSE 0.0 END), 2) AS realized_revenue_usd
    FROM read_csv_auto('data/ga4_product_items.csv')
    GROUP BY item_id, item_name, item_category, item_price_usd
),
ranked_products AS (
    SELECT
        *,
        ROUND(CAST(units_purchased AS DOUBLE) / NULLIF(units_added_to_cart, 0) * 100.0, 2) AS item_conversion_rate_pct,
        RANK() OVER (ORDER BY abandoned_cart_value_usd DESC) AS leakage_rank
    FROM product_leakage
)
SELECT
    leakage_rank,
    item_id,
    item_name,
    item_category,
    item_price_usd,
    units_added_to_cart,
    units_purchased,
    item_conversion_rate_pct,
    abandoned_cart_value_usd,
    realized_revenue_usd
FROM ranked_products
WHERE leakage_rank <= 10
ORDER BY leakage_rank;
