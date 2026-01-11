# Notebook Execution Contract – Silver Layer

## Dispatcher Notebook (`nb_silver_load`)

Responsibilities:
- Validate pipeline parameters
- Enforce `silver_run_id` governance
- Initialize `silver_log_runs`
- Orchestrate execution of child notebooks
- Write step-level logs and metrics
- Finalize run status

Key rule:
`nb_silver_load` must never generate a new `silver_run_id` when executed from a pipeline.

## Child Notebooks (`nb_silver_*`)

Each child notebook must follow the same contract.

### Mandatory Steps
1. Execute:
   ```python
   %run ./nb_silver_utils
   ```

2. Initialize context from dispatcher:
   - Use the `silver_run_id` passed from dispatcher
   - Read execution context from `silver_log_steps`
   - Never generate a new run ID

3. Process entity data:
   - Read from Bronze layer tables
   - Apply cleaning, deduplication, and enrichment
   - Perform quality checks (fail-fast strategy)
   - Write to Silver table

4. Return standardized payload:
   - Follow the `silver_entity_payload` contract
   - Include metrics: `row_in`, `row_out`, `dedup_dropped`, `partition_count`
   - Include timing information
   - Include quality check results

5. Update step status in `silver_log_steps`:
   - Write metrics and status
   - Store payload JSON for audit trail

### Payload Contract
All child notebooks must return a payload conforming to `silver_entity_payload`:
- `run_id`: The `silver_run_id` from pipeline
- `entity_code`: Entity identifier (e.g., `CARDS`, `FX`, `MCC`, `TRANSACTIONS`, `USERS`)
- `status`: Execution status (`SUCCESS`, `FAILED`)
- `metrics`: Row counts and processing metrics
- `table`: Target table information
- `timing`: Execution timing
- `quality`: Quality check results

## Key Principles
- **Stateless execution**: Child notebooks must not maintain state between runs
- **Idempotent operations**: FULL rebuilds must be deterministic
- **Fail-fast**: Quality checks stop execution on failure
- **Audit trail**: All operations logged to `silver_log_steps`

