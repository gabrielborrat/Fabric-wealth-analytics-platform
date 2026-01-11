# Run IDs & Logging Model

## Run ID Governance (Option A)
The platform enforces **pipeline-driven run identity**.

### Pipeline Execution
- `gold_run_id = @pipeline().RunId`
- The same identifier is propagated to:
  - `gold_log_runs`
  - `gold_log_steps`
  - all Gold tables
  - anomaly tables

### Manual Execution
- If no pipeline context exists, a run ID may be generated
- This mode is for development or debugging only

## Logging Tables

### gold_log_runs
One row per Gold execution.

Key columns:
- `gold_run_id`
- `pipeline_name`
- `layer` (`gold`)
- `status` (`RUNNING`, `SUCCESS`, `FAILED`, `PARTIAL`)
- `start_ts`, `end_ts`, `duration_ms`
- `params_json`
- `error_message`

### gold_log_steps
Append-only table, one row per entity step.

Key columns:
- `gold_run_id`
- `step_seq`
- `entity_code`
- `notebook_name`
- `status`
- `row_in`, `row_out`, `row_rejected`
- `payload_json`
  - contains the execution context (`ctx`)
  - acts as the source of truth for child notebooks

## Anomaly Tracking

### gold_anomaly_event
- Row-level anomalies
- Linked to `gold_run_id`
- Includes severity, rule, domain, and natural keys

### gold_anomaly_kpi
- Aggregated anomaly counts per run and rule
- Used for monitoring and SLA reporting

## Audit Guarantees
- Full traceability from pipeline to record
- Deterministic replay
- Clear separation between orchestration and computation
