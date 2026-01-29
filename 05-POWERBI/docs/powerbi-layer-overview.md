# Power BI Layer Overview  
**Wealth Management Analytics Platform – Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

The **Power BI Layer** is the **business intelligence and reporting layer** of the Wealth Management Analytics Platform built on Microsoft Fabric.  
It provides **interactive dashboards and semantic models** that enable business stakeholders, analysts, and operations teams to:

- Monitor transaction analytics and business KPIs
- Track operational health, data quality, and pipeline execution
- Perform risk and fraud analysis
- Investigate data anomalies and support root-cause analysis

The Power BI layer is built on **Direct Lake connectivity**, enabling:

- **Real-time analytics** directly from the Gold layer Lakehouse (no data duplication)
- **High-performance queries** leveraging Delta Lake optimizations
- **Unified governance** with the data engineering layers (Bronze, Silver, Gold)
- **Certified business metrics** via centralized DAX measures

This layer delivers **production-grade BI** with:

- Separate semantic models for **Business** and **Operations** use cases
- Enterprise-ready dashboard design (executive-friendly, risk-aware, drill-down capable)
- Comprehensive measure catalogs for governance and maintenance
- Color-driven status indicators and KPI thresholds

---

## 2. Objectives of the Power BI Layer

### 2.1 Provide business-ready analytics dashboards
Deliver interactive, decision-oriented dashboards for business stakeholders, product owners, and analytics teams.

### 2.2 Enable operational observability
Provide data engineering and platform operations teams with end-to-end visibility into pipeline execution, data quality, and data freshness.

### 2.3 Enforce certified business metrics
Centralize all KPIs and calculations in DAX measures, ensuring consistency across reports and eliminating logic duplication.

### 2.4 Support risk and fraud analysis
Enable risk analysts to detect anomalies, identify concentration risks, and investigate transaction-level details.

### 2.5 Leverage Direct Lake for performance
Connect directly to Gold layer Delta tables without data duplication, ensuring real-time analytics and optimal query performance.

---

## 3. Architecture Summary

### 3.1 Semantic Models (Two-Tier Design)

The Power BI layer uses **two dedicated semantic models** to separate business analytics from operational monitoring:

#### 3.1.1 SM_BUSINESS_Transactions (Business Semantic Model)

- **Purpose**: Business transaction analytics and KPIs
- **Data Source**: Gold layer Delta tables (Direct Lake)
  - `gold_fact_transactions`
  - `gold_dim_card`
  - `gold_dim_date`
  - `gold_dim_mcc`
  - `gold_dim_user`
- **Target Audience**: Business stakeholders, product owners, risk analysts
- **Key Measures**: Transaction counts, spend metrics, success rates, chip adoption, dark web exposure, concentration KPIs

#### 3.1.2 SM_OPS_Observability (Operations Semantic Model)

- **Purpose**: Platform observability, data quality monitoring, pipeline execution tracking
- **Data Source**: DWH layer warehouse tables (Direct Lake or Import)
  - `wh_run`
  - `wh_job_run_log`
  - `wh_dq_check_result`
  - `fact_transactions_daily`
  - `fact_transactions_monthly`
  - `dim_date`, `dim_month`
- **Target Audience**: Data engineers, analytics engineers, platform operations teams
- **Key Measures**: Run status, job execution metrics, DQ check results, data freshness, volume monitoring

### 3.2 Dashboards

#### 3.2.1 Business Dashboard — Transaction Analytics

A **three-page dashboard** designed for business stakeholders:

- **Page 1 — Transaction Overview**: High-level KPIs, spend distribution, adoption trends, top MCC analysis
- **Page 2 — Risk & Fraud Analysis**: Failed transactions, dark web exposure, risk evolution over time
- **Page 3 — Transaction Details**: Full drill-down capability from aggregated KPIs to individual transactions

**Design Principles**:
- Clean, executive-friendly layout
- Consistent color palette across KPIs
- Fully interactive cross-filtering
- Centralized business measures (no calculated columns in visuals)

#### 3.2.2 OPS Dashboard — Observability

A **comprehensive operational monitoring dashboard** for data platform teams:

- **Row 0 — Global Run Context**: Selected run ID, latest run, status, duration
- **Row 1 — Data Quality (DQ)**: DQ fail count, overall DQ status, color indicators
- **Row 2 — Freshness Monitoring**: Daily/monthly freshness, last date present, SLA compliance
- **Row 3 — Pipeline & Job Execution**: Jobs executed, jobs failed, success rate
- **Row 4 — Run History & Windows**: Average duration, max duration, rows processed (window-based metrics)
- **Row 5 — Volume Monitoring**: Rows processed, rows source, volume status

**Design Principles**:
- Color-driven status indicators (Green / Orange / Red)
- Window-based metrics for trend analysis
- Run-aware filtering (latest run, selected run)
- Single source of truth via DAX measures

### 3.3 Direct Lake Connectivity

Both semantic models leverage **Direct Lake** mode:

- **No data duplication**: Queries execute directly against Delta Lake tables
- **Real-time analytics**: Data is always current (no refresh lag)
- **Optimal performance**: Leverages Delta Lake columnar storage and indexing
- **Unified governance**: Same data governance rules as the Gold layer

---

## 4. Storage / Model Artifacts (Repository)

This repository captures the Power BI layer artifacts as code:

### 4.1 Semantic Model Documentation

- `05-POWERBI/semantic-model/business/`
  - `sm-business-measures_catalog.md`: Complete DAX measures catalog for business semantic model
  - `sm-business-model.png`: Visual representation of the business model
  - `sm-business-relationships.png`: Relationship diagram
- `05-POWERBI/semantic-model/operations/`
  - `sm-operations-measures_catalog.md`: Complete DAX measures catalog for operations semantic model
  - `sm-operations-model.png`: Visual representation of the operations model
  - `sm-operations-relationships.png`: Relationship diagram

### 4.2 Dashboard Documentation

- `05-POWERBI/reports/business/dashboard_business.md`: Complete documentation of the Business Dashboard (purpose, pages, KPIs, design principles)
- `05-POWERBI/reports/operations/dashboard-operarions.md`: Complete documentation of the OPS Dashboard (purpose, rows, metrics, operational usage)

### 4.3 Visual Assets

- `05-POWERBI/wm-reporting-bi.png`: High-level architecture diagram

---

## 5. Key Benefits

✅ **Direct Lake connectivity** for real-time analytics without data duplication  
✅ **Two-tier semantic model design** (Business vs Operations) for clear separation of concerns  
✅ **Certified business metrics** via centralized DAX measures  
✅ **Enterprise-ready dashboard design** (executive-friendly, risk-aware, drill-down capable)  
✅ **Comprehensive operational observability** for data platform teams  
✅ **Production-grade BI standards** (RLS-ready, alerting-ready, KPI thresholds)  
✅ **Portfolio-ready documentation** for client demos and architecture reviews  
✅ **Unified governance** with data engineering layers (Bronze, Silver, Gold)  

---

## 6. Measure Organization (DAX)

### 6.1 Business Semantic Model Measures

Measures are organized into logical folders:

- **Base**: Core calculations (Amounts, Counts, Detail, Risk)
- **Fmt**: Formatting helpers (dates, labels)
- **KPI**: Business KPIs (Concentration, Risk, Spend, Volume)

All measures follow naming conventions:
- `Base_*_D`: Base measures (D = Detail level)
- `KPI_*_D`: Business KPIs
- `Fmt_*`: Formatting measures

### 6.2 Operations Semantic Model Measures

Measures are organized by functional area:

- **OPS / DQ**: Data quality checks and status
- **OPS / Freshness**: Data freshness monitoring
- **OPS / Health**: Overall platform health indicators
- **OPS / Jobs**: Job execution metrics
- **OPS / Run**: Run-level context and status
- **OPS / RunHistory**: Window-based historical metrics
- **OPS / Volume**: Volume monitoring

All measures use consistent color logic (Green / Orange / Red) for conditional formatting.

---

## 7. Governance & Best Practices

### 7.1 Measure Governance

- **Centralized definitions**: All calculations in DAX measures (no calculated columns in visuals)
- **Documentation**: Complete measure catalogs maintained in Markdown
- **Naming conventions**: Consistent prefixes and suffixes for discoverability
- **Reusability**: Base measures referenced by KPI measures to avoid duplication

### 7.2 Dashboard Design

- **No hard-coded logic**: All visuals use measures
- **Color-driven status**: Consistent color semantics across dashboards
- **Interactive filtering**: Global slicers and cross-filtering enabled
- **Executive-friendly**: Clean layouts, clear KPIs, drill-down capability

### 7.3 Operational Readiness

- **RLS-ready**: Semantic models designed for Row-Level Security
- **Alerting-ready**: Measures can be used for Power BI alerts
- **KPI thresholds**: Color logic supports threshold-based alerting
- **Portfolio-ready**: Documentation suitable for client demos and architecture reviews

---

## 8. Consumption Patterns

### 8.1 Business Users

- **Primary Use Case**: Transaction analytics, spend analysis, risk monitoring
- **Access**: Business Dashboard (SM_BUSINESS_Transactions)
- **Interaction**: Interactive filtering, drill-down to transaction details

### 8.2 Operations Teams

- **Primary Use Case**: Pipeline monitoring, data quality checks, freshness validation
- **Access**: OPS Dashboard (SM_OPS_Observability)
- **Interaction**: Run selection, window-based trend analysis, DQ investigation

### 8.3 Analysts

- **Primary Use Case**: Ad-hoc analysis, custom reports, investigation
- **Access**: Both semantic models (depending on use case)
- **Interaction**: Build custom reports on top of semantic models

---

## 9. Future Extensions

Potential enhancements:

- **Executive summary page**: High-level business snapshot
- **Automated alerts**: Power BI alerts on KPIs and thresholds
- **Anomaly detection integration**: ML-based anomaly detection in dashboards
- **Scenario comparison**: Period-over-period analysis
- **Embedded commentary**: Stakeholder annotations and notes
- **Cross-workspace observability**: Multi-workspace monitoring
- **Historical SLA compliance tracking**: Long-term trend analysis

---

## 10. Related Documentation

- **Semantic Model Measures**: 
  - Business: `05-POWERBI/semantic-model/business/sm-business-measures_catalog.md`
  - Operations: `05-POWERBI/semantic-model/operations/sm-operations-measures_catalog.md`
- **Dashboard Documentation**:
  - Business: `05-POWERBI/reports/business/dashboard_business.md`
  - Operations: `05-POWERBI/reports/operations/dashboard-operarions.md`
- **Gold Layer** (data source): `03-GOLD/docs/gold-layer-overview.md`
- **DWH Layer** (operations data source): `04-DWH/docs/dwh-layer-overview.md`
- **Architecture Overview**: `DOCS/architecture_overview.md`
