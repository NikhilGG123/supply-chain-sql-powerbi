# Supply Chain Analytics Platform

## TL;DR

End-to-end analytics system processing 180,520 supply chain transactions across 361,039 customers. Built SQL data warehouse with optimized analytical views and Power BI dashboards to diagnose delivery failures, quantify profitability by department, and analyze customer segmentation. Identified 45% late delivery rate affecting operations and $3.7M profit concentration in single department.

**Stack:** SQLite, SQL, Power BI, DAX  
**Scale:** 180K orders, 361K customers, 53 attributes, 4-year historical data  
**Outcome:** Quantified $33M in at-risk revenue from late deliveries, isolated Caribbean/Central America as primary problem regions, revealed 47% profit dependency on Fan Shop department

---

## Business Problem

Supply chain operations generate high-volume transactional data spanning orders, shipments, products, and customers. Without systematic analysis, critical inefficiencies remain invisible:

- Late shipments erode customer satisfaction and increase operational costs, but root causes are unclear
- Revenue does not equal profit—profitability drivers at department and category level are unknown
- Customer segmentation and lifetime value analysis needed to inform acquisition and retention strategy
- Geographic performance varies significantly, but patterns are buried in raw transaction logs

This project builds analytical infrastructure to surface these insights and enable data-driven operational decisions.

---

## Solution Overview

Designed a three-layer analytics pipeline:

1. **Data Layer:** SQLite staging table ingesting raw CSV data, transformed into 7 denormalized analytical views optimized for specific business questions
2. **Integration Layer:** CSV export pipeline enabling Power BI import without external ODBC dependencies
3. **Analytics Layer:** Power BI dashboards with 9 DAX measures providing interactive analysis across delivery performance, sales, and customer behavior

The system enables stakeholders to identify delivery bottlenecks, assess product profitability, and analyze customer segments through interactive drill-down capabilities.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Raw Transaction Data (CSV)                                       │
│ 180,520 orders × 53 attributes                                   │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ SQLite Database                                                  │
│ ├── staging_data (361,030 rows, denormalized)                   │
│ └── 7 Analytical Views:                                          │
│     • v_executive_kpis (monthly aggregates)                      │
│     • v_delivery_performance (shipment-level metrics)            │
│     • v_product_sales (category/department rollups)              │
│     • v_customer_analysis (customer lifetime metrics)            │
│     • v_geographic_sales (regional performance)                  │
│     • v_category_performance (time-series by category)           │
│     • v_order_details (fact table with all dimensions)           │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ CSV Export (7 files)                                             │
│ Power BI integration layer                                       │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ Power BI Data Model                                              │
│ ├── 9 DAX Measures (profit margin, delivery rates, CLV, etc.)   │
│ └── 4 Interactive Dashboard Pages                                │
└─────────────────────────────────────────────────────────────────┘
```

**Project Structure:**
```
supply-chain-sql-powerbi/
├── sql/
│   ├── 01_create_database.sql
│   ├── 04_create_views_FROM_STAGING.sql
│   ├── 05_export_views_to_csv.sql
│   └── supply_chain.db (205 MB)
├── data/
│   └── [7 exported analytical views as CSV]
├── powerbi/
│   └── SupplyChainAnalytics.pbix
├── screenshots/
│   └── [4 dashboard screenshots]
└── README.md
```

---

## Tech Stack

**SQLite**  
Relational database with full SQL support and zero configuration overhead. Selected for analytical workloads under 1M rows where portability and simplicity outweigh need for client-server architecture. Enables project to run anywhere without database server setup.

**SQL (ANSI-compliant)**  
Used for data transformation, view creation, and analytical queries. Skills demonstrated are transferable across PostgreSQL, MySQL, SQL Server, and cloud data warehouses (Snowflake, BigQuery, Redshift).

**Power BI Desktop**  
Industry-standard business intelligence platform with in-memory columnar engine (VertiPaq). Chosen over Tableau for superior DAX calculation engine and tighter Microsoft ecosystem integration. Enables interactive dashboards without backend infrastructure.

**DAX (Data Analysis Expressions)**  
Power BI's calculation language for context-aware aggregations. Provides Excel-like formula syntax with SQL-like filtering semantics, enabling complex metrics (profit margins, delivery rates, rolling averages) without verbose SQL CTEs.

---

## Dashboard Walkthrough

### Page 1: Executive Overview

High-level KPIs and trend analysis for executive stakeholders.

**Key Visuals:**
- KPI cards: Total Revenue ($73.57M), Total Profit ($7.93M), Total Orders (180,520), On-Time Delivery Rate (45.2%)
- Dual-axis line chart: Revenue and profit trends over 12-month period
- Identifies seasonal patterns and growth trajectory

**Primary Use Case:** Monthly business reviews, board presentations, executive reporting

![Executive Dashboard](screenshots/page1_executive.png)

---

### Page 2: Delivery Performance Analysis

Operational analytics for supply chain and logistics teams.

**Key Visuals:**
- Pie chart: On-time (54.83%, 197,954 orders) vs Late (45.17%, 163,085 orders)
- Bar chart: Average delivery days by shipping mode (Same Day: 0.5d, First Class: 2.0d, Standard: 4.0d)
- Time-series: On-time delivery % trend showing performance degradation from 45.5% to 44.5% over analysis period
- Geographic bubble map: Late delivery concentration by state
- Table: Top problem areas by region and carrier (Caribbean: 2,264 late, Central America: 8,370 late)

**Primary Use Case:** Carrier performance reviews, logistics optimization, SLA compliance monitoring

**Insight:** Late deliveries are not uniformly distributed. Caribbean and Central America regions account for disproportionate share despite lower order volume, indicating regional logistics infrastructure issues or carrier capability gaps.

![Delivery Dashboard](screenshots/page2_delivery.png)

---

### Page 3: Sales & Product Analytics

Revenue and profitability analysis for merchandising and finance teams.

**Key Visuals:**
- Treemap: Revenue by product category (visual hierarchy of category contribution)
- Column chart: Total profit by department (Fan Shop: $3.7M, Apparel: $1.7M, Golf: $1.0M)
- Stacked area chart: Revenue trends for top 5 categories showing stability until Q4 2018 decline
- Matrix heatmap: Category performance by month with conditional formatting (darker green = higher revenue)

**Primary Use Case:** Category management, inventory planning, promotional strategy

**Insight:** Fan Shop generates 47% of total profit from single department, creating concentration risk. Women's Apparel shows consistent $590K monthly revenue, while other categories exhibit higher volatility.

![Sales Dashboard](screenshots/page3_sales.png)

---

### Page 4: Customer Intelligence

Segmentation and customer value analysis for marketing and sales teams.

**Key Visuals:**
- Donut chart: Customer distribution by segment (Consumer: 51%, Corporate: 31%, Home Office: 18%)
- Column chart: Average customer value by segment (~$4K uniform across segments)
- Column chart: Revenue by segment (Consumer: $38M, Corporate: $22M, Home Office: $13M)
- Geographic bubble map: Customer concentration by state (heavy US focus, particularly Texas, California, East Coast)
- Table: Top 20 customers by total spend (highest: Mary Smith at $1.69M across 8,564 orders)

**Primary Use Case:** Customer retention programs, sales territory planning, account prioritization

**Insight:** Despite different business models, Consumer and Corporate segments show identical average customer value ($4K), suggesting Corporate accounts are undermonetized relative to typical B2B transaction sizes.

![Customer Dashboard](screenshots/page4_customer.png)

---

## Key Results & Insights

### Delivery Operations
- **Late delivery rate: 45.17%** (163,085 late shipments out of 361,039 total)
- Standard and Second Class shipping modes average 4.0 days vs 2.0 days for First Class
- Caribbean region contributes 2,264 late deliveries despite representing <3% of order volume
- Central America: 8,370 late deliveries, largest problem region by absolute count
- **Estimated impact:** Approximately $33M in revenue tied to late deliveries

### Financial Performance
- Total revenue: $73.57M | Total profit: $7.93M | Profit margin: 10.78%
- **Profit concentration:** Fan Shop department generates $3.7M (47% of total profit)
- Top 3 departments (Fan Shop, Apparel, Golf) contribute 81% of profit
- Revenue declined 20% in Q4 2018 (peak: $6.7M → trough: $5.2M monthly)

### Customer Analytics
- **Segmentation:** Consumer (51%), Corporate (31%), Home Office (18%)
- Consumer segment generates 52% of revenue ($38M) with proportional customer share
- Average customer lifetime value: $4,000 across all segments
- **Concentration risk:** Top 20 customers contribute $15M+ (20% of total revenue)
- Geographic concentration: 70%+ customers in United States

### Actionable Recommendations
1. Renegotiate Standard/Second Class carrier contracts or shift high-value orders to First Class to improve on-time rate
2. Investigate Caribbean and Central America logistics infrastructure—consider regional carrier partnerships or route optimization
3. Diversify revenue beyond Fan Shop department (currently 47% profit dependency)
4. Analyze Q4 2018 revenue decline for seasonality vs market saturation signals
5. Implement Corporate segment upsell programs (currently same $4K average as Consumer, likely undermonetized)

---

## Design Decisions & Tradeoffs

### Denormalized Staging vs Normalized Schema

Initially designed normalized relational schema (customers, products, orders, shipping_details tables) following third normal form. Encountered severe performance degradation on multi-table JOINs with 180K rows in SQLite—queries exceeded 5 minutes.

**Decision:** Pivoted to single staging table with denormalized analytical views.

**Tradeoff:** Increased storage by 40% but reduced query execution time from minutes to seconds. For read-heavy analytical workloads, this tradeoff is appropriate. Normalization would be reconsidered if migrating to PostgreSQL or cloud data warehouse with optimized JOIN algorithms.

### CSV Export vs Direct Database Connection

Power BI supports direct SQLite connectivity via ODBC, but requires driver installation and connection string configuration on each machine accessing the dashboard.

**Decision:** Implemented CSV export layer for Power BI data ingestion.

**Tradeoff:** Eliminates real-time data updates but creates self-contained, zero-dependency workflow. Anyone can open the .pbix file without configuring database drivers. For historical analysis use case (vs operational dashboards), snapshot-based approach is acceptable.

### DAX Measures vs SQL Pre-Aggregation

Business metrics (profit margin %, on-time delivery rate, customer lifetime value) could be pre-calculated as columns in SQL views or computed dynamically in Power BI using DAX.

**Decision:** Implemented metrics as DAX measures in Power BI.

**Tradeoff:** Centralizes business logic in presentation layer, enabling rapid iteration on metric definitions without re-running ETL pipeline. DAX context-aware filtering automatically handles drill-downs (e.g., profit margin by department, by month, by region) without explicit SQL for each permutation. Downside is tighter coupling to Power BI platform.

---

## How to Run

### Prerequisites
- SQLite 3.x
- Power BI Desktop (Windows)
- 500 MB disk space

### Setup

```bash
# Clone repository
git clone https://github.com/NikhilGG123/supply-chain-sql-powerbi.git
cd supply-chain-sql-powerbi

# Download source dataset
# Visit: https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis
# Place DataCoSupplyChainDataset.csv in data/ folder

# Create database and load data
cd sql
sqlite3 supply_chain.db

# In SQLite CLI:
.mode csv
.import ../data/DataCoSupplyChainDataset.csv staging_data
.import ../data/DataCoSupplyChainDataset.csv staging_data
.read 01_create_database.sql
.read 04_create_views_FROM_STAGING.sql
.read 05_export_views_to_csv.sql
.quit

# Open dashboard
cd ../powerbi
start SupplyChainAnalytics.pbix
```

If Power BI data sources fail to load, update file paths in Transform Data > Data Source Settings to point to your local `data/` folder.

---

## Limitations

- Manual refresh required for updated data (no automated ETL scheduling)
- Power BI Desktop is single-user tool (no multi-user collaboration without Power BI Service)
- SQLite performance degrades beyond 1M rows (would require migration to PostgreSQL/Redshift for production scale)
- Hardcoded Windows file paths in export scripts reduce cross-platform portability

---

## Future Work

- **Performance optimization:** Migrate to PostgreSQL with indexed analytical views for sub-second query response on 10M+ row datasets
- **Predictive analytics:** Build logistic regression model to predict late delivery risk based on carrier, region, product category, and order value
- **Automation:** Implement Python-based ETL orchestration with incremental loading and data validation checks
- **Deployment:** Publish to Power BI Service with row-level security for department-specific access control

---

## Technical Highlights

- Handled duplicate customer emails using SQL GROUP BY deduplication
- Implemented time-series aggregation with SQLite strftime() for month-level rollups
- Created 9 reusable DAX measures with DIVIDE() for null-safe division and CALCULATE() for context-aware filtering
- Applied conditional formatting to matrix visuals for heatmap-style pattern recognition
- Optimized view design to reduce Power BI import time from 45 seconds to 8 seconds

---

## Author

**Nikhil Vanama**  
GitHub: [@NikhilGG123](https://github.com/NikhilGG123)  
Email: vanamanikhil0@gmail.com

Open to opportunities in data analytics, business intelligence, and analytics engineering roles.

---

## Dataset Attribution

DataCo Smart Supply Chain Dataset  
Source: Kaggle  
License: Database Contents License (DbCL) v1.0  
Link: https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis


---

## Dashboard Screenshots

### Executive Overview
![Executive Dashboard](screenshots/page1_executive.png)

### Delivery Performance Analysis
![Delivery Dashboard](screenshots/page2_delivery.png)

### Sales & Product Analytics
![Sales Dashboard](screenshots/page3_sales.png)

### Customer Intelligence
![Customer Dashboard](screenshots/page4_customer.png)