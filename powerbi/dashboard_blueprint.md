# Power BI Dashboard Blueprint: Google Merchandise Store (GA4) Friction Analysis

## Executive Summary & Canvas Architecture
- **Target Report Name**: `GA4_Ecommerce_Friction_RCA.pbix`
- **Canvas Resolution**: Standard 16:9 Widescreen (`1920 x 1080 px`)
- **Visual Design System**: Material Light UI (`#1A73E8` Primary Google Blue, `#0F9D58` Success Green, `#DB4437` Alert Red, `#F4B400` Caution Amber, `#202124` Dark Charcoal Neutral)
- **Target Audience**: VP of Product, Head of E-Commerce, Lead Checkout Product Manager, Growth Marketing Leads

---

## Page 1: Executive KPI Performance & Top-Line Overview
**Objective**: Provide senior leadership with an immediate pulse on the 6 Core Product KPIs across September, October, and November 2026, highlighting the top-line conversion drop.

### 1. Global Slicer Header (Top Banner: Y 0–90 px)
- **Date Range Slicer**: `event_date` (Between slider: Sep 1, 2026 – Nov 25, 2026)
- **Month Slicer**: Horizontal tile buttons (`Sep 2026`, `Oct 2026`, `Nov 2026`)
- **Device Segment Slicer**: Multi-select pill buttons (`Desktop`, `Mobile`, `Tablet`)
- **User Cohort Slicer**: (`All Users`, `New Users`, `Returning Users`)

### 2. Core KPI Scorecard Cards (Y 105–215 px, 6 Equal Columns)
1. **Total Sessions**: `[Total Sessions]` | 100.0K | Subtitle: Storewide Traffic Volume
2. **Overall Conversion Rate %**: `[Overall Conversion Rate %]` | 8.87% | Dynamic MoM indicator (-1.41% pts in Nov)
3. **Cart-to-Checkout Rate %**: `[Cart-to-Checkout Rate %]` | 58.28% | Steady baseline
4. **Checkout Abandonment Rate %**: `[Checkout Abandonment Rate %]` | 46.54% | Red highlight in Nov (spiked to 53.4%)
5. **Total Revenue**: `[Total Revenue]` | $787,832 | Formatted in USD Currency
6. **Average Order Value (AOV)**: `[Average Order Value]` | $88.82 | MoM stability check ($88.60 vs $89.04)

### 3. Visual Layout Grid (Y 230–1040 px)
- **Visual 1.1 (Top-Left, 60% Width)**: **Weekly Conversion Rate & Revenue Trend (Combo Chart)**
  - *X-Axis*: `week_start_date`
  - *Column Y-Axis*: `[Total Revenue]` (Bars in `#1A73E8`)
  - *Line Y-Axis*: `[Overall Conversion Rate %]` (Line in `#DB4437` with data points)
  - *Storytelling Annotation*: Explicit callout card pinned at Week of Nov 2: *"Mobile address validation bug deployed; conversion declines from 9.4% to 7.8%"*
- **Visual 1.2 (Top-Right, 40% Width)**: **Monthly MoM Waterfall Bridge**
  - *Breakdown*: Sep Gross Revenue -> Oct Traffic Expansion (+13.5%) -> Nov Conversion Friction Leakage (-18.2%) -> Nov Ending Gross Revenue
- **Visual 1.3 (Bottom-Left, 50% Width)**: **Marketing Channel Acquisition Matrix (Clustered Bar Chart)**
  - *Y-Axis*: `traffic_source` (`organic`, `direct`, `paid_search`, `referral`, `email`)
  - *X-Axis 1*: `[Total Revenue]`
  - *Tooltips*: `[Overall Conversion Rate %]`, `[Revenue Per Session]`, `[Total Sessions]`
- **Visual 1.4 (Bottom-Right, 50% Width)**: **Geographic Market Efficiency Table (Matrix Visual)**
  - *Rows*: `country` (United States, United Kingdom, Canada, Germany, etc.)
  - *Values*: `[Total Sessions]`, `[Stage 4 Purchase Sessions]`, `[Overall Conversion Rate %]`, `[Total Revenue]`, `[Average Order Value]`
  - *Conditional Formatting*: Color scale data bars on Conversion Rate and Data Bars on Revenue.

---

## Page 2: Four-Stage Funnel & Mobile Checkout Friction RCA
**Objective**: The core diagnostic deep-dive. Quantify the step-by-step drop-off across the 4 stages and prove that elevated `shipping_step_error` on mobile devices caused the conversion crash.

### 1. Funnel Breakdown & Device Comparison (Top Half: Y 105–550 px)
- **Visual 2.1 (Left, 50% Width)**: **The 4-Stage Storewide Funnel Visual**
  - *Stages*:
    1. `Stage 1: View Item` (79,481 sessions | 100.0% of viewers)
    2. `Stage 2: Add to Cart` (28,474 sessions | 35.82% step conversion)
    3. `Stage 3: Begin Checkout` (16,595 sessions | 58.28% step conversion)
    4. `Stage 4: Purchase` (8,870 sessions | 53.45% checkout completion)
  - *Card Overlays*: Drop-off percentages between stages (64.18% drop at carting, 41.72% drop at checkout, 46.55% drop at purchase).
- **Visual 2.2 (Right, 50% Width)**: **Checkout Completion Rate by Device Category across Months (Clustered Column Chart)**
  - *X-Axis*: `month_name` (Sep, Oct, Nov)
  - *Series*: `device_category` (Desktop, Mobile, Tablet)
  - *Y-Axis*: `[Checkout-to-Purchase Conversion %]`
  - *Insight Highlight*: Desktop stays completely flat at ~62% in Sep, Oct, Nov. Tablet stays stable at ~54%. Mobile collapses from 58.2% (Sep) and 56.9% (Oct) down to 31.5% (Nov).

### 2. Root-Cause Verification: The Shipping Step Error (Bottom Half: Y 570–1040 px)
- **Visual 2.3 (Left, 50% Width)**: **Shipping Step Validation Error Rate % vs. Abandonment (Dual-Axis Area Chart)**
  - *X-Axis*: `event_date` (Daily aggregation)
  - *Area 1 (Left Y-Axis)*: `[Mobile Shipping Step Error Rate %]` (Shaded in light red `#FCE8E6`, stroke `#DB4437`)
  - *Line 2 (Right Y-Axis)*: `[Mobile Checkout Abandonment Rate %]` (Line in `#C5221F`)
  - *Proof Point*: Near-perfect correlation ($r > 0.94$) between shipping validation errors and abandoned mobile carts starting November 1.
- **Visual 2.4 (Right, 50% Width)**: **Error Impact Revenue Bridge & Cohort Loss Table**
  - Clean Checkout Flow vs. Encountered Shipping Error:
    - Clean Mobile Checkout: 58.4% completion rate | $86.20 AOV
    - Mobile Checkout with Error: 12.1% completion rate | $81.40 AOV
    - **Total Net Lost Revenue**: **$68,400+** in November alone directly attributable to this defect.

---

## Page 3: Product Category & Channel Opportunity Matrix
**Objective**: Merchandising revenue leakage analysis and prioritized remediation opportunities.

### 1. Merchandising Leakage Grid (Top Half: Y 105–550 px)
- **Visual 3.1 (Left, 55% Width)**: **Cart Revenue Leakage by Category (Stacked Bar Chart)**
  - *Y-Axis*: `item_category` (`Apparel`, `Electronics`, `Bags`, `Lifestyle`, `Drinkware`, `Office`)
  - *X-Axis*: Realized Revenue (Green) vs. Abandoned Cart Value (Red)
  - *Takeaway*: Apparel ($142K+ abandoned) and Electronics ($128K+ abandoned) suffer the highest absolute dollar leakage due to higher item price points and sizing/accessory uncertainty.
- **Visual 3.2 (Right, 45% Width)**: **Top 10 High-Friction Products (Ranked Table Visual)**
  - *Columns*: Product Name, Category, Unit Price, Units Added to Cart, Units Purchased, Item Conversion %, Abandoned Cart Value ($)
  - *Highlighted Rows*: Pixel Active ANC Buds ($119.00), Commuter Anti-Theft Backpack ($88.00), Heritage Zip Hoodie ($68.00).

### 2. Customer Cohorts & Revenue Recovery Sensitivity (Bottom Half: Y 570–1040 px)
- **Visual 3.3 (Left, 45% Width)**: **New vs. Returning Cohort Dynamics (Donut + KPI Gauge)**
  - Returning visitors represent 28.0% of traffic but drive **36.2% of gross revenue** with a **10.8% conversion rate** (vs. 8.1% for new visitors) and an AOV of **$98.40** (vs. $84.20).
- **Visual 3.4 (Right, 55% Width)**: **Interactive What-If Sensitivity Matrix (Parameter Grid)**
  - Dynamic slider allowing leadership to toggle: *Mobile Conversion Lift (+1.0%, +2.0%, +3.0%, +5.0%)*.
  - Displays dynamic cards:
    - *Recovered Monthly Orders*: +42 to +210 orders/mo
    - *Recovered Monthly Revenue*: +$3,465 to +$17,325/mo
    - *Annualized Revenue Opportunity*: **+$41,580 to +$207,900/year**
