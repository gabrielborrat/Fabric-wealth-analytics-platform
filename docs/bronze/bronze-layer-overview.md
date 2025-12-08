# Bronze Layer Overview  
**Wealth Management Analytics Platform – Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

The Bronze Layer is the foundational ingestion tier of the Wealth Management Analytics Platform built on Microsoft Fabric. It centralizes raw-but-typed data from multiple heterogeneous sources (Amazon S3, Kaggle, CSV files, market instruments, stock/ETF OHLCV data, user data, card data, MCC codes, customer transactions, fundamentals, prices, and more).

Its mission is to provide a **stable, consistent, auditable, and banking-grade ingestion foundation** by enforcing:

- Column normalization (`snake_case`)
- Strict schema alignment
- Explicit data typing
- Technical metadata enrichment
- Full ingestion auditability (file-level + run-level)
- A unified ingestion framework across all datasets

The Bronze layer delivers stable Delta tables for the Silver engineering layer, the Gold business layer, and Direct Lake Power BI semantic models.

---

## 2. Objectives of the Bronze Layer

The Bronze Layer has five key objectives:

### 2.1 Centralize raw-but-typed datasets
Collect and standardize data from all upstream sources into OneLake.

### 2.2 Apply minimal but mandatory normalization
A unified `normalize_columns()` helper ensures clean, predictable, snake_case schemas independent of input formatting.

### 2.3 Enforce strict data typing
Business-critical fields are cast according to strict rules:

- Dates → DATE  
- Amounts → DOUBLE  
- Volumes → BIGINT  
- IDs → BIGINT / STRING  
- Flags → STRING (UPPER/TRIM)

### 2.4 Add technical metadata for governance
All Bronze tables include:

- `source_file`  
- `ingestion_date`  
- `ingestion_ts`  
- `entity`

### 2.5 Guarantee full auditability
Two technical tables enable complete ingestion traceability:

- `tech_ingestion_manifest` — file-level tracking  
- `tech_ingestion_log` — run-level metrics and status  

---

## 3. Architecture Summary

### 3.1 pl_ingest_generic — Unified Ingestion Pipeline

The **generic ingestion pipeline** handles all Bronze ingestions using parameters only.  
Its main execution flow:

1. GetMetadata (discover source files)  
2. `nb_prepare_incremental_list`  
3. ForEach (batchCount = 1, strictly sequential)  
   - Copy file to Landing  
   - Run `nb_load_generic_bronze`  
   - Copy file to Archive  
   - Update manifest entry  
4. Derive ingestion status (SUCCESS, PARTIAL, FAILED, NO_DATA)  
5. Log ingestion metrics (`nb_log_ingestion`)  

This design ensures determinism, idempotency, maintainability, and audit readiness.

---

### 3.2 pl_master_ingestion — Orchestration Layer

The orchestrator pipeline executes the generic pipeline sequentially across entities:

- FX  
- CUSTOMER  
- SECURITIES  
- FUNDAMENTALS  
- STOCK  
- ETF  
- PRICES  
- PRICES_SPLIT_ADJUSTED  
- CARD  
- USER  
- MCC  
- TRANSACTION  

This design provides:

- Clear operational separation  
- Consistent ingestion patterns  
- Per-entity monitoring (child pipeline runs)

---

### 3.3 OneLake Storage Organization

Landing and Archive follow a date-partitioned folder structure:
landing/<entity>/<yyyy-MM-dd>/<file>.csv
archive/<entity>/<yyyy-MM-dd>/<file>.csv

All Bronze Delta tables reside in the main Lakehouse (`lh_wm_core`):
bronze_fx_raw
bronze_customer_raw
bronze_stock_raw
bronze_etf_raw
bronze_card_raw
bronze_user_raw
bronze_mcc_raw
bronze_transaction_raw
bronze_securities_raw
bronze_fundamentals_raw
bronze_prices_raw
bronze_prices_split_adjusted_raw


---

## 4. Standardization Principles

### 4.1 Snake_case normalization
All incoming column names are standardized using a dedicated helper (`to_snake`), ensuring consistency across all datasets.

### 4.2 Modular transformation functions
The notebook `nb_load_generic_bronze` implements a modular transformation architecture:

- `transform_fx()`  
- `transform_customer()`  
- `load_stock()`  
- `load_etf()`  
- `load_cards()`  
- `load_users()`  
- `load_mcc()`  
- `load_transactions()`  
- `load_securities()`  
- `load_fundamentals()`  
- `load_prices()`  
- `load_prices_split_adjusted()`  

Each function:

- cleans and types fields  
- enforces a strict final `SELECT`  
- outputs a schema-aligned DataFrame  

### 4.3 Technical Columns
Added uniformly to every Bronze table:

- `source_file`  
- `ingestion_date`  
- `ingestion_ts`  
- `entity`

These ensure lineage, reproducibility, and regulatory compliance.

---

## 5. Ingestion Modes

### 5.1 FULL mode
Ingests all files from the source directory.  
Used for:

- first-time ingestion  
- historical backfills  
- reprocessing after upstream corrections  

### 5.2 INCR (Incremental) mode
Ingests only **new files** identified via the `tech_ingestion_manifest`.  
No watermark is used by design.  
This avoids timestamp drift issues and ensures full auditability.

---

## 6. Manifest and Logging

### 6.1 tech_ingestion_manifest (file-level tracking)

Tracks each file with the following attributes:

- entity  
- file_path  
- file_size  
- first_ingested_datetime  
- last_ingested_datetime  
- last_status  
- exec_date  
- ingestion_mode  
- total_source_files  
- total_candidate_files  
- processed_files  
- failed_files  

Key benefits:

- Enables incremental ingestion  
- Identifies problematic files  
- Supports audit & regulatory inspections  

---

### 6.2 tech_ingestion_log (run-level metrics)

Records ingestion metrics for each entity run:

- entity  
- exec_date  
- total_source_files  
- total_candidate_files  
- processed_files  
- failed_files  
- status (SUCCESS / PARTIAL / FAILED / NO_DATA)  
- log_timestamp  

Used for:

- ingestion dashboards  
- SLA monitoring  
- operational supervision  

---

## 7. Error Handling & Resilience

### Retry Policies
- Copy activities → 3 retries, 60 seconds  
- Notebooks → 2 retries, 120 seconds  

### Failure isolation
Errors are isolated **per file**, ensuring the pipeline can complete with:

- SUCCESS  
- PARTIAL  
- FAILED  
- NO_DATA  

### Schema enforcement
`mergeSchema` is intentionally **not used** in Bronze.  
Bronze schemas are aligned with notebook transformations — never inferred dynamically.

---

## 8. Key Benefits of the Bronze Framework

### 8.1 Governance-grade ingestion
- Full lineage  
- Reproducible, deterministic runs  
- Audit-friendly file-level manifest  
- Clean separation of ingestion, processing, archiving, and logging  

### 8.2 Strong engineering discipline
- Unified ingestion pipeline  
- Modular transformation architecture  
- Explicit and stable schemas  
- Resilient error-handling  

### 8.3 High extensibility
Adding a new entity requires only:

1. A new loader function in the notebook  
2. Adding entity parameters to `pl_ingest_generic`  
3. Creating a Bronze table definition  

No pipeline duplication is needed.

---

## 9. Conclusion

The Bronze Layer of the Wealth Management Analytics Platform is a **robust, extensible, and fully auditable ingestion foundation**. It uses Microsoft Fabric Pipelines, OneLake, and Spark notebooks to normalize and structure heterogeneous datasets following strict data governance principles.

The architecture is aligned with financial industry expectations and provides:

- reproducibility  
- compliance  
- schema stability  
- reliability  
- operational transparency  

It is now ready to support the development of the Silver and Gold layers, Power BI analytics, and advanced Wealth Management use cases.

---


