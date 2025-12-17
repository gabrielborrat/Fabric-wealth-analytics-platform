# Bronze Layer — Manifest & Logging Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

This document describes the **Manifest** and **Ingestion Logging** subsystems used in the Bronze Layer of the Wealth Management Analytics Platform.

These components ensure that the ingestion framework is:

- fully auditable  
- deterministic and reproducible  
- operationally observable  
- compliant with financial governance requirements  

Two core technical tables support this capability:

1. **`tech_ingestion_manifest`** — file-level lineage  
2. **`tech_ingestion_log`** — run-level ingestion metrics  

Together, they deliver enterprise-grade oversight over ingestion completeness, failures, incremental processing, and regulatory traceability.

---

# 2. tech_ingestion_manifest — File-Level Lineage

The **manifest** is the central mechanism enabling incremental ingestion, historical traceability, and file-level auditability.

It provides a persistent record for **every file ever seen**, including:

- when it was first ingested  
- whether it succeeded or failed  
- how many times it was processed  
- the ingestion mode used  
- the last known status  

This table is used both during ingestion (to filter candidates) and after ingestion (for monitoring and auditing).

---

## 2.1 Purpose of the Manifest

The manifest supports four core functions:

### 1. **Incremental Ingestion**
Only “new” files (not previously ingested) are selected when `ingestion_mode = INCR`.

### 2. **Auditability**
Regulators and internal auditors can trace:

- every file ingested  
- ingestion attempts  
- error states  
- reprocessing events  

### 3. **Error Diagnosis**
Failures are logged per file, enabling rapid operational troubleshooting.

### 4. **Historical Trace**
The manifest preserves a complete lineage log, forming the authoritative record of ingestion activity.

---

## 2.2 Manifest Schema Overview

`tech_ingestion_manifest` contains the following logical fields:

| Column | Description |
|--------|-------------|
| **entity** | Dataset identifier (FX, CUSTOMER, STOCK, etc.). |
| **file_path** | Full source path or filename. Unique per entity. |
| **source_name** | Logical file name extracted from metadata. |
| **file_size** | File size in bytes for validation and drift detection. |
| **first_ingested_datetime** | Timestamp when file was first processed. |
| **last_ingested_datetime** | Timestamp of the most recent ingestion attempt. |
| **last_status** | SUCCESS, FAILED, SKIPPED, or PARTIAL. |
| **exec_date** | Logical run date for the ingestion attempt. |
| **ingestion_mode** | FULL or INCR. |
| **total_source_files** | Files discovered during that run. |
| **total_candidate_files** | Files selected for ingestion (in INCR mode). |
| **processed_files** | Files successfully processed in that run. |
| **failed_files** | Files that failed in that run. |
| **log_timestamp** | System timestamp of manifest update. |

This schema is intentionally redundant to maximize observability and audit value.

---

## 2.3 Manifest Lifecycle

### **Step 1 — File Discovery**
During `GetMetadata`, all files under the source path are identified.

### **Step 2 — Candidate Selection**
`nb_prepare_incremental_list` compares discovered files with the manifest.

- If file **not present** → candidate for ingestion  
- If file **present but failed earlier** → candidate for retry  
- If file **present and succeeded** → skipped in INCR mode  

### **Step 3 — Manifest Write (Pre-Ingestion)**
A new row is created or an existing one updated with:

- ingestion_mode  
- exec_date  
- file_size  
- timestamps  

This creates a durable audit trail for every ingestion attempt.

### **Step 4 — Manifest Update (Post-Ingestion)**
After processing each file, the manifest is updated with:

- last_status  
- last_ingested_datetime  
- updated counters (processed/failed)  

### **Step 5 — Persist for downstream analytics**
Power BI dashboards leverage the manifest to display:

- ingestion completeness  
- error trends  
- historical ingestion patterns  
- data availability SLAs  

---

# 3. Ingestion Status Model

Each file and each ingestion run follows a clear status model.

### File-Level Status (Manifest)
- **SUCCESS** — File processed without error  
- **FAILED** — File encountered an error in pipeline or notebook  
- **SKIPPED** — Already ingested; ignored during INCR mode  
- **PARTIAL** — Reserved for multi-part files (not used but structurally available)

### Run-Level Status (Log)
- **SUCCESS** — All candidate files processed  
- **PARTIAL** — Some files processed, some failed  
- **FAILED** — No files processed successfully and at least one failed  
- **NO_DATA** — No candidate files available  

These statuses are essential for operational supervision.

---

# 4. tech_ingestion_log — Run-Level Metrics

Whereas the manifest tracks files, **the logging system tracks runs**.

Each run of `pl_ingest_generic` inserts exactly **one row** into `tech_ingestion_log`.

---

## 4.1 Log Schema Overview

| Column | Description |
|--------|-------------|
| **entity** | Dataset processed during the run. |
| **exec_date** | Logical ingestion date. |
| **total_source_files** | Files detected by GetMetadata. |
| **total_candidate_files** | Files selected for ingestion. |
| **processed_files** | Files processed successfully. |
| **failed_files** | Files that failed. |
| **status** | SUCCESS / PARTIAL / FAILED / NO_DATA. |
| **log_timestamp** | Timestamp of log record creation. |

This table is primarily used for **operational dashboards** and **SLA monitoring**.

---

## 4.2 Purpose of the Logging Subsystem

### 1. **Operational Monitoring**
Provides ingestion completeness and error ratios at a glance.

### 2. **Alerts & Early Warning**
Supports future integration with alert policies.

### 3. **SLA Measurement**
Allows teams to track ingestion availability and latency KPIs.

### 4. **Audit & Governance**
Maintains long-term run history for compliance purposes.

---

# 5. Interaction Between Manifest & Log

The two systems complement each other:

| Layer | Role |
|-------|------|
| **Manifest** | Tracks each *file*, controls incremental ingestion, stores detailed processing history. |
| **Log** | Tracks each *ingestion run*, aggregates metrics, supports dashboards. |

Together, they provide:

- complete traceability  
- accurate operational analytics  
- strong guarantees for data governance audits  

---

# 6. Incremental Ingestion Logic (INCR Mode)

The incremental ingestion implemented in `pl_ingest_generic` follows this deterministic logic:

1. Discover all files  
2. Filter files that **do not exist** in the manifest  
3. Include failed files for retry  
4. Exclude successful files  
5. Process candidates sequentially  
6. Update manifest file-by-file  
7. Write run-level metrics  

This ensures:

- no double ingestion  
- deterministic behavior  
- operational transparency  

Notably, **no timestamp-based watermark** is used.  
This is a deliberate design choice to avoid:

- inconsistent file timestamps  
- resync issues  
- time zone drift  
- race conditions inherent in streaming/watermark models  

---

# 7. Failure Handling & Resilience

The manifest and log systems enable sophisticated error handling:

### 7.1 File-Level Isolation
A single file failure does not end the run.

### 7.2 Run-Level Partial Success
Runs can end in **PARTIAL** if at least one file succeeded.

### 7.3 Automatic Retry
Failed files are reprocessed naturally in the next INCR run.

### 7.4 Transparent Operations
Operators can inspect:

- which files failed  
- how many times they were retried  
- when they last succeeded  
- which runs suffered partial failures  

---

# 8. Recommended Power BI Monitoring Dashboards

The manifest and log tables support several operational dashboards:

### Dashboard 1 — Daily Ingestion Status  
Visuals:
- Total files processed per entity  
- Daily SUCCESS / PARTIAL / FAILED / NO_DATA counts  

### Dashboard 2 — File-Level Audit Explorer  
Visuals:
- File history timeline  
- Failed file list  
- Reprocessing history  

### Dashboard 3 — SLA & Availability  
Visuals:
- Run duration  
- Data completeness  
- Trend over rolling 30 days  

These dashboards transform ingestion governance into an easily monitorable operational workflow.

---

# 9. Extensibility Guidelines

Extending ingestion to new datasets requires no modification to the manifest or log logic.

For each new entity:

1. Add Bronze transformation logic  
2. Register entity in the pipeline  
3. The manifest/log automatically incorporate the new dataset  

This design supports scale, agility, and long-term maintainability.

---

# 10. tech_schema_compliance — Schema Registry Governance

In addition to file-level lineage and run-level metrics, the Bronze layer is governed by a **Schema Registry** and a **post-ingestion schema compliance validation process**.

This governance layer ensures that all Bronze Delta tables remain aligned with their approved schema contracts over time.

---

## 10.1 Purpose of Schema Compliance

The schema compliance subsystem serves four key objectives:

1. **Contract Enforcement**
   - Each Bronze table has an explicit, versioned schema contract defined in YAML.
   - The contract defines column names, data types, order, and technical metadata.

2. **Schema Drift Detection**
   - Detects unexpected schema changes caused by:
     - source data changes
     - notebook logic errors
     - accidental schema evolution
   - Drift is detected *after ingestion* to avoid destabilizing pipelines.

3. **Audit & Evidence**
   - Provides time-stamped evidence that Bronze schemas remain frozen and controlled.
   - Supports internal and regulatory audits.

4. **Safe Evolution**
   - Enables controlled schema changes through explicit registry updates and versioning.

---

## 10.2 tech_schema_compliance Table

Schema validation results are persisted in the `tech_schema_compliance` table.

Each execution of the schema validation process inserts **one row per entity**, capturing the compliance status at that point in time.

### Logical schema

| Column | Description |
|------|-------------|
| **run_ts_utc** | Timestamp of the schema validation run. |
| **layer** | Data layer validated (BRONZE). |
| **entity** | Entity name (FX, CUSTOMER, PRICES, etc.). |
| **table_name** | Physical Delta table name. |
| **registry_path** | YAML contract file used for validation. |
| **registry_status** | Declared registry status (e.g. APPROVED). |
| **compliance_status** | PASS or FAIL. |
| **missing_columns** | Columns expected but not present. |
| **extra_columns** | Columns present but not in registry. |
| **type_mismatches** | Columns with data type differences. |
| **order_mismatch** | Indicates column order deviation. |
| **order_details** | Expected vs actual order (if applicable). |

---

## 10.3 Validation Process

Schema compliance is validated by the notebook:

- **`nb_validate_bronze_schema_registry`**

This notebook:
1. Loads all YAML contracts from the Schema Registry
2. Reads live Delta table schemas from the Lakehouse
3. Compares expected vs actual schemas
4. Writes detailed compliance results to `tech_schema_compliance`

The notebook is executed **from the master orchestration pipeline** after Bronze ingestion completes.

---

## 10.4 Governance Model

- Schema validation is **non-blocking by design**
- Ingestion pipelines do not fail on schema drift
- Drift is surfaced through monitoring and dashboards

This approach ensures:
- ingestion stability
- early detection of governance issues
- progressive hardening toward stricter enforcement if required

---

## 10.5 Relationship with Manifest & Log

| Control Plane | Scope | Purpose |
|--------------|-------|---------|
| **tech_ingestion_manifest** | File-level | Lineage, incrementality, retries |
| **tech_ingestion_log** | Run-level | Metrics, SLA, operational status |
| **tech_schema_compliance** | Schema-level | Contract compliance, drift detection |

Together, these three layers provide **complete Bronze governance coverage**.

# 11. Conclusion

The Manifest and Logging framework provides a **robust, auditable, and transparent ingestion governance layer** for the Wealth Management Analytics Platform.

Key strengths include:

- deterministic incremental ingestion  
- fine-grained file-level lineage  
- run-level operational observability  
- resilience through isolated failure handling  
- audit readiness for regulatory environments  

This subsystem is a cornerstone of the platform’s **data governance posture** and ensures that all downstream Silver, Gold, and Power BI layers are built upon **trustworthy, traceable, and complete datasets**.

---

