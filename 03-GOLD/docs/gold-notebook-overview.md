# Gold Layer — Notebook Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

This document provides a technical description of the **Gold notebooks** used in the Wealth Management Analytics Platform.

Gold notebooks implement a **contract-first, banking-grade** execution design:

- no implicit schema inference
- deterministic, repeatable runs
- strict conformance to dimensions
- auditable logs and anomaly events

---

## 2. `nb_gold_load` — Gold Dispatcher Notebook

`nb_gold_load` is the central dispatcher that orchestrates entity-level notebooks (dimensions then facts).

### 2.1 Role

- Reads the execution request (entity, mode, context)
- Uses a control-driven approach (entity metadata in a control table)
- Writes step-level RUNNING logs including a JSON payload containing execution context (`ctx`)
- Invokes the appropriate child notebook
- Collects deterministic exit payloads (metrics/status) from child notebooks
- Finalizes run-level status (SUCCESS / FAILED / PARTIAL)

### 2.2 Control + Logging Tables (Logical)

Gold notebooks reference a standard set of managed tables:

- `gold_ctl_entity` — entity control (enabled, order, notebook_name, critical, retries, timeouts, target_table)
- `gold_log_runs` — run-level log (start/end, status, metrics)
- `gold_log_steps` — step-level log (per entity, status, payload_json)
- `gold_anomaly_event` — append-only anomaly events (conformance violations, rejected records)

---

## 3. `nb_gold_utils` — Shared Utilities

`nb_gold_utils` provides reusable primitives:

### 3.1 Contract-first assertions

- `assert_required_columns`
- `assert_no_additional_columns`
- `assert_column_types`
- `assert_not_null`
- `assert_unique_key`

These are used to guarantee schema stability and key constraints.

### 3.2 Hash helpers

- `add_key_hash` (stable natural key hash)
- `add_natural_keys_json` (audit-friendly representation)

Hashes enable deterministic idempotency and record change detection.

### 3.3 Conformance helpers

- orphan detection using join semantics (e.g. left_anti)
- split outputs into conforming vs non-conforming
- provide metadata for anomaly event creation

---

## 4. Entity Notebooks

Gold implements one notebook per dimension/fact:

### 4.1 Dimensions

- `nb_gold_dim_date`
- `nb_gold_dim_mcc`
- `nb_gold_dim_user`
- `nb_gold_dim_card`

Shared principles:

- Read execution context from `gold_log_steps` (latest RUNNING step for the notebook)
- Deduplicate using latest `ingestion_ts`
- Apply strict schema and key constraints
- Rebuild target deterministically (commonly TRUNCATE + APPEND)

### 4.2 Facts

- `nb_gold_fact_transactions`

Additional principles for facts:

- Enforce dimensional conformance to all referenced dimensions
- Exclude orphan rows from the output
- Log anomalies append-only for auditability
- Rebuild in an idempotent manner (commonly partition-scoped rebuild using `txn_month`)

---

## 5. `nb_gold_ddl` — Gold DDL / Initialization

`nb_gold_ddl` is responsible for creating or initializing Gold tables required by:

- the dimensional model
- the Gold control/logging/anomaly tables

The notebook should be run once per environment/workspace initialization, and then on schema evolution events under change control.

---

## 6. Execution Contract Summary

Gold notebooks follow a consistent contract:

- **No runtime arguments** for entity notebooks
- **Dispatcher writes RUNNING ctx** into `gold_log_steps`
- **Entity notebooks read ctx**, validate required fields, execute deterministically
- **Entity notebooks return metrics** (rows, status, anomalies) back to dispatcher

This approach increases reproducibility and simplifies operational debugging.

---

## 7. Conclusion

Gold notebooks provide a contract-first, observable, and auditable transformation layer that builds business-ready star schema assets with strict conformance guarantees, enabling reliable analytics and Power BI consumption.

