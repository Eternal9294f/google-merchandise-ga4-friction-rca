# Google Merchandise Store (GA4) — SQL Business Intelligence Query Audit Log

This document records the exact execution logs and tabular outputs for all 12 analytical SQL queries run against the complete 100,000-session dataset (`ga4_sessions.csv`) and 50,000-product interaction dataset (`ga4_product_items.csv`).

- **Engine**: DuckDB in-memory analytical OLAP engine
- **Dataset Scope**: 100,000 sessions (1 Sep 2026 - 25 Nov 2026)
- **Execution Status**: All 12 queries verified with 0 errors.

---

## 01_executive_monthly_kpis.sql

```sql
-- =====================================================================
-- 01_executive_monthly_kpis.sql
-- Business Question: How did top-line store performance evolve month-over-month
-- across sessions, conversion efficiency, gross revenue, and AOV?
-- =====================================================================

WITH monthly_aggregates AS (
    SELECT
        month_name,
        CASE month_name
            WHEN 'Sep' THEN 9
            WHEN 'Oct' THEN 10
            WHEN 'Nov' THEN 11
        END AS month_num,
        COUNT(session_id) AS total_sessions,
        SUM(purchased) AS total_buyers,
        ROUND(CAST(SUM(purchased) AS DOUBLE) / COUNT(session_id) * 100.0, 2) AS conversion_rate_pct,
        ROUND(SUM(order_revenue_usd), 2) AS total_revenue_usd,
        ROUND(SUM(order_revenue_usd) / NULLIF(SUM(purchased), 0), 2) AS aov_usd
    FROM read_csv_auto('data/ga4_sessions.csv')
    GROUP BY month_name, month_num
)
SELECT
    month_name,
    total_sessions,
    total_buyers,
    conversion_rate_pct,
    total_revenue_usd,
    aov_usd,
    ROUND(
        (conversion_rate_pct - LAG(conversion_rate_pct) OVER (ORDER BY month_num)),
        2
    ) AS cr_mom_diff_pts,
    ROUND(
        (total_revenue_usd - LAG(total_revenue_usd) OVER (ORDER BY month_num)) / 
        LAG(total_revenue_usd) OVER (ORDER BY month_num) * 100.0,
        2
    ) AS revenue_mom_pct
FROM monthly_aggregates
ORDER BY month_num;
```

**Query Execution Output:**

| month_name | total_sessions | total_buyers | conversion_rate_pct | total_revenue_usd | aov_usd | cr_mom_diff_pts | revenue_mom_pct |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sep | 33000 | 3295.0 | 9.98 | 289273.47 | 87.79 | nan | nan |
| Oct | 37012 | 3656.0 | 9.88 | 319225.09 | 87.32 | -0.1 | 10.35 |
| Nov | 29988 | 2291.0 | 7.64 | 199541.01 | 87.1 | -2.24 | -37.49 |

---

## 02_four_stage_funnel.sql

```sql
-- =====================================================================
-- 02_four_stage_funnel.sql
-- Business Question: Where are users dropping off across the 4-stage funnel,
-- and what are the exact step-to-step and cumulative conversion efficiencies?
-- =====================================================================

WITH raw_counts AS (
    SELECT
        COUNT(session_id) AS stage_0_all_sessions,
        SUM(viewed_item) AS stage_1_view_item,
        SUM(added_to_cart) AS stage_2_add_to_cart,
        SUM(began_checkout) AS stage_3_begin_checkout,
        SUM(purchased) AS stage_4_purchase
    FROM read_csv_auto('data/ga4_sessions.csv')
)
SELECT
    'Stage 1: View Item' AS funnel_stage,
    stage_1_view_item AS session_count,
    ROUND(CAST(stage_1_view_item AS DOUBLE) / stage_0_all_sessions * 100.0, 2) AS step_to_step_conv_pct,
    ROUND(CAST(stage_1_view_item AS DOUBLE) / stage_0_all_sessions * 100.0, 2) AS cumulative_conv_pct,
    ROUND(100.0 - (CAST(stage_1_view_item AS DOUBLE) / stage_0_all_sessions * 100.0), 2) AS drop_off_pct
FROM raw_counts

UNION ALL

SELECT
    'Stage 2: Add to Cart' AS funnel_stage,
    stage_2_add_to_cart AS session_count,
    ROUND(CAST(stage_2_add_to_cart AS DOUBLE) / stage_1_view_item * 100.0, 2) AS step_to_step_conv_pct,
    ROUND(CAST(stage_2_add_to_cart AS DOUBLE) / stage_0_all_sessions * 100.0, 2) AS cumulative_conv_pct,
    ROUND(100.0 - (CAST(stage_2_add_to_cart AS DOUBLE) / stage_1_view_item * 100.0), 2) AS drop_off_pct
FROM raw_counts

UNION ALL

SELECT
    'Stage 3: Begin Checkout' AS funnel_stage,
    stage_3_begin_checkout AS session_count,
    ROUND(CAST(stage_3_begin_checkout AS DOUBLE) / stage_2_add_to_cart * 100.0, 2) AS step_to_step_conv_pct,
    ROUND(CAST(stage_3_begin_checkout AS DOUBLE) / stage_0_all_sessions * 100.0, 2) AS cumulative_conv_pct,
    ROUND(100.0 - (CAST(stage_3_begin_checkout AS DOUBLE) / stage_2_add_to_cart * 100.0), 2) AS drop_off_pct
FROM raw_counts

UNION ALL

SELECT
    'Stage 4: Purchase' AS funnel_stage,
    stage_4_purchase AS session_count,
    ROUND(CAST(stage_4_purchase AS DOUBLE) / stage_3_begin_checkout * 100.0, 2) AS step_to_step_conv_pct,
    ROUND(CAST(stage_4_purchase AS DOUBLE) / stage_0_all_sessions * 100.0, 2) AS cumulative_conv_pct,
    ROUND(100.0 - (CAST(stage_4_purchase AS DOUBLE) / stage_3_begin_checkout * 100.0), 2) AS drop_off_pct
FROM raw_counts;
```

**Query Execution Output:**

| funnel_stage | session_count | step_to_step_conv_pct | cumulative_conv_pct | drop_off_pct |
| --- | --- | --- | --- | --- |
| Stage 1: View Item | 81276.0 | 81.28 | 81.28 | 18.72 |
| Stage 2: Add to Cart | 27530.0 | 33.87 | 27.53 | 66.13 |
| Stage 3: Begin Checkout | 15916.0 | 57.81 | 15.92 | 42.19 |
| Stage 4: Purchase | 9242.0 | 58.07 | 9.24 | 41.93 |

---

## 03_device_funnel_rca.sql

```sql
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
```

**Query Execution Output:**

| month_name | month_num | device_category | total_sessions | checkout_sessions | purchased_sessions | checkout_to_purch_conv_pct | checkout_abandonment_pct | total_shipping_errors | shipping_error_rate_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Sep | 9 | desktop | 17210 | 2734.0 | 1774.0 | 64.89 | 35.11 | 67.0 | 2.45 |
| Sep | 9 | mobile | 13103 | 2123.0 | 1286.0 | 60.57 | 39.43 | 92.0 | 4.33 |
| Sep | 9 | tablet | 2687 | 421.0 | 235.0 | 55.82 | 44.18 | 10.0 | 2.38 |
| Oct | 10 | desktop | 19152 | 3020.0 | 1995.0 | 66.06 | 33.94 | 68.0 | 2.25 |
| Oct | 10 | mobile | 14832 | 2379.0 | 1361.0 | 57.21 | 42.79 | 136.0 | 5.72 |
| Oct | 10 | tablet | 3028 | 519.0 | 300.0 | 57.8 | 42.2 | 10.0 | 1.93 |
| Nov | 11 | desktop | 15441 | 2419.0 | 1574.0 | 65.07 | 34.93 | 44.0 | 1.82 |
| Nov | 11 | mobile | 12140 | 1924.0 | 516.0 | 26.82 | 73.18 | 586.0 | 30.46 |
| Nov | 11 | tablet | 2407 | 377.0 | 201.0 | 53.32 | 46.68 | 15.0 | 3.98 |

---

## 04_channel_acquisition_roi.sql

```sql
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
```

**Query Execution Output:**

| traffic_source | total_sessions | total_purchases | conversion_rate_pct | total_revenue_usd | aov_usd | revenue_per_session_usd |
| --- | --- | --- | --- | --- | --- | --- |
| organic | 35045 | 3209.0 | 9.16 | 278843.59 | 86.89 | 7.96 |
| direct | 24956 | 2294.0 | 9.19 | 199944.36 | 87.16 | 8.01 |
| paid_search | 20138 | 1858.0 | 9.23 | 165072.0 | 88.84 | 8.2 |
| referral | 11978 | 1130.0 | 9.43 | 99486.31 | 88.04 | 8.31 |
| email | 7883 | 751.0 | 9.53 | 64693.31 | 86.14 | 8.21 |

---

## 05_new_vs_returning_cohorts.sql

```sql
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
```

**Query Execution Output:**

| user_type | total_sessions | share_of_sessions_pct | view_rate_pct | cart_rate_pct | checkout_rate_pct | checkout_to_purch_conv_pct | overall_conv_rate_pct | total_revenue_usd | aov_usd |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| returning | 27842 | 27.8 | 89.66 | 37.39 | 63.2 | 62.08 | 13.16 | 365366.9 | 99.75 |
| new | 72158 | 72.2 | 78.04 | 32.31 | 55.05 | 55.7 | 7.73 | 442672.67 | 79.35 |

---

## 06_category_revenue_leakage.sql

```sql
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
```

**Query Execution Output:**

| item_category | total_item_interactions | cart_additions | units_purchased | cart_to_purchase_conv_pct | cart_abandonment_pct | realized_revenue_usd | abandoned_cart_value_usd | leakage_share_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Electronics | 8026 | 8016.0 | 2680.0 | 33.43 | 66.57 | 276239.0 | 552257.0 | 66.66 |
| Bags | 8018 | 8003.0 | 2703.0 | 33.77 | 66.23 | 237712.0 | 460593.0 | 65.96 |
| Apparel | 10028 | 10010.0 | 3382.0 | 33.79 | 66.21 | 221256.0 | 443932.0 | 66.74 |
| Lifestyle | 8018 | 8006.0 | 2662.0 | 33.25 | 66.75 | 92018.5 | 185340.0 | 66.82 |
| Office | 8041 | 8028.0 | 2722.0 | 33.91 | 66.09 | 94698.0 | 183425.5 | 65.95 |
| Drinkware | 7869 | 7852.0 | 2665.0 | 33.94 | 66.06 | 85060.0 | 169923.5 | 66.64 |

---

## 07_top_abandoned_products.sql

```sql
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
```

**Query Execution Output:**

| leakage_rank | item_id | item_name | item_category | item_price_usd | units_added_to_cart | units_purchased | item_conversion_rate_pct | abandoned_cart_value_usd | realized_revenue_usd |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | ELC-501 | Google Pixel Active ANC Wireless Buds | Electronics | 119.0 | 2428.0 | 840.0 | 34.6 | 188972.0 | 99960.0 |
| 2 | BAG-604 | Android Weekend Heavy-Duty Duffle Bag | Bags | 95.0 | 2518.0 | 846.0 | 33.6 | 158840.0 | 80370.0 |
| 3 | ELC-504 | Google High-Fidelity Bluetooth Speaker | Electronics | 89.0 | 2497.0 | 801.0 | 32.08 | 150944.0 | 71289.0 |
| 4 | APP-103 | Chrome Technical Softshell Jacket | Apparel | 92.0 | 2450.0 | 823.0 | 33.59 | 149684.0 | 75716.0 |
| 5 | BAG-601 | Google Commuter Anti-Theft Backpack | Bags | 88.0 | 2383.0 | 811.0 | 34.03 | 138336.0 | 71368.0 |
| 6 | ELC-503 | Android Smart Sensor Desk Lamp | Electronics | 78.0 | 2506.0 | 851.0 | 33.96 | 129090.0 | 66378.0 |
| 7 | BAG-602 | Chrome Weatherproof Urban Messenger | Bags | 74.0 | 2509.0 | 876.0 | 34.91 | 120842.0 | 64824.0 |
| 8 | APP-101 | Google Heritage Zip Hoodie | Apparel | 68.0 | 2574.0 | 829.0 | 32.21 | 118660.0 | 56372.0 |
| 9 | ELC-502 | Google Fast Multi-Port GaN Charger 65W | Electronics | 49.0 | 2487.0 | 788.0 | 31.68 | 83251.0 | 38612.0 |
| 10 | APP-102 | Android Everyday Crewneck | Apparel | 48.0 | 2456.0 | 833.0 | 33.92 | 77904.0 | 39984.0 |

---

## 08_day_of_week_patterns.sql

```sql
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
```

**Query Execution Output:**

| day_of_week_num | day_name | total_sessions | total_purchases | conversion_rate_pct | total_revenue_usd | aov_usd | revenue_per_session_usd |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | Sunday | 13975 | 1262.0 | 9.03 | 112965.47 | 89.51 | 8.08 |
| 1 | Monday | 13979 | 1250.0 | 8.94 | 109950.97 | 87.96 | 7.87 |
| 2 | Tuesday | 15046 | 1392.0 | 9.25 | 120718.19 | 86.72 | 8.02 |
| 3 | Wednesday | 15111 | 1411.0 | 9.34 | 122946.81 | 87.13 | 8.14 |
| 4 | Thursday | 14134 | 1389.0 | 9.83 | 119116.01 | 85.76 | 8.43 |
| 5 | Friday | 13802 | 1246.0 | 9.03 | 107408.35 | 86.2 | 7.78 |
| 6 | Saturday | 13953 | 1292.0 | 9.26 | 114933.77 | 88.96 | 8.24 |

---

## 09_checkout_error_impact.sql

```sql
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
```

**Query Execution Output:**

| device_category | checkout_experience | checkout_sessions | completed_orders | completion_rate_pct | realized_revenue_usd | estimated_lost_revenue_usd |
| --- | --- | --- | --- | --- | --- | --- |
| desktop | Clean Checkout Flow | 7994 | 5320.0 | 66.55 | 465986.27 | 0.0 |
| desktop | Encountered Shipping Error | 179 | 23.0 | 12.85 | 2026.25 | 8419.54 |
| mobile | Clean Checkout Flow | 5612 | 3056.0 | 54.45 | 266567.58 | 0.0 |
| mobile | Encountered Shipping Error | 814 | 107.0 | 13.14 | 9499.22 | 29328.73 |
| tablet | Clean Checkout Flow | 1282 | 732.0 | 57.1 | 63666.4 | 0.0 |
| tablet | Encountered Shipping Error | 35 | 4.0 | 11.43 | 293.85 | 1390.38 |

---

## 10_high_value_user_segmentation.sql

```sql
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
```

**Query Execution Output:**

| spend_quartile | tier_label | customer_count | min_spend_usd | max_spend_usd | avg_spend_usd | total_quartile_spend_usd | revenue_share_pct |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Tier 1 - Platinum VIP (Top 25%) | 2224 | 105.92 | 363.65 | 139.99 | 311331.1 | 38.53 |
| 2 | Tier 2 - Gold High-Value | 2224 | 81.25 | 105.91 | 92.41 | 205525.58 | 25.44 |
| 3 | Tier 3 - Silver Mid-Tier | 2223 | 66.66 | 81.24 | 73.3 | 162954.21 | 20.17 |
| 4 | Tier 4 - Bronze Entry-Tier | 2223 | 47.1 | 66.65 | 57.68 | 128228.68 | 15.87 |

---

## 11_weekly_conversion_trend.sql

```sql
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
```

**Query Execution Output:**

| week_start_date | total_sessions | checkout_sessions | completed_orders | overall_conv_rate_pct | checkout_to_purch_conv_pct | shipping_errors | shipping_error_rate_pct | total_revenue_usd | aov_usd |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-08-31 00:00:00 | 6555 | 1072.0 | 651.0 | 9.93 | 60.73 | 33.0 | 3.08 | 56984.77 | 87.53 |
| 2026-09-07 00:00:00 | 7920 | 1237.0 | 797.0 | 10.06 | 64.43 | 41.0 | 3.31 | 70748.44 | 88.77 |
| 2026-09-14 00:00:00 | 7647 | 1216.0 | 761.0 | 9.95 | 62.58 | 39.0 | 3.21 | 66243.74 | 87.05 |
| 2026-09-21 00:00:00 | 7562 | 1206.0 | 753.0 | 9.96 | 62.44 | 40.0 | 3.32 | 65581.79 | 87.09 |
| 2026-09-28 00:00:00 | 8024 | 1280.0 | 772.0 | 9.62 | 60.31 | 35.0 | 2.73 | 68757.77 | 89.06 |
| 2026-10-05 00:00:00 | 8406 | 1292.0 | 775.0 | 9.22 | 59.98 | 54.0 | 4.18 | 67332.51 | 86.88 |
| 2026-10-12 00:00:00 | 8299 | 1301.0 | 785.0 | 9.46 | 60.34 | 58.0 | 4.46 | 68944.51 | 87.83 |
| 2026-10-19 00:00:00 | 8282 | 1393.0 | 884.0 | 10.67 | 63.46 | 49.0 | 3.52 | 77397.71 | 87.55 |
| 2026-10-26 00:00:00 | 8486 | 1383.0 | 871.0 | 10.26 | 62.98 | 53.0 | 3.83 | 74967.48 | 86.07 |
| 2026-11-02 00:00:00 | 8381 | 1323.0 | 677.0 | 8.08 | 51.17 | 174.0 | 13.15 | 58649.97 | 86.63 |
| 2026-11-09 00:00:00 | 8437 | 1341.0 | 663.0 | 7.86 | 49.44 | 175.0 | 13.05 | 57769.9 | 87.13 |
| 2026-11-16 00:00:00 | 8345 | 1309.0 | 609.0 | 7.3 | 46.52 | 183.0 | 13.98 | 53391.6 | 87.67 |
| 2026-11-23 00:00:00 | 3656 | 563.0 | 244.0 | 6.67 | 43.34 | 94.0 | 16.7 | 21269.38 | 87.17 |

---

## 12_country_tier_performance.sql

```sql
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
```

**Query Execution Output:**

| country | total_sessions | session_share_pct | checkout_sessions | total_purchases | overall_conv_rate_pct | checkout_to_purch_conv_pct | total_revenue_usd | aov_usd |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| United States | 55065 | 55.06 | 8823.0 | 5102.0 | 9.27 | 57.83 | 445330.67 | 87.29 |
| United Kingdom | 11969 | 11.97 | 1869.0 | 1123.0 | 9.38 | 60.09 | 98425.95 | 87.65 |
| Canada | 9071 | 9.07 | 1456.0 | 864.0 | 9.52 | 59.34 | 76663.16 | 88.73 |
| Germany | 6936 | 6.94 | 1120.0 | 644.0 | 9.28 | 57.5 | 54642.91 | 84.85 |
| India | 6018 | 6.02 | 949.0 | 533.0 | 8.86 | 56.16 | 47451.37 | 89.03 |
| France | 3960 | 3.96 | 639.0 | 372.0 | 9.39 | 58.22 | 33223.18 | 89.31 |
| Australia | 3975 | 3.98 | 604.0 | 343.0 | 8.63 | 56.79 | 29611.55 | 86.33 |
| Japan | 3006 | 3.01 | 456.0 | 261.0 | 8.68 | 57.24 | 22690.78 | 86.94 |

---
