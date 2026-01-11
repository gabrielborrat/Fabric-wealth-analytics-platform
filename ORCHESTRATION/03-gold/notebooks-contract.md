# Notebook Execution Contract – Gold Layer

## Dispatcher Notebook (`nb_gold_load`)

Responsibilities:
- Validate pipeline parameters
- Enforce `gold_run_id` governance
- Initialize `gold_log_runs`
- Orchestrate execution of child notebooks
- Write step-level logs and metrics
- Finalize run status

Key rule:
`nb_gold_load` must never generate a new `gold_run_id` when executed from a pipeline.

## Child Notebooks (`nb_gold_dim_*`, `nb_gold_fact_*`)

Each child notebook must follow the same contract.

### Mandatory Steps
1. Execute:
   ```python
   %run ./nb_gold_utils
