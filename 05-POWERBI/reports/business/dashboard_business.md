# 📊 Business Dashboard — Transaction Analytics

## 1. Purpose & Positioning

The **Business Dashboard — Transaction Analytics** is designed to provide **business stakeholders, product owners, and analytics teams** with a clear, decision‑oriented view of transaction activity.

It focuses on **volume, spend, success, adoption, concentration, and risk exposure**, while remaining fully interactive and drill‑down capable.

Typical use cases:
- Executive overview of transaction performance
- Monitoring transaction health and adoption trends
- Identifying concentration risks (MCC / merchants)
- Supporting fraud & risk analysis
- Enabling detailed transaction‑level investigation

---

## 2. Target Audience

- Business stakeholders (Operations, Finance, Product)
- Risk & Fraud analysts
- Data & Analytics teams
- Management / Steering committees

---

## 3. Data Foundation

The dashboard is built on a **Business Semantic Model** backed by a **Gold‑layer Data Warehouse**, ensuring:

- Certified, reconciled metrics
- Stable business definitions
- Consistent drill‑down behavior

### Key data domains
- Transactions (fact_transactions)
- Cards & card brands
- Merchants & MCC codes
- Dates (day / month / period)

---

## 4. Page 1 — Transaction Overview

### Objective
Provide a **high‑level business snapshot** of transaction activity over a selected time range.

### Global Controls
- **Date Range slicer** (shared across pages)
- Cross‑filtering between all visuals

### Row 1 — Core KPIs

- **Total Transactions**
- **Total Spend**
- **Success Rate**
- **Failure Rate**
- **Chip Adoption Rate**
- **Dark Web Cards**
- **Dark Web Exposure Rate**

Purpose:
- Immediate understanding of platform health
- Fast comparison across periods

---

### Row 2 — Distribution & Composition

#### Spend by Card Brand
- Table showing:
  - Total Amount
  - Transaction Count
- Enables brand‑level analysis

#### Transactions by MCC Code
- MCC Description
- Total Amount
- Transaction Count

Purpose:
- Identify dominant card brands
- Understand category‑level spending patterns

---

### Row 3 — Adoption & Trends

#### Transactions Chip vs Non‑Chip
- 100% stacked bar
- Consistent color coding across pages

#### Transactions & Spend Trend Over Time
- Line chart combining:
  - Transaction count
  - Total spend

#### Top MCC by Spend
- Top‑N bar chart
- Dynamic ranking based on spend

Purpose:
- Track adoption trends
- Detect volume or spend anomalies
- Identify concentration risks

---

## 5. Page 2 — Risk & Fraud Analysis

### Objective
Focus on **risk signals and fraud‑related indicators** while keeping full interactivity with the business metrics.

### Row 1 — Risk KPIs

- **Failed Transactions**
- **Failure Rate**
- **Dark Web Cards**
- **Dark Web Exposure Rate**

Purpose:
- Fast detection of abnormal behavior
- Risk posture overview

---

### Row 2 — Risk Evolution Over Time

- **Failed Transactions Over Time**
- **Failure Rate Over Time**

Purpose:
- Identify spikes and trends
- Correlate failures with periods or events

---

### Row 3 — Risk Breakdown

- **Failed Transactions by MCC** (Top‑N)
- **Dark Web Exposure by Card Brand**

Purpose:
- Locate risk concentration
- Support targeted investigations

---

## 6. Page 3 — Transaction Details

### Objective
Enable **full drill‑down from aggregated KPIs to individual transactions**.

This page is designed as an **analysis & investigation workspace**.

### Row 0 — Global Filters

- Date Range
- Card Brand
- Transaction ID

Purpose:
- Precise filtering
- Reproducible analysis

---

### Row 1 — Financial Summary

- **Transaction Amount**
- **Transaction Base Amount**

Purpose:
- Immediate financial context for selected transactions

---

### Row 2 — Transaction Context

Tabular view including:
- Transaction Date
- Transaction ID
- Currency
- Chip usage
- Merchant State
- Merchant City
- Merchant Name

Purpose:
- Operational investigation
- Root‑cause analysis

---

## 7. Design Principles

- Clean, executive‑friendly layout
- Consistent color palette across KPIs
- Explicit separation between:
  - Overview
  - Risk
  - Detail
- No duplicated logic between visuals
- Fully interactive cross‑filtering

---

## 8. Governance & Best Practices

- Centralized business measures
- No calculated columns in visuals
- All KPIs sourced from certified DAX measures
- Consistent naming conventions
- Ready for:
  - RLS
  - Alerting
  - KPI thresholds

---

## 9. Portfolio & Demo Value

This dashboard demonstrates:

- Strong semantic modeling
- Business‑oriented KPI design
- Risk‑aware analytics
- End‑to‑end drill‑down capability
- Production‑grade BI standards

It is suitable for:
- Client demos
- Senior BI / Analytics roles
- Data platform architecture portfolios

---

## 10. Next Possible Extensions

- Executive summary page
- Automated alerts on KPIs
- Anomaly detection integration
- Scenario comparison (period‑over‑period)
- Embedded commentary for stakeholders

