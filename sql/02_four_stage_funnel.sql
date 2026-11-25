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
