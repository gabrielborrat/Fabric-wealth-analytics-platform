# Gold Layer Overview  
**Wealth Management Analytics Platform – Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

The Gold Layer is the **business-ready analytics layer** of the Wealth Management Analytics Platform built on Microsoft Fabric.  
It transforms curated Silver datasets into a **conformed star schema** (Dimensions + Facts), optimized for:

- **Direct Lake** Power BI semantic models
- Consistent KPIs (AUM / PnL / Risk / Spend analytics)
- Deterministic, auditable, and “banking-grade” execution

Gold is intentionally **contract-first** and enforces:

- Strict schemas (expected columns + data types)
- Stable natural keys and record hashes
- Deduplication rules (keep latest by `ingestion_ts`)
- **Dimensional conformance** (no orphan foreign keys in facts)
- Append-only anomaly logging for non-conforming records

---

## 2. Objectives of the Gold Layer

### 2.1 Deliver a conformed analytical model
Provide a stable dimensional model (dims + facts) that downstream analytics can rely on.

### 2.2 Enforce banking-grade data contracts
Guarantee reproducibility and schema stability (no hidden schema drift).

### 2.3 Guarantee conformance and integrity
Ensure facts only reference valid dimension members; log violations as anomalies.

### 2.4 Provide operational observability
Provide run-level and step-level execution logs (RUNNING/SUCCESS/FAILED/PARTIAL) with deterministic metrics.

---

## 3. Architecture Summary

### 3.1 `pl_gold_load_generic` — Generic Gold Load Pipeline

`pl_gold_load_generic` executes the **Gold dispatcher notebook** and is entirely parameter-driven.  
It passes context such as:

- `p_entity_code` (e.g. `dim_date`, `fact_transactions`)
- `p_load_mode` (e.g. FULL)
- `p_as_of_date` (optional; used for temporal loads if needed)
- `p_environment`, `p_triggered_by`, `p_pipeline_name`

### 3.2 `pl_gold_master` — Gold Orchestration Pipeline

`pl_gold_master` orchestrates the Gold entities sequentially (dimensions then facts).  
Current sequence (as implemented):

- `dim_date`
- `dim_mcc`
- `dim_user`
- `dim_card`
- `fact_transactions`

This ordering ensures foreign keys exist before dependent entities are built.

### 3.3 Gold Notebooks (Entity-Level Implementations)

Gold logic is implemented in Fabric notebooks:

- **Dispatcher**: `nb_gold_load` (data-driven orchestration)
- **Utilities**: `nb_gold_utils` (assertions, conformance helpers, hashing)
- **DDL**: `nb_gold_ddl` (table creation/initialization)
- **Entity notebooks**:
  - `nb_gold_dim_date`
  - `nb_gold_dim_mcc`
  - `nb_gold_dim_user`
  - `nb_gold_dim_card`
  - `nb_gold_fact_transactions`

---

## 4. Gold Data Model (Star Schema)

Gold provides a core star schema aligned with the warehouse model:

- **Dimensions**
  - `gold_dim_date`
  - `gold_dim_mcc`
  - `gold_dim_user`
  - `gold_dim_card`
- **Facts**
  - `gold_fact_transactions`

Each entity exposes stable business keys and supporting attributes; facts enforce referential integrity to dimensions.

---

## 5. Data Quality & Conformance in Gold

Gold implements a strict conformance process:

- **Deduplication**: keep latest record by `ingestion_ts`
- **Key hashing / record hash**: stable hash for change detection and idempotency
- **Orphan handling**: rows with missing dimension keys are:
  - excluded from Gold fact tables
  - logged into anomaly tables (append-only)

---

## 6. Conclusion

The Gold Layer delivers a **conformed, contract-first, analytics-optimized** model ready for Power BI and enterprise reporting.  
It bridges engineering-grade Silver outputs to business-grade, governed, and observable analytics assets.

