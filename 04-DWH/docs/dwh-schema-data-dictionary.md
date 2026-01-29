# DWH Layer — Data Dictionary  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## Overview

This document provides a **professional-grade DWH Layer Data Dictionary** for the Wealth Management Analytics Platform.  
It describes the **warehouse tables**, their role, and their core fields, aligned with:

- `04-DWH/dwh-model-dll.sql` (DDL definitions)
- `04-DWH/dwh-sp-ddl.sql` (refresh + DQ + publish procedures)
- DWH pipelines in `04-DWH/pipelines/` (orchestration)

The DWH layer is implemented in the Fabric Data Warehouse:

- Warehouse: `wh_wm_analytics`
- Schema: `dbo`

---

## 1. Control & Governance Tables

### 1.1 `dbo.wh_ctl_job` — Job registry

Controls which stored procedures are executed by the DWH pipelines.

| Column | Type | Description |
|---|---|---|
| `job_group` | varchar(50) | Execution group (`DIMS`, `FACTS`, `AGG`, `CONTROLS`, `PUBLISH`) |
| `job_order` | int | Deterministic ordering within the group |
| `job_code` | varchar(100) | Job identifier passed to procedures as `@JobId` |
| `sp_schema` | varchar(50) | Stored procedure schema (usually `dbo`) |
| `sp_name` | varchar(128) | Stored procedure name |
| `enabled` | bit | Whether job is active |
| `is_critical` | bit | If 1, failure stops the pipeline |
| `needs_txn_month` | bit | Requires `@TxnMonth` parameter |
| `needs_exec_date` | bit | Requires `@ExecDate` parameter |
| `notes` | varchar(500) | Free-form notes |

### 1.2 `dbo.wh_job_run_log` — Job execution log

Captures STARTED / SUCCESS / FAILED records for each job execution.

Key fields:

- `run_id`, `job_id`
- `exec_ts_start`, `exec_ts_end`
- `exec_date`, `txn_month`
- `status`
- row metrics (`rows_inserted`, `rows_updated`, `rows_deleted`, `rows_source`)
- `message`

### 1.3 `dbo.wh_dq_check_result` — DQ check results

Persists DQ results per run and per check.

| Column | Type | Description |
|---|---|---|
| `run_id` | varchar(64) | Correlation run identifier |
| `check_code` | varchar(100) | Code identifying the check |
| `exec_ts` | datetime2(3) | Timestamp of the check |
| `exec_date` | date | Execution date (optional) |
| `txn_month` | date | Month scope (optional) |
| `status` | varchar(16) | PASS / FAIL (or similar) |
| `issue_count` | bigint | Number of issues found |
| `message` | varchar(2000) | Human-readable details |

### 1.4 `dbo.wh_run` — Run summary

Stores run-level status and rollups (duration, job counts, DQ rollups, last message).

---

## 2. Operational Control Tables (DQ outputs)

These tables store detailed control metrics and publish decisions:

### 2.1 `dbo.ctrl_duplicates`
Duplicates metrics for the relevant scope (e.g. per month).

### 2.2 `dbo.ctrl_conformance`
Conformance checks (counts, expected constraints, etc.).

### 2.3 `dbo.ctrl_reconciliation`
Gold vs DWH reconciliation metrics (values, deltas, tolerances, status).

### 2.4 `dbo.ctrl_publish_status`
Publish decision/status per month (publish timestamp, status, reason).

---

## 3. Dimension Tables

### 3.1 `dbo.dim_date`
Date dimension used to join facts to calendar attributes.

Core fields:

- `date_key` (surrogate key)
- `date_id`, `full_date`
- `year`, `quarter`, `month`, `week`, `day_of_week`
- `is_weekend`, `is_business_day`

### 3.2 `dbo.dim_month`
Month dimension / calendar helper.

Core fields:

- `month_start`
- `year`, `month`, `yyyymm`
- `month_label`

### 3.3 `dbo.dim_user`
User/customer analytical attributes.

Core fields:

- `user_key` (surrogate key)
- `client_id`
- demographics & finance: `current_age`, `yearly_income`, `total_debt`, `credit_score`
- `address`

### 3.4 `dbo.dim_card`
Payment card analytical attributes.

Core fields:

- `card_key` (surrogate key)
- `card_id`, `client_id`
- `card_brand`, `card_type`
- `has_chip`, `credit_limit`, `num_cards_issued`, `card_on_dark_web`

### 3.5 `dbo.dim_mcc`
Merchant Category Code analytical attributes.

Core fields:

- `mcc_key` (surrogate key)
- `mcc_code`
- `mcc_description`, `mcc_category`

---

## 4. Fact Tables

### 4.1 `dbo.fact_transactions`
Transaction-level fact table (grain: one transaction).

Core fields:

- natural key: `transaction_id`
- foreign keys: `date_key`, `user_key`, `card_key`, `mcc_key`
- `txn_date`, `txn_month`
- measures: `amount`, `currency`
- flags: `is_success`

### 4.2 `dbo.fact_transactions_daily`
Daily aggregated transactions (grain: day).

Contains daily counts and amounts derived from `fact_transactions`.

### 4.3 `dbo.fact_transactions_monthly`
Monthly aggregated transactions (grain: month).

Contains monthly counts and amounts derived from `fact_transactions`.

---

## 5. Notes on Governance & Stability

### 5.1 Deterministic monthly scope
Pipelines and procedures can scope processing to a single month via `@TxnMonth`.

### 5.2 Auditability
Every run can be reconstructed using:

- `dbo.wh_run` (summary)
- `dbo.wh_job_run_log` (job-level logs)
- `dbo.wh_dq_check_result` (DQ outputs)
- control tables (metric details)

---

## 6. Source of Truth

If you need the complete column-level DDL (all columns, types, constraints), refer to:

- `04-DWH/dwh-model-dll.sql`

