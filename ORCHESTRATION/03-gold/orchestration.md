# Gold Orchestration

## Orchestration Artifacts
- **Pipeline**: `pl_gold_load_generic`
- **Dispatcher notebook**: `nb_gold_load`
- **Child notebooks**:
  - `nb_gold_dim_*`
  - `nb_gold_fact_*`

## Orchestration Philosophy
The Gold layer uses a **pipeline-driven orchestration model** where:
- The pipeline is the source of truth for the run context
- The dispatcher controls execution order and logging
- Child notebooks are stateless and context-driven

## Pipeline Parameters

| Parameter | Description |
|---------|------------|
| `p_entity_code` | Entity selector (`dim_mcc`, `ALL`, list) |
| `p_load_mode` | Load strategy (`FULL`) |
| `p_as_of_date` | Optional reference date |
| `p_environment` | `dev` / `test` / `prod` |
| `p_triggered_by` | `manual` / `schedule` |
| `p_pipeline_name` | Fixed: `pl_gold_load_generic` |
| `p_gold_run_id` | **Injected as `@pipeline().RunId`** |

## Execution Flow
1. Pipeline initializes `p_gold_run_id`
2. `nb_gold_load` starts a run in `gold_log_runs`
3. Dispatcher reads enabled entities from `gold_ctl_entity`
4. For each entity:
   - Write `RUNNING` step in `gold_log_steps`
   - Execute child notebook
   - Capture metrics and final status
5. Dispatcher finalizes the run (`SUCCESS`, `FAILED`, `PARTIAL`)

## Key Rule
The pipeline is the **only component allowed to define the Gold run identity**.
