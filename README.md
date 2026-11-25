# 🛒 Google Merchandise Store (GA4) Telemetry Analysis
### Why Did Online Sales Drop 1.41%? (A 100,000-Session E-Commerce Investigation)

[![Dataset: 100,000 Sessions](https://img.shields.io/badge/Dataset-100%2C000_Sessions-1A73E8?style=flat&logo=googleanalytics&logoColor=white)](data/ga4_sessions.csv)
[![Products Analyzed: 50,000 Items](https://img.shields.io/badge/Interactions-50%2C000_Items-0F9D58?style=flat)](data/ga4_product_items.csv)
[![SQL Queries: 12 Verified](https://img.shields.io/badge/SQL_Queries-12_Verified_DuckDB-F4B400?style=flat&logo=postgresql&logoColor=white)](sql/query_results.md)
[![Excel Financial Model](https://img.shields.io/badge/Excel-5--Tab_Model-107C41?style=flat&logo=microsoftexcel&logoColor=white)](excel/GA4_Business_Analysis_Model.xlsx)
[![Power BI Blueprints](https://img.shields.io/badge/Power_BI-3--Page_Blueprints_%2B_DAX-DB4437?style=flat&logo=powerbi&logoColor=white)](powerbi/dashboard_blueprint.md)
[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-white?style=flat&logo=github&logoColor=black)](https://github.com/Eternal9294f/google-merchandise-ga4-friction-rca)

---

## 📌 1. The Problem We Solved

Between September and November 2026, the **Google Merchandise Store** experienced an unexpected **1.41 percentage point drop in storewide conversion rate** (plunging from **9.24% in October** to **7.83% in November**). 

At first glance, high-level dashboards made it look like holiday marketing campaigns were failing or users were losing interest. But that didn't make sense:
* **Shopper interest was strong**: Traffic was steady (~30,000 sessions/month) and users were adding items to their carts at healthy rates (~35.8%).
* **The revenue impact was massive**: Over **$68,400 in gross merchandise sales vanished** in November alone during what should have been peak holiday shopping.

**The Core Business Question:**  
*Where in the buying journey were shoppers getting stuck, why did checkout drop-offs spike in November, and what exact product fix will recover this lost revenue?*

---

## 📊 2. What We Did

We audited **100,000 e-commerce sessions** and **50,000 product-level interactions** spanning September 1, 2026 through November 25, 2026, using industry-standard GA4 BigQuery e-commerce schemas.

1. **Reconstructed the 4-Stage Funnel**: Tracked every session step-by-step from `View Item` ➔ `Add to Cart` ➔ `Begin Checkout` ➔ `Purchase`.
2. **Executed 12 Analytical SQL Queries**: Queried the 100,000 rows using DuckDB (window functions, `LAG()`, `NTILE()`, and device cohorts) to pinpoint the exact failure point.
3. **Engineered an Excel Financial Model**: Built a 5-tab financial workbook with dynamic `COUNTIFS`/`SUMIFS`, metric governance, and a live What-If sensitivity table.
4. **Designed a 3-Page Power BI Blueprint**: Created an executive visual blueprint with Google Material styling (`#1A73E8`, `#0F9D58`, `#DB4437`), copy-paste DAX measures, and a custom theme.
5. **Formulated Prioritized Recommendations**: Evaluated solutions using the **RICE framework** (Reach, Impact, Confidence, Effort) to give engineering clear guidance.

---

## 🖼️ 3. The 3 Dashboard Blueprints

### Page 1: Executive KPI Overview (The Top-Line Pulse)
> Tracks the health of storewide traffic, conversion rates, and gross revenue across marketing channels and international markets.

* **Top KPI Scorecards**: 6 core metric cards showing Total Sessions (100K), Conversion Rate (8.87%), Cart-to-Checkout (58.28%), Checkout Abandonment (46.55%), Total Revenue ($787.8K), and AOV ($88.82).
* **Weekly Trajectory Chart**: Dual-axis visual pinpointing the exact week in early November when conversion crashed.
* **Channel Acquisition Matrix**: Compares Organic, Direct, Paid Search, Referral, and Email conversion efficiency.
* **Geographic Market Table**: Analyzes session volume and average order values across the US, UK, Canada, Germany, and 4 other global markets.

---

### Page 2: Four-Stage Funnel & Mobile Friction RCA (Finding the Cause)
> Pinpoints the exact step where users dropped off and proves why mobile devices suffered the conversion crash.

* **4-Stage Visual Funnel**: Visualizes volume drop from 79.5K viewers ➔ 28.5K cart additions ➔ 16.6K checkout starts ➔ 8.87K purchases.
* **Device Checkout Drop Comparison**: Shows Desktop completion holding perfectly steady at **~62%**, while Mobile crashes from **56.9% to 31.5%** in November.
* **The Root Cause (Validation Error Surge)**: Proves that client-side address validation errors (`shipping_step_error`) surged from **5.0% to 28.3%** on mobile web.
* **Lost Revenue Card**: Quantifies the direct $62,300+ revenue loss resulting from the address validation defect.

---

### Page 3: Product Category & Channel Opportunity Matrix (The Financial Levers)
> Shows which product lines suffered the highest dollar leakage and models the revenue recovered from fixing the mobile bug.

* **Category Cart Leakage Chart**: Details why Apparel ($143K abandoned) and Electronics ($129K abandoned) suffered the biggest lost cart values.
* **Top 10 High-Friction Products Table**: Identifies high-consideration items like *Pixel Active ANC Buds* ($119.00) and *Heritage Zip Hoodie* ($68.00) that users repeatedly abandon.
* **New vs. Returning Cohort Analysis**: Demonstrates that returning shoppers convert at **10.8%** with a higher AOV ($98.40) versus first-time visitors (8.1% and $84.20).
* **What-If Sensitivity Matrix**: Interactive model demonstrating how lifting mobile checkout conversion by +1% to +5% recovers **+$41,580 to +$207,900 annually**.

---

## 🔍 4. What We Found Out (Key Insights in Plain English)

### 1. The Conversion Drop Was 100% Isolated to Mobile Devices
* **Desktop shoppers were completely unaffected**: Desktop checkout completion remained virtually flat (**62.01% in Sep, 62.62% in Oct, and 62.09% in Nov**).
* **Tablet shoppers were also steady**: Tablet checkout held flat at **53.75%**.
* **Mobile checkout completely collapsed**: Mobile completion plunged by **25.37 percentage points** (from **56.87% in October** down to **31.50% in November**).

### 2. The Smoking Gun: A Silent Address Validation Bug
* In early November, a front-end script update caused an unhandled regex validation failure on mobile address forms (`shipping_step_error`).
* Mobile shipping errors skyrocketed from **5.00% in October** to **28.31% in November** (a **5.7x increase**).
* Shoppers who encountered this error had only a **12.06% completion rate** (compared to **54.80%** for error-free mobile checkouts). Over 87% gave up and abandoned their carts.

### 3. $62,300+ in Direct Revenue Was Lost
* Mobile sessions hitting this error directly cost the business **$45,699.20** in lost sales in November alone.
* Across the full 3 months, checkout validation errors burned **$62,336.68 in lost gross revenue**.

### 4. Apparel & Electronics Suffered the Largest Dollar Abandonment
* **Apparel carts lost $143,448**: Sizing questions combined with checkout friction caused shoppers to abandon high-priced hoodies and jackets.
* **Electronics carts lost $129,584**: High-ticket accessories (e.g., Pixel Buds at $119.00) had strong purchase intent but high cart abandonment when checkout forms threw validation errors.

### 5. Returning Shoppers Are the Store's Most Valuable Asset
* Returning shoppers made up **28.0% of sessions** but generated **36.2% of total revenue**.
* They converted at **10.8%** (compared to 8.1% for new visitors) and spent **$98.40 per order** (compared to $84.20 for new buyers).

---

## 💡 5. What Should Google Merchandise Store Do? (3 Prioritized Solutions)

Using the **RICE Framework** (*Reach, Impact, Confidence, Effort*), we prioritized the product backlog to stop revenue leakage:

```
RICE Score = (Reach × Impact × Confidence) / Effort
```

| Priority | Product Recommendation | Target Metric | Reach (Monthly) | Impact | Confidence | Effort | RICE Score |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| **#1 (P0)** | **Mobile Address Autocomplete & Flexible Validation Hotfix** | Mobile Checkout Conv % | 4,200 checkouts | 3.0 (Massive) | 100% | 1 week | **12,600** |
| **#2 (P1)** | **One-Click Express Checkout (Google Pay / Apple Pay)** | Mobile Cart-to-Purchase % | 3,800 mobile carts | 2.0 (High) | 80% | 2 weeks | **3,040** |
| **#3 (P2)** | **Automated Cart Abandonment Recovery for Apparel & Electronics** | Cart Value Recovery | 1,850 cart drops | 1.0 (Medium) | 90% | 1.5 weeks | **1,110** |

### Solution 1: Immediate Hotfix for Mobile Address Validation (Priority 1 - P0)
* **The Problem**: Mobile keyboard autofill triggers regex mismatches on postal codes and street lines, blocking 28.3% of mobile shoppers with modal errors.
* **The Fix**: Deploy Google Places Address Autocomplete API, allow flexible international postal formats, and replace blocking alerts with inline helper text.
* **Expected Result**: Recovers **+$125,000 to +$200,000 in annualized gross revenue** within 7 days of deployment.

### Solution 2: One-Click Express Checkout (Priority 2 - P1)
* **The Problem**: 41.7% of all cart additions abandon before completing the multi-step checkout form.
* **The Fix**: Place Google Pay and Apple Pay express buttons directly on product pages and inside the cart drawer, allowing mobile users to bypass shipping address forms entirely.
* **Expected Result**: Increases mobile checkout progression by +3.5% and eliminates manual typing friction.

### Solution 3: Triggered Abandoned Cart Recovery (Priority 3 - P2)
* **The Problem**: Over $272,000 in high-margin Apparel and Electronics merchandise sits abandoned in carts.
* **The Fix**: Send automated email/SMS reminders within 60 minutes for abandoned carts over $75, featuring one-click checkout links and real-time inventory reservation notices.
* **Expected Result**: A conservative 8–12% recovery rate reclaims **+$21,000 to +$32,000 in lost revenue every quarter**.

---

## 📈 6. Core Product KPIs At a Glance (The 6 Defined Metrics)

| Metric ID | Core Product KPI | What It Measures | Sep 2026 | Oct 2026 | Nov 2026 | Full Period Total | Nov vs Oct Trend |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| **KPI-01** | **Total Sessions** | Storewide browsing traffic volume | 33,028 | 37,015 | 29,957 | **100,000** | -19.1% (25 days) |
| **KPI-02** | **Overall Conversion Rate %** | % of sessions completing a purchase | 9.07% | 9.24% | **7.83%** | **8.87%** | **-1.41% pts** ⚠️ |
| **KPI-03** | **Cart-to-Checkout Rate %** | % of carts advancing to checkout | 58.48% | 58.28% | 58.07% | **58.28%** | -0.21% pts (Stable) |
| **KPI-04** | **Checkout Abandonment Rate %** | % of checkouts that fail to buy | 45.42% | 45.18% | **53.40%** | **46.55%** | **+8.22% pts** 🚨 |
| **KPI-05** | **Total Gross Revenue** | Dollar sum of completed orders | $264,196 | $314,630 | $209,006 | **$787,832** | -$105.6K |
| **KPI-06** | **Average Order Value (AOV)** | Average dollar spend per purchase | $88.21 | $88.82 | $89.04 | **$88.82** | +$0.22 (Stable) |

---

## 📂 7. Repository Structure

```text
├── data/
│   ├── ga4_sessions.csv                 <- 100,000 raw GA4 telemetry rows (Sep 1 – Nov 25, 2026)
│   └── ga4_product_items.csv            <- 50,000 product-level interaction rows
├── excel/
│   └── GA4_Business_Analysis_Model.xlsx <- 5-tab financial model with live formulas & sensitivity
├── sql/
│   ├── 01_executive_monthly_kpis.sql    <- Monthly trends & MoM change using LAG()
│   ├── 02_four_stage_funnel.sql         <- 4-stage funnel conversion & drop-off %
│   ├── 03_device_funnel_rca.sql         <- Root-cause segmentation by device & month
│   ├── 04_channel_acquisition_roi.sql   <- Traffic source efficiency & revenue per session
│   ├── 05_new_vs_returning_cohorts.sql  <- Cohort progression & AOV comparison
│   ├── 06_category_revenue_leakage.sql  <- Department cart abandonment & leakage share
│   ├── 07_top_abandoned_products.sql    <- Top 10 products ranked by lost cart value
│   ├── 08_day_of_week_patterns.sql      <- Day-of-week purchasing behavior
│   ├── 09_checkout_error_impact.sql     <- Quantified dollar loss from shipping errors
│   ├── 10_high_value_user_segmentation.sql <- Customer spend quartiles via NTILE(4)
│   ├── 11_weekly_conversion_trend.sql   <- Weekly trajectory isolating friction onset
│   ├── 12_country_tier_performance.sql  <- International geographic efficiency
│   └── query_results.md                 <- Complete audit log with exact tabular outputs
├── powerbi/
│   ├── dashboard_blueprint.md           <- 3-page executive wireframe & layout spec
│   ├── dax_measures.txt                 <- Ready-to-paste DAX formulas for all KPIs
│   └── theme.json                       <- Custom Google Material UI executive theme
└── README.md                            <- Master portfolio project documentation
```

---

## 📬 Contact & Discussion

Have questions about this analysis, the root-cause methodology, or how to adapt these GA4 e-commerce models for your product? Feel free to open an issue or connect!

- **Analyst**: Portfolio Project — E-Commerce Growth & Product Analytics
- **Tools Used**: GA4 Telemetry, SQL (DuckDB/PostgreSQL), Microsoft Excel (Financial Modeling), Power BI (DAX & Visualization)
- **Methodology**: 4-Stage Conversion Funnel, Cohort Segmentation, Root-Cause Diagnostics, RICE Prioritization Framework
