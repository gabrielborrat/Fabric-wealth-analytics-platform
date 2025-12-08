# Bronze Layer — Pipeline Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

This document describes the **ingestion pipeline architecture** powering the Bronze Layer of the Wealth Management Analytics Platform.  
It covers:

- the **generic ingestion pipeline** (`pl_ingest_generic`)  
- the **master orchestration pipeline** (`pl_master_ingestion`)  
- pipeline parameters and dynamic expressions  
- success/failure handling and counters  
- retry policies and resilience mechanisms  
- ingestion status rules  
- operational and governance considerations  

The pipelines are designed according to **banking-grade engineering and observability standards**, ensuring deterministic, auditable, and fully traceable ingestion flows.

---

## 2. Pipeline Architecture Overview

### 2.1 Multi-Entity, Unified Ingestion Framework

All Bronze ingestions — regardless of source or dataset (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, TRANSACTION, PRICES, SECURITIES, FUNDAMENTALS…) — follow a **single ingestion pattern** implemented through:

1. `pl_ingest_generic` — parameter-driven ingestion logic  
2. `nb_load_generic_bronze` — modular transformation notebook  
3. Landing → Bronze → Archive → Manifest updates  
4. Logging (run-level)  
5. Incremental ingestion based on manifest state  

This approach ensures:

- no duplication of pipelines  
- easy onboarding of new entities  
- full alignment of ingestion behaviors  
- maintainability and observability across environments  

---

## 3. pl_ingest_generic — Generic Ingestion Pipeline

The **core pipeline** used for every entity.

### 3.1 Pipeline Parameters

| Parameter | Description |
|----------|-------------|
| `entity` | The dataset identifier (FX, CUSTOMER, STOCK, etc.). Used for routing in the notebook and logging. |
| `p_SourcePath` | Location of source files (e.g., `FX-rates/`, `customers/`). |
| `p_LandingPath` | Landing area path in OneLake. |
| `p_ArchivePath` | Archive area path in OneLake. |
| `ingestion_mode` | FULL or INCR (incremental based on manifest). |
| `p_ExecDate` | Execution date (usually derived from pipeline trigger). |

These parameters ensure full configurability and avoid hardcoding paths.

---

### 3.2 High-Level Pipeline Flow

1. **GetMetadata**  
   - Lists all available files under `p_SourcePath`.  
   - Output: array of filenames.

2. **nb_prepare_incremental_list**  
   - Compares file list vs. manifest.  
   - Determines which files are **candidates** for ingestion (INCR mode).  
   - Writes or updates entries in `tech_ingestion_manifest`.

3. **Set_TotalSourceFiles / Set_TotalCandidateFiles**  
   - Stores counts in pipeline variables for logging purposes.

4. **ForEach (Sequential, batchCount = 1)**  
   For each candidate file:

   a. **Copy_ToLanding**  
      - Copies raw file from source to Landing.  
      - Implements retry policy.  

   b. **nb_load_generic_bronze**  
      - Reads file from Landing.  
      - Normalizes columns (snake_case).  
      - Applies entity-specific transformation logic.  
      - Adds technical metadata.  
      - Writes to the correct Bronze Delta table.  
      - Retry enabled (2 attempts).  

   c. **CopyToArchive**  
      - Moves file to archive location.  

   d. **Update_Manifest**  
      - Updates status, timestamps, processed/failed counts.  

   e. **Success/Failure Counter Updates**  
      - Increments `v_ProcessedFiles` or `v_FailedFiles` depending on activity outcome.  

5. **Derive_Status**  
   - Computes final run status (SUCCESS, PARTIAL, FAILED, NO_DATA).  

6. **nb_log_ingestion**  
   - Writes final ingestion metrics to `tech_ingestion_log`.

---

## 4. Dynamic Expressions

### 4.1 File iteration
@activity('GetMetadata').output.childItems

### 4.2 Landing path
@concat(p_LandingPath, p_ExecDate, '/', item().name)


### 4.3 Archive path
@concat(p_ArchivePath, p_ExecDate, '/', item().name)


These ensure date-based partitioning and consistent storage layout.

---

## 5. Success & Failure Handling

### 5.1 File-Level Failure Isolation

Every activity in the ForEach loop (Copy → Notebook → Archive) includes a **Failure** branch.

A single file failure does **not** fail the entire run.

This allows:
- PARTIAL ingestion states  
- graceful degradation  
- continuation of processing for other files  

### 5.2 Counter Variables

| Variable | Description |
|---------|-------------|
| `v_TotalSourceFiles` | Number of files found in the source. |
| `v_TotalCandidateFiles` | Number of files selected for ingestion (INCR mode). |
| `v_ProcessedFiles` | Files successfully processed. |
| `v_FailedFiles` | Files that failed ingestion. |
| `v_ProcessedFilesTmp` | Temporary accumulator inside ForEach success branch. |
| `v_FailedFilesTmp` | Temporary accumulator inside ForEach failure branch. |

The pipeline updates counters after each file using two-step operations:
- Increment temporary counter  
- Persist into main counter after execution  

This prevents race conditions.

---

## 6. Ingestion Status Logic

Final ingestion status is computed using the following rules:

### SUCCESS
- All candidate files processed successfully  
- `failed_files = 0` AND  
- `processed_files = candidate_files`

### NO_DATA
- No files found OR  
- No new files to ingest (INCR mode)

### FAILED
- No files processed successfully and at least one failed

### PARTIAL
- Some files processed, some failed

This classification is written to `tech_ingestion_log`.

---

## 7. Retry Mechanisms

To provide production-grade resilience:

### Copy Activities
- Retry count: **3**
- Retry interval: **60 seconds**

### Notebook Activities
- Retry count: **2**
- Retry interval: **120 seconds**

Benefits:
- Tolerates transient network issues  
- Stabilizes ingestion of large files  
- Avoids unnecessary run failures  

---

## 8. pl_master_ingestion — Master Orchestration Pipeline

This pipeline ensures deterministic ordering and isolation of ingestion runs.

### 8.1 Execution Sequence

Typically:

1. FX  
2. CUSTOMER  
3. SECURITIES  
4. FUNDAMENTALS  
5. STOCK  
6. ETF  
7. PRICES  
8. PRICES_SPLIT_ADJUSTED  
9. CARD  
10. USER  
11. MCC  
12. TRANSACTION  

### 8.2 Benefits

- Unified governance entry point  
- Clean observability (parent → child pipeline runs)  
- Clear operational procedures  
- Easier scheduling and dependency coordination  

### 8.3 Trigger Strategy
- Daily at market close or early morning  
- Event-based triggers optional for future enhancements  

---

## 9. Storage Lifecycle: Landing → Bronze → Archive

Files follow a deterministic lifecycle:

### Landing  
Temporary staging area for ingestion.

### Bronze  
Typed Delta table after transformation.

### Archive  
Immutable copy for traceability and reprocessing.  
File names and paths include execution date.

This structure aligns with financial audit recommendations.

---

## 10. Governance & Observability Features

### 10.1 Manifest (File-Level Lineage)
Captures:
- first and last ingestion timestamps  
- last processing status  
- execution context  
- record and file-level metrics  

Enables:
- incremental ingestion  
- error diagnosis  
- lineage reconstruction  

### 10.2 Run-Level Logging
Provides:
- SLAs  
- ingestion completeness  
- failure diagnostics  
- reporting for operational dashboards  

### 10.3 Deterministic Processing
Sequential ForEach ensures:
- predictable ordering  
- no concurrency side effects  
- reliable counter updates  

---

## 11. Extensibility Model

To onboard a new entity:

1. Add loader function in notebook  
2. Add entity parameters to `pl_ingest_generic`  
3. Create Bronze table  
4. Register entity in `pl_master_ingestion`  

No pipeline duplication is required.  
No notebook re-engineering is necessary beyond the transformation module.

---

## 12. Conclusion

The Bronze ingestion pipelines implement a **unified, resilient, auditable ingestion framework** fully aligned with banking data governance standards.

Key strengths:

- Fully parameterized ingestion logic  
- Strict schema enforcement  
- Rich observability (manifest + logs + counters)  
- Modular, reusable notebook architecture  
- Deterministic execution  
- Extensibility without duplication  

This framework forms the operational backbone of the Wealth Management Analytics Platform and enables reliable downstream Silver and Gold transformations, Data Warehouse modeling, and advanced Power BI reporting.

---

