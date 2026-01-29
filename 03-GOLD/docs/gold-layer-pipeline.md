# Gold Layer — Pipeline Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

This document describes the **Gold pipeline architecture** powering the Gold Layer of the Wealth Management Analytics Platform.  
It covers:

- the **generic execution pipeline** (`pl_gold_load_generic`)
- the **master orchestration pipeline** (`pl_gold_master`)
- parameters and execution context
- ordering rules (dims → facts)
- logging and anomaly handling principles

Gold pipelines are designed for **deterministic, auditable, banking-grade execution**.

---

## 2. Pipeline Architecture Overview

Gold uses a simple but robust orchestration pattern:

- `pl_gold_master` orchestrates the sequence of entities
- each entity load is executed through `pl_gold_load_generic`
- `pl_gold_load_generic` triggers the Gold dispatcher notebook, which in turn runs the correct entity notebook

This allows:

- single, reusable pipeline logic
- consistent run metadata and logging
- easy extensibility (add a new entity without duplicating pipelines)

---

## 3. `pl_gold_load_generic` — Generic Gold Load Pipeline

### 3.1 Purpose

`pl_gold_load_generic` is the single entry point to execute a Gold load for a given `p_entity_code`.  
It invokes the Fabric notebook (dispatcher) and passes parameters consistently.

### 3.2 Parameters

| Parameter | Description |
|----------|-------------|
| `p_entity_code` | Gold entity identifier (e.g. `dim_date`, `fact_transactions`). |
| `p_load_mode` | Load mode (typically `FULL`). |
| `p_as_of_date` | Optional “as of” date string for time-point processing. |
| `p_environment` | Environment tag (e.g. `dev`). |
| `p_triggered_by` | Trigger origin (manual/schedule). |
| `p_pipeline_name` | Caller pipeline name (defaults to `pl_gold_load_generic`). |
| `p_gold_run_id` | Run id injected/propagated by the pipeline. |

### 3.3 High-Level Flow

1. **SetVariable**: set `v_gold_run_id = @pipeline().RunId`
2. **TridentNotebook**: execute Gold notebook with parameters:
   - `p_entity_code`
   - `p_load_mode`
   - `p_as_of_date`
   - `p_environment`
   - `p_triggered_by`
   - `p_pipeline_name`
   - `p_gold_run_id`

### 3.4 Idempotency Expectations

Gold notebooks are expected to be **idempotent** for a given logical execution scope by using deterministic keys/hashes and rebuild patterns (commonly TRUNCATE + APPEND for dimensions and partition-scoped rebuilds for facts).

---

## 4. `pl_gold_master` — Master Orchestration Pipeline

### 4.1 Purpose

`pl_gold_master` is the orchestrator pipeline that runs Gold entities in a deterministic order.  
It invokes `pl_gold_load_generic` for each entity using `InvokePipeline` activities.

### 4.2 Execution Order

Current ordering implemented (sequential):

1. `dim_date`
2. `dim_mcc`
3. `dim_user`
4. `dim_card`
5. `fact_transactions`

Rationale:

- dimensions must exist before facts for conformance checks
- card depends on user (card → client)
- the transactions fact depends on all dimensions

### 4.3 Retry / Timeout Policies

Activities use Fabric pipeline policies:

- `timeout`: `"0.12:00:00"` (12 hours)
- `retry`: `0` (notebook-level retry is typically handled by the dispatcher/entity contract)

---

## 5. Logging & Observability (Gold)

Gold execution is designed to support:

- **Run-level logging** (overall status, timing, metrics)
- **Step-level logging** (per entity notebook execution)
- Deterministic payloads (context JSON)

Gold notebooks operate in a **data-driven mode** where the dispatcher writes a RUNNING step record, and entity notebooks read their context from that table (instead of relying on runtime args).

---

## 6. Anomaly Handling

Gold facts enforce dimensional conformance. Records that violate conformance rules are:

- excluded from the Gold fact output
- logged into anomaly tables (append-only) with rule identifiers and severity

This keeps Gold consumption safe while preserving full traceability.

---

## 7. Extensibility Model

To add a new Gold entity:

1. Create a new notebook `nb_gold_<entity>`
2. Register it in the Gold control table (dispatcher-driven)
3. Add the entity invocation in `pl_gold_master` (or keep it data-driven in dispatcher, depending on target governance model)

No duplication of pipelines is required.

---

## 8. Conclusion

Gold pipelines implement a **simple, repeatable, and auditable orchestration pattern**: one master orchestrator + one generic executor, with strict logging and conformance controls to ensure business-grade analytics outputs.

