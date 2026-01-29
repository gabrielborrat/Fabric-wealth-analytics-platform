# DWH Layer Overview  
**Wealth Management Analytics Platform – Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

The **DWH (Data Warehouse) Layer** is the curated, SQL-native analytical serving layer of the Wealth Management Analytics Platform.  
It materializes a governed star schema (dimensions + facts) inside a Microsoft Fabric **Data Warehouse** and provides:

- Deterministic, SQL-controlled transformations
- Repeatable monthly refreshes with orchestration
- Data quality controls (duplicates, orphans, conformance, reconciliation)
- Publish/ready-to-consume checks before downstream consumption (e.g. semantic model refresh)

This layer is designed for **banking-grade auditability** and operational clarity:

- A **job registry table** drives execution (`dbo.wh_ctl_job`)
- Each job execution is logged at run level (`dbo.wh_job_run_log`)
- Each DQ check result is persisted (`dbo.wh_dq_check_result`)
- An orchestrator pipeline manages end-to-end refreshes (`pl_dwh_refresh_month_e2e`)

---

## 2. Objectives of the DWH Layer

### 2.1 Provide a stable star schema for analytics
Expose clean dimensions and facts optimized for reporting and dashboarding.

### 2.2 Enforce strong governance and traceability
Persist run metadata and job outcomes for auditability and incident triage.

### 2.3 Industrialize DQ controls
Automate duplicates/orphans/reconciliation checks and persist results per run.

### 2.4 Publish only “ready” datasets
Gate the publish stage using freshness/completeness checks before triggering downstream refresh steps.

---

## 3. Architecture Summary

### 3.1 Main warehouse artifact
- **Warehouse**: `wh_wm_analytics`  
- **Schema**: `dbo`

### 3.2 Orchestration pattern (job-driven)

The DWH refresh is implemented as:

- **Job registry**: `dbo.wh_ctl_job`  
  Each row describes a job (group, order, stored procedure, enablement, criticality, required parameters).

- **Execution pipelines** (by job group):
  - `pl_dwh_refresh_dimensions` (group `DIMS`)
  - `pl_dwh_refresh_facts` (group `FACTS`)
  - `pl_dwh_refresh_aggregates` (group `AGG`)
  - `pl_dwh_refresh_controls` (group `CONTROLS`)
  - `pl_dwh_publish` (group `PUBLISH`)

- **End-to-end orchestrator**:
  - `pl_dwh_refresh_month_e2e`: runs the above groups sequentially and finalizes the run status.

---

## 4. Storage / Model Artifacts (repo)

This repository captures the DWH layer artifacts as code:

- `04-DWH/dwh-model-dll.sql`: table DDL (dimensions, facts, control tables, run logging tables)
- `04-DWH/dwh-sp-ddl.sql`: stored procedures implementing refresh jobs, DQ controls, and publish actions
- `04-DWH/pipelines/*.json`: Fabric pipeline definitions orchestrating stored procedure execution

---

## 5. Key Benefits

✅ **SQL-governed transformations** for predictable analytics outputs  
✅ **Job registry-driven orchestration** (no hardcoded job lists in pipelines)  
✅ **Run logging + DQ persistence** for auditability and operations  
✅ **Publish gating** to avoid exposing stale / inconsistent warehouse states  

---

## 6. Quick Start (what to run)

To refresh a month end-to-end, run the pipeline:

- `pl_dwh_refresh_month_e2e` with:
  - `p_TxnMonth` (DATE): targeted month (month start date)
  - `p_ExecDate` (DATE): execution date (optional depending on job)
  - `p_RunId` (STRING): optional external run id; if empty, the pipeline uses the Fabric run id

For more details, see:
- `dwh-layer-pipeline.md`
- `dwh-schema-data-dictionary.md`

