# DWH Layer — Stored Procedures Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

Unlike the Bronze/Silver/Gold layers (Spark notebooks + Lakehouse), the DWH layer logic is implemented primarily as **T-SQL stored procedures** executed by Fabric Pipelines through **Script** activities against the Fabric **Data Warehouse** (`wh_wm_analytics`).

This document describes:

- stored procedure categories (dimensions, facts, controls, reconciliation, publish)
- run-level logging and DQ persistence model
- procedure parameter contract (RunId, JobId, TxnMonth, ExecDate)

Source of truth:

- Stored procedures: `04-DWH/dwh-sp-ddl.sql`
- Tables/logging: `04-DWH/dwh-model-dll.sql`

---

## 2. Standard Parameter Contract

Most procedures follow a consistent signature:

- `@RunId VARCHAR(64)` (optional; if NULL/blank, a new id can be generated)
- `@JobId VARCHAR(64)` (optional; used to identify job in logs)
- `@TxnMonth DATE` (optional; scope for month-level refresh/DQ)
- `@ExecDate DATE` (optional; execution date for logging)

This enables:

- consistent orchestration from pipelines
- correlation of all actions within a single end-to-end run
- audit-friendly logging for each job and control

---

## 3. Logging & Audit Tables

### 3.1 Job run logging: `dbo.wh_job_run_log`

Each procedure typically writes:

- a **STARTED** record at the beginning
- a **SUCCESS** or **FAILED** record at completion

Including timestamps, optional row counts, and a message.

### 3.2 Data quality results: `dbo.wh_dq_check_result`

DQ checks persist:

- `check_code` (e.g. duplicates, orphans, empty hash)
- `status` (PASS/FAIL)
- `issue_count`
- `txn_month` and `exec_date` scope

### 3.3 Run summary: `dbo.wh_run`

The orchestrator finalizes a run summary (status, duration, counts, DQ rollup) via publish procedures.

---

## 4. Procedure Families (high-level)

### 4.1 Dimension refresh (`job_group = 'DIMS'`)

Typical procedures:

- `dbo.sp_job_dim_date_refresh`
- `dbo.sp_job_dim_month_refresh`
- `dbo.sp_job_dim_user_refresh`
- `dbo.sp_job_dim_card_refresh`
- `dbo.sp_job_dim_mcc_refresh`

Purpose:

- upsert/refresh dimension tables (`dbo.dim_*`)
- maintain stable surrogate keys and hashes (where applicable)

### 4.2 Fact refresh (`job_group = 'FACTS'`)

Typical procedures:

- `dbo.sp_job_fact_transactions_refresh_month`
- `dbo.sp_job_fact_transactions_daily_refresh_month`
- `dbo.sp_job_fact_transactions_monthly_refresh_month`

Purpose:

- load transaction facts scoped to `@TxnMonth`
- populate derived fact tables (`fact_transactions_daily`, `fact_transactions_monthly`)

### 4.3 Aggregates (`job_group = 'AGG'`)

Aggregates are built after facts to provide fast, precomputed metrics for reporting and validation.

### 4.4 Controls & reconciliation (`job_group = 'CONTROLS'`)

Typical procedures:

- DQ duplicates / empty hash:
  - `dbo.sp_ctl_fact_transactions_duplicates_transaction_id`
  - `dbo.sp_ctl_fact_transactions_empty_record_hash`
- Orphans checks:
  - `dbo.sp_ctl_fact_transactions_orphans_user`
  - `dbo.sp_ctl_fact_transactions_orphans_card`
  - `dbo.sp_ctl_fact_transactions_orphans_mcc`
  - `dbo.sp_ctl_fact_transactions_orphans_date`
- Gold vs DWH reconciliation:
  - `dbo.sp_ctl_recon_gold_vs_dwh_amounts`
  - `dbo.sp_ctl_recon_gold_vs_dwh_counts`

Outputs:

- per-check results in `dbo.wh_dq_check_result`
- operational traces in `dbo.wh_job_run_log`

### 4.5 Publish (`job_group = 'PUBLISH'`)

Typical procedures:

- Gate checks:
  - `dbo.sp_pub_check_aggregates_freshness`
  - `dbo.sp_pub_check_aggregates_monthly_present`
- Publish actions:
  - `dbo.sp_pub_refresh_semantic_model`
- Run finalization:
  - `dbo.sp_pub_wh_run_refresh`

---

## 5. How Pipelines Execute Procedures

Pipelines read `dbo.wh_ctl_job` and dynamically execute:

```sql
EXEC <sp_schema>.<sp_name>
  @RunId = '<run_id>',
  @JobId = '<job_code>',
  @TxnMonth = '<txn_month?>',
  @ExecDate = '<exec_date?>';
```

The inclusion of `@TxnMonth` and `@ExecDate` depends on the flags:

- `needs_txn_month`
- `needs_exec_date`

---

## 6. Extensibility Checklist

To add a new control or publish step:

1. Create the stored procedure (same parameter contract)
2. Register it in `dbo.wh_ctl_job` with:
   - `job_group`
   - `job_order`
   - `enabled = 1`
   - `is_critical` set appropriately
   - parameter requirement flags
3. Re-run the orchestrator (no pipeline changes required)

