# Silver Orchestration

## Orchestration Artifacts
- **Pipeline**: `pl_silver_load_generic`
- **Dispatcher notebook**: `nb_silver_load`
- **Child notebooks**:
  - `nb_silver_cards`
  - `nb_silver_fx`
  - `nb_silver_mcc`
  - `nb_silver_transactions`
  - `nb_silver_users`

## Orchestration Philosophy
The Silver layer uses a **pipeline-driven orchestration model** where:
- The pipeline is the source of truth for the run context
- The dispatcher controls execution order and logging
- Child notebooks are stateless and context-driven

## Pipeline Parameters

| Parameter | Description |
|---------|-------------|
| `p_entity_code` | Entity selector (`CARDS`, `FX`, `MCC`, `TRANSACTIONS`, `USERS`, `ALL`, list) |
| `p_load_mode` | Load strategy (`FULL`, `INCR`) |
| `p_as_of_date` | Optional reference date |
| `p_environment` | `dev` / `test` / `prod` |
| `p_triggered_by` | `manual` / `schedule` |
| `p_pipeline_name` | Fixed: `pl_silver_load_generic` |
| `p_silver_run_id` | **Injected as `@pipeline().RunId`** |

## Execution Flow
1. Pipeline initializes `p_silver_run_id`
2. `nb_silver_load` starts a run in `silver_log_runs`
3. Dispatcher reads enabled entities from `silver_ctl_entity`
4. For each entity:
   - Write `RUNNING` step in `silver_log_steps`
   - Execute child notebook
   - Capture metrics and final status (from `silver_entity_payload`)
5. Dispatcher finalizes the run (`SUCCESS`, `FAILED`, `PARTIAL`)

## Key Rule
The pipeline is the **only component allowed to define the Silver run identity**.

