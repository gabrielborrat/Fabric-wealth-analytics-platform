# DWH Layer — Pipeline Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

This document describes the **Fabric Pipeline architecture** that orchestrates the DWH (Data Warehouse) layer refresh.  
It focuses on:

- job registry-driven execution (`dbo.wh_ctl_job`)
- group pipelines (DIMS / FACTS / AGG / CONTROLS / PUBLISH)
- end-to-end monthly orchestration (`pl_dwh_refresh_month_e2e`)
- dynamic parameter passing (`p_TxnMonth`, `p_ExecDate`, `p_RunId`)
- failure handling and “critical job” escalation

---

## 2. Core Design: Job Registry Driven Execution

All DWH pipelines execute jobs from a single control table:

- `dbo.wh_ctl_job`

Each job row provides:

- `job_group`: one of `DIMS`, `FACTS`, `AGG`, `CONTROLS`, `PUBLISH`
- `job_order`: deterministic ordering within the group
- `sp_schema`, `sp_name`: stored procedure to execute
- `enabled`: whether the job is active
- `is_critical`: whether a failure must stop the pipeline
- `needs_txn_month`, `needs_exec_date`: required parameter flags

This avoids hardcoding stored procedure lists in pipelines and makes the DWH layer **configurable via data**.

---

## 3. Group Pipelines (per job_group)

### 3.1 Shared pattern

The pipelines below share the same structure:

1. **GetJobList** (Script / Query)  
   Reads enabled jobs for a given group:
   - `WHERE enabled = 1 AND job_group = '<GROUP>' ORDER BY job_order`

2. **ForEachJobs**  
   Iterates over the job list rows:
   - `items = @activity('GetJobList').output.resultSets[0].rows`

3. **If_Condition_TxnMonth** (IfCondition)  
   Ensures required parameters are present before executing the job:
   - If the job requires `TxnMonth`, pipeline must have `p_TxnMonth`
   - If the job requires `ExecDate`, pipeline must have `p_ExecDate`

4. **RunJobSP** (Script / NonQuery)  
   Executes the stored procedure dynamically using `@concat(...)`, passing:
   - `@RunId`
   - `@JobId`
   - Optional `@TxnMonth`
   - Optional `@ExecDate`

5. **If_JobFailed_Critical**  
   If the previous block fails and `is_critical = 1`, the pipeline **fails intentionally**.

### 3.2 Pipelines

- `pl_dwh_refresh_dimensions` → executes jobs where `job_group = 'DIMS'`
- `pl_dwh_refresh_facts` → executes jobs where `job_group = 'FACTS'`
- `pl_dwh_refresh_aggregates` → executes jobs where `job_group = 'AGG'`
- `pl_dwh_refresh_controls` → executes jobs where `job_group = 'CONTROLS'`
- `pl_dwh_publish` → executes jobs where `job_group = 'PUBLISH'`

---

## 4. End-to-End Monthly Orchestrator: pl_dwh_refresh_month_e2e

### 4.1 Purpose

`pl_dwh_refresh_month_e2e` orchestrates the full monthly refresh in a deterministic order:

1. `Run_Dimensions`  
2. `Run_Facts`  
3. `Run_Aggregates`  
4. `Run_Controls`  
5. `Run_Publish`  
6. `Finalize_Run` (persist run-level summary via `dbo.sp_pub_wh_run_refresh`)

### 4.2 RunId handling

The pipeline sets `vRunId` as:

- If `p_RunId` is empty/null → uses `pipeline().RunId`
- Otherwise → uses `p_RunId`

This allows external correlation while keeping a safe default.

### 4.3 Parameters

Orchestrator parameters (expected):

| Parameter | Type | Description |
|---|---|---|
| `p_TxnMonth` | string/date | Month scope for refresh (typically month start) |
| `p_ExecDate` | string/date | Execution date (for audit/logging) |
| `p_RunId` | string | Optional external run id |

Child pipeline parameters are passed through consistently.

---

## 5. Operational Notes

### 5.1 Where logic lives

- Pipelines orchestrate and pass parameters
- Stored procedures implement refresh and DQ logic (see `04-DWH/dwh-sp-ddl.sql`)
- DDL defines the warehouse model (see `04-DWH/dwh-model-dll.sql`)

### 5.2 Failure model

- Non-critical job failure: job run logs capture failure; pipeline continues
- Critical job failure: pipeline fails fast (Fail activity), stopping the group/orchestrator

---

## 6. Extensibility Model

To add a new DWH job:

1. Create a stored procedure (or reuse existing) in `dwh-sp-ddl.sql`
2. Register the job in `dbo.wh_ctl_job`:
   - assign `job_group`, `job_order`
   - set `enabled`, `is_critical`
   - set parameter requirements flags

No pipeline modification is required.

