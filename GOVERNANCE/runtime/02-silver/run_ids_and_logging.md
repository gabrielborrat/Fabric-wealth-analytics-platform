# Run IDs & Logging Model

## Run ID Governance (Option A)
The platform enforces **pipeline-driven run identity**.

### Pipeline Execution
- `silver_run_id = @pipeline().RunId`
- The same identifier is propagated to:
  - `silver_log_runs`
  - `silver_log_steps`
  - all Silver tables
  - control tables

### Manual Execution
- If no pipeline context exists, a run ID may be generated
- This mode is for development or debugging only

## Logging Tables

### silver_log_runs
One row per Silver execution.

Key columns:
- `silver_run_id`
- `pipeline_name`
- `layer` (`silver`)
- `status` (`RUNNING`, `SUCCESS`, `FAILED`, `PARTIAL`)
- `start_ts`, `end_ts`, `duration_ms`
- `params_json`
- `error_message`

### silver_log_steps
Append-only table, one row per entity step.

Key columns:
- `silver_run_id`
- `step_seq`
- `entity_code` (`CARDS`, `FX`, `MCC`, `TRANSACTIONS`, `USERS`)
- `notebook_name`
- `status`
- `row_in`, `row_out`, `row_rejected`, `dedup_dropped`
- `payload_json`
  - contains the execution context (`ctx`)
  - acts as the source of truth for child notebooks
  - follows the `silver_entity_payload` contract

## Entity Payload Contract

All `nb_silver_*` entity notebooks return a standardized payload (`silver_entity_payload`) containing:
- Execution metadata (`run_id`, `entity_code`, `status`)
- Metrics (`row_in`, `row_out`, `dedup_dropped`, `partition_count`)
- Table information (`target_table`, `partition_cols`)
- Timing information (`started_utc`, `ended_utc`, `duration_ms`)
- Quality checks (`fail_fast_checks`)

This payload is logged to `silver_log_steps` and enables:
- End-to-end traceability
- Performance monitoring
- Quality metrics tracking
- Deterministic replay

## Audit Guarantees
- Full traceability from pipeline to record
- Deterministic replay
- Clear separation between orchestration and computation
- Quality checks logged and auditable

