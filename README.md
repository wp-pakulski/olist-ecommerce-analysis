# Olist E-commerce Analysis — SQL, Python & Power BI

End-to-end analysis of the Brazilian marketplace **Olist** (~99k orders, 9 related tables, 2016–2018):
from raw CSVs through SQLite + SQL and pandas to a 3-page Power BI dashboard, ending with
quantified business recommendations.

**Business question:** what drives marketplace revenue, and what really threatens its scaling —
on the customer-retention side and the seller-quality side?

![Executive Summary](powerbi/screenshots/01_executive_summary.png)

*More dashboard pages: [Seller Performance](powerbi/screenshots/02_seller_performance.png) · [Customers & Delivery](powerbi/screenshots/03_customers_delivery.png)*

## Key findings

*All metrics computed on delivered orders (96,478 of 99,441 — 97% of volume).*

| Finding | Number |
|---|---|
| Total revenue / orders / AOV | 13.2M BRL / 96,478 / 137 BRL (median 87) |
| Revenue concentration (Pareto) | top 20% of sellers = **82.3%** of revenue |
| Customer retention | only **3.0%** of customers ever return (avg 1.03 orders/customer) |
| Delivery ↔ satisfaction | ≤7 days → **4.41★** vs >30 days → **2.18★**; the pain threshold is **~21 days** |
| Delivery geography | São Paulo 8.3 days vs northern states ~26–27 days (**~3× slower**) |
| Problem sellers | **343 (~11.6%)** rated below 3.5★ |

**The takeaway:** Olist is an efficient machine for *acquiring* and *selling* — but growth is
*bought*, not *built*. Retention barely exists, so every revenue unit requires continuous
marketing spend, and service quality is hostage to delivery time and a long tail of weak sellers.

➡️ **Full analysis with quantified recommendations:** [docs/business_conclusions.md](docs/business_conclusions.md)

## Sample visualizations

![Monthly revenue trend](reports/line_monthly_revenue.png)

![Orders heatmap](reports/heatmap_orders.png)

## Tech stack

- **SQL (SQLite)** — multi-table joins, window functions (`RANK`, `LAG`, `NTILE`), multi-CTE
  queries, cohort analysis, RFM segmentation
- **Python** — pandas (cleaning, KPI), matplotlib/seaborn (visualizations)
- **Power BI** — 3-page dashboard, DAX measures, data model over cleaned tables
- **Excel Power Query** — alternative cleaning pipeline

## Data model

![Entity-relationship diagram](docs/erd_olist.png)

## Project structure

```
portfolio-ecommerce/
├── data/                  # not in repo — see "How to reproduce"
│   ├── raw/               # 9 CSVs from Kaggle
│   ├── processed/         # cleaned CSVs (built by notebook 02)
│   └── olist.db           # SQLite database (built by notebooks 01–02)
├── notebooks/
│   ├── 01_import_data.ipynb      # CSV → SQLite
│   ├── 02_data_cleaning.ipynb    # types, dates, delivery_days, city typos, geo dedup
│   ├── 03_kpi_analysis.ipynb     # sales / logistics / satisfaction / retention KPIs
│   └── 04_visualizations.ipynb   # heatmap, boxplot, category ranking, revenue trend
├── sql/
│   ├── 01_eksploracja.sql             # data exploration
│   ├── 02_business_analysis.sql       # revenue trends, payments, logistics, retention
│   ├── 03_advanced_analysis.sql       # seller ranking, running totals, cohorts
│   └── 04_business_analysis_advanced.sql  # Pareto/ABC, SLA thresholds, problem sellers, RFM
├── powerbi/olist_dashboard.pbix
├── excel/olist_power_query.xlsx
├── docs/
│   ├── business_conclusions.md   # findings + recommendations
│   ├── erd_olist.drawio          # entity-relationship diagram (source)
│   └── erd_olist.png             # entity-relationship diagram (export)
└── reports/                      # exported charts (PNG)
```

## How to reproduce

1. Download the dataset from Kaggle:
   [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Place the 9 CSV files in `data/raw/`
3. Install dependencies: `pip install -r requirements.txt`
4. Run the notebooks in order (`01` → `04`) — `01` builds the SQLite database,
   `02` cleans the data and rewrites the core tables
5. SQL analyses in `sql/` run against `data/olist.db` (e.g. in DBeaver or the `sqlite3` CLI)

## Metric definitions

- **Scope:** all KPIs are computed on orders with status `delivered` (the only deliberate
  exception: cancellation analysis, which by definition needs all statuses)
- **Revenue** = `SUM(order_items.price)` — product value excluding freight
- **Seller rating** = average review score per order (1 review = 1 vote; reviews are not
  weighted by the number of items a seller has in the order)
- **On-time delivery** = delivered date ≤ estimated delivery date
- **Retention** = share of `customer_unique_id` with more than one delivered order

## Known limitations

Historical data (2016–2018, Brazil); no cost data (CAC, margins), so profitability conclusions
are directional; multi-seller orders share a single review. Full list in
[docs/business_conclusions.md](docs/business_conclusions.md#5-ograniczenia-analizy).
