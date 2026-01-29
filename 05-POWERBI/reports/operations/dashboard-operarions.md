# OPS – Observability Dashboard

## 1. Purpose & Scope

The **OPS – Observability Dashboard** provides an end‑to‑end operational view of the data platform execution layer. It is designed for **Data Engineering, Analytics Engineering, and Platform Operations** teams to:

- Monitor pipeline and job executions
- Detect data freshness and data quality issues early
- Track run performance, volumes, and failures
- Support operational incident analysis and root‑cause investigation

The dashboard follows **enterprise observability principles** and is aligned with **banking‑grade operational standards**.

---

## 2. Target Users

- Data Engineers
- Analytics Engineers
- Platform / OPS teams
- Technical Leads
- On‑call / Runbook operators

---

## 3. Data Sources

The dashboard is built on curated **Gold / Ops** tables:

- `wh_run`
- `wh_job_run_log`
- `wh_dq_check_result`
- `fact_transactions_daily`
- `fact_transactions_monthly`

Supporting dimensions:

- `dim_date`
- `dim_month`

All metrics are exposed through a **dedicated OPS semantic model**.

---

## 4. Global Design Principles

- **Single source of truth** via DAX measures
- **Color‑driven status indicators** (Green / Orange / Red)
- **Window‑based metrics** (rolling periods)
- **Run‑aware filtering** (latest run, selected run)
- **No hard‑coded logic in visuals** — everything via measures

---

## 5. Dashboard Structure

### 5.1 Row 0 — Global Run Context

**Objective:** identify the execution context currently analyzed.

Displayed elements:

- Selected Run ID
- Latest Run ID
- Run Status
- Run Duration (minutes)
- Last Successful Run Timestamp

Key questions answered:

- Which run am I looking at?
- Is it the latest execution?
- Did it succeed or fail?

---

### 5.2 Row 1 — Data Quality (DQ)

**Objective:** monitor data quality gates and rule failures.

KPIs:

- DQ Fail Count
- Overall DQ Status
- DQ Status Color

Behavior:

- Green: no blocking failures
- Orange: warnings detected
- Red: critical DQ failure

---

### 5.3 Row 2 — Freshness Monitoring

**Objective:** ensure data availability SLAs are respected.

KPIs:

- Daily Freshness (days)
- Monthly Freshness (days)
- Last Date Present
- Current Month Presence
- Monthly Aggregate Status

Highlights:

- Automatic freshness aging
- Month completeness detection
- SLA‑driven color logic

---

### 5.4 Row 3 — Pipeline & Job Execution

**Objective:** track execution reliability and stability.

KPIs:

- Jobs Executed
- Jobs Failed
- Success Rate
- Execution Status Color

Insights:

- Immediate detection of failed jobs
- Success ratio trend
- Execution volume anomalies

---

### 5.5 Row 4 — Run History & Windows

**Objective:** analyze behavior across recent runs.

Metrics (window‑based):

- Average Duration (min)
- Max Duration (window)
- Rows Processed (window)
- Runs Succeeded (window)
- Runs Failed (window)

This row supports **trend analysis** and **capacity planning**.

---

### 5.6 Row 5 — Volume Monitoring

**Objective:** detect unexpected volume drops or spikes.

KPIs:

- Rows Processed
- Rows Source
- Volume Status Color

Use cases:

- Detect partial loads
- Identify upstream source issues
- Validate expected ingestion volumes

---

## 6. Color & Status Logic

All status visuals rely on **dedicated DAX color measures**, ensuring:

- Consistent semantics across the dashboard
- Reusability in alerts and other reports
- Clear separation between logic and visualization

Standard palette:

- Green → OK / Healthy
- Orange → Warning / Degraded
- Red → Critical / Failed

---

## 7. Filtering & Interactions

Global slicers:

- Run ID
- Date

Design rules:

- All visuals react to run selection
- Window metrics remain independent of slicers where required
- No circular dependencies between visuals

---

## 8. Operational Usage

Typical workflows:

1. Open dashboard after pipeline execution
2. Check global run status
3. Review DQ and freshness indicators
4. Investigate failures or anomalies
5. Drill into run history if needed

The dashboard acts as the **first line of defense** before deeper log inspection.

---

## 9. Portfolio & Demo Value

This dashboard demonstrates:

- Enterprise‑grade observability design
- Advanced DAX modeling
- Operational thinking beyond pure BI
- Clear separation of business vs OPS metrics
- Production‑ready monitoring patterns

It is suitable for:

- Client demos
- Architecture reviews
- Data platform portfolio presentations

---

## 10. Next Extensions (Optional)

- Alerting integration (Power BI / Fabric)
- SLA breach notifications
- Historical SLA compliance tracking
- Cross‑workspace observability

---

**Status:** Production‑ready

**Owner:** Data Platform / OPS

**Last Updated:** _to be filled_

