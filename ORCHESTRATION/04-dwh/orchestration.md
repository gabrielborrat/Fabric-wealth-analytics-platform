# DWH Orchestration

## Orchestration Artifacts
- **End-to-end Orchestrator Pipeline**: `pl_dwh_refresh_month_e2e`
- **Group Pipelines**:
  - `pl_dwh_refresh_dimensions` (job_group = `DIMS`)
  - `pl_dwh_refresh_facts` (job_group = `FACTS`)
  - `pl_dwh_refresh_aggregates` (job_group = `AGG`)
  - `pl_dwh_refresh_controls` (job_group = `CONTROLS`)
  - `pl_dwh_publish` (job_group = `PUBLISH`)
- **Warehouse (target)**: `wh_wm_analytics` (schema `dbo`)
- **Execution logic**: T-SQL stored procedures (executed via Fabric Pipeline Script activities)

## Orchestration Philosophy
The DWH layer uses a **job-registry-driven orchestration model** where:
- Pipelines orchestrate *when* and *in which order* groups run
- The warehouse control table `dbo.wh_ctl_job` defines *which jobs* run in each group
- Stored procedures implement the transformation + DQ + publish logic
- Run identity is consistent across the whole execution (`RunId`)

## Pipeline Parameters (Run Context)

The DWH orchestration is month-scoped and designed for deterministic reprocessing.

| Parameter | Description |
|---------|-------------|
| `p_TxnMonth` | Month scope (DATE) for refresh / DQ / publish checks (typically month start) |
| `p_ExecDate` | Execution date used for audit logging (DATE) |
| `p_RunId` | Optional external run id. If empty/null, the pipeline uses `@pipeline().RunId` |

## Execution Flow (End-to-End)
1. `pl_dwh_refresh_month_e2e` initializes `RunId` (variable `vRunId`)
2. Run groups sequentially:
   - `Run_Dimensions` → `pl_dwh_refresh_dimensions`
   - `Run_Facts` → `pl_dwh_refresh_facts`
   - `Run_Aggregates` → `pl_dwh_refresh_aggregates`
   - `Run_Controls` → `pl_dwh_refresh_controls`
   - `Run_Publish` → `pl_dwh_publish`
3. Finalize run summary (`Finalize_Run`) via `dbo.sp_pub_wh_run_refresh`

## Group Pipeline Pattern (Job Registry)

Each group pipeline uses the same pattern:

1. Query `dbo.wh_ctl_job` to get enabled jobs for the group (ordered by `job_order`)
2. ForEach job:
   - Verify required parameters exist (based on `needs_txn_month` / `needs_exec_date`)
   - Execute the configured stored procedure (`sp_schema.sp_name`)
   - If the job is critical and fails (`is_critical = 1`), fail the pipeline

## Key Rule
The orchestrator pipeline is the **single source of truth** for the DWH run identity (`RunId`) used for:
- `dbo.wh_job_run_log` (job-level auditing)
- `dbo.wh_dq_check_result` (DQ outcomes)
- `dbo.wh_run` (run summary)

