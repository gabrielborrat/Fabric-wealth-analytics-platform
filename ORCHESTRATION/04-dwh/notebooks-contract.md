# Execution Contract – DWH Layer

## Purpose

The DWH layer is executed through **Fabric Pipeline Script activities** calling **T-SQL stored procedures** in the Fabric Data Warehouse.  
This contract describes the expectations for:

- pipeline parameters (RunId, TxnMonth, ExecDate)
- job registry behavior (`dbo.wh_ctl_job`)
- stored procedure execution and logging
- publish gating

> Note: Unlike Bronze/Silver/Gold, the DWH layer does not rely on Spark notebooks as the primary execution unit.  
> The equivalent “unit of work” here is a **stored procedure job** referenced by `dbo.wh_ctl_job`.

---

## Job Execution Contract (Stored Procedure Job)

Each enabled job in `dbo.wh_ctl_job` must conform to the following:

### Responsibilities
- Implement deterministic, idempotent logic for its scope (typically `@TxnMonth`)
- Write a STARTED entry in `dbo.wh_job_run_log`
- Write a SUCCESS/FAILED entry in `dbo.wh_job_run_log` with timestamps and a message
- If a DQ/control job: write results in `dbo.wh_dq_check_result` (and/or control tables)

### Parameters
Pipelines will call procedures with the following parameters (when required):

- `@RunId`: correlation id for the whole orchestration run
- `@JobId`: job identifier (`job_code`)
- `@TxnMonth`: month scope (only when `needs_txn_month = 1`)
- `@ExecDate`: execution date (only when `needs_exec_date = 1`)

### Mandatory Steps (recommended structure)
1. Determine `@RunId` fallback if empty/null (optional, but recommended for direct/manual execution)
2. Insert STARTED row into `dbo.wh_job_run_log`
3. Execute the business logic (refresh / control / publish)
4. Persist any control outputs (DQ tables, publish status)
5. Insert SUCCESS row into `dbo.wh_job_run_log`
6. On exception: insert FAILED row into `dbo.wh_job_run_log`, then rethrow

### Key Rules
- **Deterministic month scoping**: if the job uses `@TxnMonth`, it must not “leak” outside the month
- **Audit first**: always log STARTED/SUCCESS/FAILED
- **Fail fast for critical jobs**: if a job is configured as critical (`is_critical = 1`), failures must propagate (throw) so the pipeline can stop

---

## Group Pipeline Contract (DIMS / FACTS / AGG / CONTROLS / PUBLISH)

Each group pipeline must:

1. Select enabled jobs from `dbo.wh_ctl_job` for its group, ordered by `job_order`
2. Execute jobs sequentially (deterministic)
3. Enforce required parameter presence via `needs_txn_month` / `needs_exec_date`
4. Fail the pipeline if a **critical** job fails

---

## Orchestrator Contract (`pl_dwh_refresh_month_e2e`)

Responsibilities:
- Define the run context (`RunId`, `TxnMonth`, `ExecDate`)
- Execute DWH groups in a deterministic sequence:
  1. Dimensions
  2. Facts
  3. Aggregates
  4. Controls
  5. Publish
- Finalize the run summary (via `dbo.sp_pub_wh_run_refresh`)

### Parameters
- `p_TxnMonth`: month scope
- `p_ExecDate`: execution date
- `p_RunId`: optional external run id

### Key Rule
The orchestrator is the **only component allowed to define** the DWH run identity used by all downstream logs.

---

## Publish Contract

Publish jobs (job_group = `PUBLISH`) must:
- Validate readiness/freshness before publishing
- Persist decision in publish control tables (e.g. `dbo.ctrl_publish_status`)
- Trigger downstream actions only when conditions are met (e.g. semantic model refresh)

