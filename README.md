# Supply Chain Performance Analytics

**Analyzed 180K+ transactions ($33M revenue) to identify delivery bottlenecks and margin optimization opportunities. Built end-to-end pipeline from raw CSV to executive dashboards, uncovering $4M+ in actionable insights.**

![Python](https://img.shields.io/badge/python-3.8+-blue.svg) ![PostgreSQL](https://img.shields.io/badge/postgresql-16+-blue.svg) ![Power BI](https://img.shields.io/badge/PowerBI-yellow.svg)

## Business Problem

Operations team lacked visibility into delivery failures and product profitability. Without centralized analytics, critical decisions (carrier negotiations, SKU rationalization, regional expansion) relied on incomplete data. This project builds the infrastructure to answer: Which shipping modes miss targets? Where are we losing money? Which customers drive profit?

## Dataset & Scale

Multi-year supply chain transaction log: **180K orders** | **20K customers** | **236 products** | **$33M revenue** | **4 global markets**

## Solution

**Pipeline:** CSV → PostgreSQL (star schema) → 7 analytical views → Power BI dashboards

**Schema Design:**
- Fact: `orders` (180K records) - sales, profit, quantity
- Dimensions: `customers`, `products`, `shipping_details`
- Pre-aggregated views for sub-second queries

**ETL Highlights:**
- Deduplication by business keys (Customer ID, Product Name)
- Foreign key validation (zero orphaned records)
- Batch processing (1000 records/commit)

## Key Findings

**1. Delivery Crisis:** 55% late rate (99K shipments) with LATAM worst at 62%
- *Impact:* Revenue risk in largest market (40% of sales)
- *Action:* Regional carrier partnerships, local fulfillment

**2. Shipping Inefficiency:** Standard Class 60% of volume, highest late rate
- *Impact:* $800K+ LTV gain from shifting VIPs to premium
- *Action:* Tiered shipping by customer value

**3. Portfolio Waste:** Top 10% SKUs = 45% profit, Bottom 30% = loss-making
- *Impact:* $500K+ in unprofitable inventory
- *Action:* Discontinue low-margin products

**4. Q4 Capacity Strain:** +35% revenue but 68% late deliveries
- *Impact:* $2M+ at-risk from holiday failures
- *Action:* Pre-positioned inventory, seasonal staffing

**Total Opportunity:** $4M+ annually

## Dashboard

4-page executive view with drill-down:

### Executive Scorecard
![Executive Dashboard](screenshots/page1_executive)

Monthly KPIs: revenue, margin, on-time %, order volume

### Delivery Operations
![Delivery Performance](screenshots/page2_delivery)

Late delivery heatmap by region/mode, delay severity analysis

### Product Performance
![Product Sales](screenshots/page3_sales)

Profitability tiers, margin by category, underperforming SKU alerts

### Customer Intelligence
![Customer Analysis](screenshots/page4_customer)

Segment analysis, lifetime value, geographic distribution

**Stakeholder value:** Operations identifies problem carriers in real-time. Product makes data-driven SKU decisions. Finance has margin visibility for pricing.

## Tech Stack

Python (pandas, psycopg2) | PostgreSQL 16 | Power BI | Star schema | Batch ETL

## Reproduce

```bash
# Setup (5 minutes)
psql -U postgres -c "CREATE DATABASE supply_chain_analytics;"
psql -U postgres -d supply_chain_analytics -f sql/01_create_schema.sql
cp .env.example .env  # Add credentials
pip install -r requirements.txt
python scripts/import_data.py
psql -U postgres -d supply_chain_analytics -f sql/03_create_views.sql
# Connect Power BI to localhost:5432, import views
```

## Next Steps

- Train late delivery classifier for proactive risk flagging
- Incremental ETL for daily updates
- Customer segmentation (K-means on RFM + delivery satisfaction)
- Production deployment (cloud migration, automated refresh)

---

**Nikhil Vanama** | [GitHub](https://github.com/nikhilvanama) | vanamanikhil0@gmail.com
