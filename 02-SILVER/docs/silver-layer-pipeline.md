# Silver Layer — Pipeline Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

This document describes the **transformation pipeline architecture** powering the Silver Layer of the Wealth Management Analytics Platform.  
It covers:

- the **generic transformation pipeline** (`pl_silver_load_generic`)  
- the **master orchestration pipeline** (`pl_silver_master`)  
- pipeline parameters and dynamic expressions  
- entity dependency management  
- retry policies and resilience mechanisms  
- operational and governance considerations  

The pipelines are designed according to **banking-grade engineering and observability standards**, ensuring deterministic, auditable, and fully traceable transformation flows.

---

## 2. Pipeline Architecture Overview

### 2.1 Multi-Entity, Unified Transformation Framework

All Silver transformations — regardless of entity (FX, Users, Cards, MCC, Transactions) — follow a **single transformation pattern** implemented through:

1. `pl_silver_load_generic` — parameter-driven transformation logic  
2. `nb_silver_load` — dispatcher notebook that routes to entity-specific notebooks  
3. Entity-specific notebooks (nb_silver_fx, nb_silver_users, etc.)  
4. Bronze → Silver transformation with deduplication  
5. Write to managed Delta tables with partitioning  

This approach ensures:

- no duplication of pipelines  
- easy onboarding of new entities  
- full alignment of transformation behaviors  
- maintainability and observability across environments  

---

## 3. pl_silver_load_generic — Generic Transformation Pipeline

The **core pipeline** used for every Silver entity.

### 3.1 Pipeline Parameters

| Parameter | Description |
|----------|-------------|
| `p_entity_code` | The entity identifier (fx_rates, users, cards, mcc, transactions). Used for routing in the notebook. |
| `p_load_mode` | FULL or INCREMENTAL (incremental based on ingestion_ts or as_of_date). |
| `p_as_of_date` | Optional execution date for point-in-time processing (YYYY-MM-DD format). |
| `p_run_id` | Optional run identifier. If empty, pipeline generates one automatically. |

These parameters ensure full configurability and avoid hardcoding entity logic.

---

### 3.2 High-Level Pipeline Flow

1. **SetRunId**  
   - Generates unique run identifier if not provided.  
   - Format: `silver_YYYYMMDD_HHmmss_<pipeline_run_id>`  
   - Stored in variable `v_run_id`.

2. **NotebookSilverLoad**  
   - Executes `nb_silver_load` notebook.  
   - Passes parameters: `run_id`, `entity_code`, `load_mode`, `as_of_date`.  
   - Notebook dispatches to entity-specific transformation notebook.  
   - Entity notebook performs:
     - Read from Bronze table
     - Clean, validate, and type data
     - Deduplicate based on natural keys
     - Add technical metadata and record_hash
     - Write to Silver Delta table
   - Retry enabled (2 attempts).

---

## 4. Dynamic Expressions

### 4.1 Run ID Generation
```
@if(
  equals(pipeline().parameters.p_run_id, ''),
  concat(
    'silver_',
    formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'),
    '_',
    pipeline().RunId
  ),
  pipeline().parameters.p_run_id
)
```

This ensures every run has a unique, traceable identifier.

### 4.2 Parameter Passing
Parameters are passed to the notebook as Fabric-compliant parameter cells:
- `run_id` → `@variables('v_run_id')`
- `entity_code` → `@pipeline().parameters.p_entity_code`
- `load_mode` → `@pipeline().parameters.p_load_mode`
- `as_of_date` → `@pipeline().parameters.p_as_of_date`

---

## 5. pl_silver_master — Master Orchestration Pipeline

This pipeline ensures deterministic ordering and dependency management of Silver transformations.

### 5.1 Execution Sequence

The master pipeline executes entities in the following order with explicit dependencies:

1. **InvokeSilverMcc**  
   - Entity: `mcc`  
   - Dependencies: None (reference data)  
   - Load mode: `full`

2. **InvokeSilverUsers**  
   - Entity: `users`  
   - Dependencies: `InvokeSilverMcc` (Succeeded)  
   - Load mode: `full`

3. **InvokeSilverCards**  
   - Entity: `cards`  
   - Dependencies: `InvokeSilverUsers` (Succeeded)  
   - Load mode: `full`

4. **InvokeSilverFX**  
   - Entity: `fx_rates`  
   - Dependencies: `InvokeSilverCards` (Succeeded)  
   - Load mode: `full`

5. **InvokeSilverTransactions**  
   - Entity: `transactions`  
   - Dependencies: `InvokeSilverFX` (Succeeded)  
   - Load mode: `full`

### 5.2 Benefits

- **Referential integrity**: Ensures parent entities (MCC, Users, Cards) are loaded before dependent entities (Transactions)  
- **Unified governance entry point**: Single pipeline to trigger all Silver transformations  
- **Clean observability**: Parent → child pipeline runs provide clear execution hierarchy  
- **Clear operational procedures**: Standardized execution order simplifies operations  
- **Easier scheduling**: Single trigger point for daily Silver refresh  

### 5.3 Trigger Strategy

- Daily after Bronze ingestion completes  
- Event-based triggers optional for future enhancements  
- Can be triggered manually for ad-hoc processing  

---

## 6. Entity Dependency Management

### 6.1 Dependency Graph

```
MCC (no dependencies)
  ↓
Users (depends on MCC)
  ↓
Cards (depends on Users)
  ↓
FX Rates (depends on Cards)
  ↓
Transactions (depends on FX, Cards, Users, MCC)
```

### 6.2 Rationale

- **MCC**: Reference data, no dependencies
- **Users**: May reference MCC codes in future enhancements
- **Cards**: Requires Users to exist for client_id foreign key validation
- **FX Rates**: Independent but sequenced after Cards for operational consistency
- **Transactions**: Requires all parent entities for foreign key integrity

This ordering ensures:
- Foreign key relationships can be validated
- Gold layer joins will have complete dimension data
- Data quality checks can reference parent tables

---

## 7. Retry Mechanisms

To provide production-grade resilience:

### Notebook Activities
- Retry count: **2**
- Retry interval: **120 seconds**

Benefits:
- Tolerates transient Spark cluster issues
- Stabilizes transformation of large datasets
- Avoids unnecessary run failures

---

## 8. Load Modes

### 8.1 FULL Mode

Processes all records from the Bronze table.

**Use cases:**
- Initial Silver population
- Historical backfills
- Reprocessing after schema changes
- Data quality remediation

**Implementation:**
- Reads entire Bronze table
- Applies all transformations
- Deduplicates and writes to Silver

### 8.2 INCREMENTAL Mode

Processes only new or changed records from Bronze.

**Use cases:**
- Daily processing of new transactions
- Efficient processing of large historical tables
- Point-in-time reprocessing

**Implementation:**
- Filters Bronze by `ingestion_ts >= last_processed_timestamp`
- Or uses `as_of_date` parameter for point-in-time processing
- Applies transformations and merges with existing Silver data

---

## 9. Error Handling & Resilience

### 9.1 Entity-Level Failure Isolation

Each entity transformation is isolated:
- Failure of one entity does not prevent others from completing
- Master pipeline continues with remaining entities
- Clear error diagnostics per entity

### 9.2 Notebook-Level Validation

Silver notebooks implement **fail-fast** validation:
- Partition cardinality checks (fail if > 240 distinct months)
- Null constraint violations
- Schema mismatches
- Data type conversion errors

These fail immediately to prevent data quality issues from propagating.

### 9.3 Retry Strategy

Notebook retries handle:
- Transient Spark cluster issues
- Temporary resource constraints
- Network timeouts

After retries exhausted, pipeline fails with clear error message.

---

## 10. Governance & Observability Features

### 10.1 Run-Level Tracking

Every Silver transformation includes:
- Unique `run_id` for traceability
- Entity code for identification
- Load mode for audit
- Execution timestamp

### 10.2 Technical Metadata

All Silver tables include:
- `source_file` — Original Bronze source
- `ingestion_date` — Processing date
- `ingestion_ts` — Precise processing timestamp
- `record_hash` — SHA-256 hash for change detection

### 10.3 Deterministic Processing

Sequential execution ensures:
- Predictable ordering
- No concurrency side effects
- Reliable dependency resolution
- Reproducible results

---

## 11. Extensibility Model

To onboard a new Silver entity:

1. Create entity-specific notebook (e.g., `nb_silver_newentity`)
   - Follow standard transformation pattern
   - Implement deduplication logic
   - Add technical metadata
   - Write to Silver Delta table

2. Update `nb_silver_load` dispatcher
   - Add entity routing logic

3. Create Silver table DDL
   - Define schema in `nb_silver_ddl` or separate DDL script

4. Register entity in `pl_silver_master`
   - Add InvokePipeline activity
   - Set dependencies appropriately

5. Create Schema Registry contract
   - Add YAML file in `GOVERNANCE/schema-registry/02-silver/`

No pipeline duplication is required.  
No notebook re-engineering is necessary beyond the transformation module.

---

## 12. Conclusion

The Silver transformation pipelines implement a **unified, resilient, auditable transformation framework** fully aligned with banking data governance standards.

Key strengths:

- Fully parameterized transformation logic  
- Strict schema enforcement  
- Rich observability (run_id, technical metadata, record_hash)  
- Modular, reusable notebook architecture  
- Deterministic execution with dependency management  
- Extensibility without duplication  

This framework forms the operational backbone of the Silver layer and enables reliable downstream Gold analytical modeling, Data Warehouse transformations, and advanced Power BI reporting.

---
