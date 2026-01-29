# Pipeline Overview

## Pipeline Orchestration

This document describes the Fabric pipelines used for data orchestration in the Wealth Management Analytics Platform, across **all layers**:

- **Bronze**: ingestion (S3 → Landing → Bronze tables + manifest + archive)
- **Silver**: transformations (Bronze → Silver) via dispatcher notebook
- **Gold**: dimensional model (Silver → Gold) via dispatcher notebook
- **DWH**: SQL Warehouse refresh (monthly E2E orchestration + job registry execution)

---

## Bronze Layer Ingestion Pipelines

### Architecture Overview

The Bronze layer uses a **unified, parameter-driven ingestion framework** that eliminates pipeline duplication. All entities (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, PRICES, SECURITIES, FUNDAMENTALS, etc.) are ingested through a single generic pipeline configured with entity-specific parameters.

In addition, the Bronze layer is governed by a **Schema Registry** (YAML contracts) and a **post-ingestion schema compliance validation** process that detects schema drift and enforces “frozen” Bronze contracts operationally.

---

## pl_bronze_ingest_generic — Generic Ingestion Pipeline

The **core reusable pipeline** that handles ingestion for all entities.

### Pipeline Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `p_Entity` | string | "FX" | Entity identifier (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, TRANSACTION, PRICES, SECURITIES, FUNDAMENTALS, PRICES_SPLIT_ADJUSTED) |
| `p_SourcePath` | string | "FX-rates-since2004-dataset/" | Source path in S3 bucket (example: `"customer_churn/"`, `"NYSE-dataset/prices/"`) |
| `p_LandingPath` | string | "landing/fx/" | Landing zone path in Lakehouse (temporary staging) |
| `p_ArchivePath` | string | "archive/fx/" | Archive zone path in Lakehouse (immutable storage) |
| `p_IngestionMode` | string | "INCR" | Ingestion mode: "FULL" or "INCR" (incremental based on manifest) |
| `p_WatermarkDays` | int | 2 | Number of days for watermark-based filtering (incremental mode) |

> Note: Incremental ingestion is **manifest-based** (new files only). `p_WatermarkDays` is retained for backward compatibility/documentation but is not the governing mechanism for INCR.

### Pipeline Flow — Detailed Steps

#### Phase 1: File Discovery & Candidate Selection

1. **GetFileList_Generic** (GetMetadata Activity)
   - Lists all files in the S3 source path (`p_SourcePath`)
   - Retrieves child items (file list) from Amazon S3
   - Output: Array of file metadata objects

2. **Set_TotalFiles** (SetVariable Activity)
   - Stores the total count of files found in source
   - Variable: `v_TotalFiles = length(GetFileList_Generic.output.childItems)`

3. **Prepare_Incremental_List** (TridentNotebook Activity)
   - **Notebook**: `nb_prepare_incremental_list`
   - Compares source file list against the ingestion manifest table
   - Performs left outer join to identify new/unprocessed files
   - Filters files based on `p_IngestionMode`:
     - **INCR**: Only files not already processed (based on manifest)
     - **FULL**: All files (reprocess everything)
   - Returns JSON array of candidate files with metadata (name, file_path)
   - Updates manifest table with new file entries

4. **Set_FilesToProcess** (SetVariable Activity)
   - Parses the JSON output from Prepare_Incremental_List
   - Variable: `v_FilesToProcess = json(Prepare_Incremental_List.output.result.exitValue)`

5. **Set_TotalCandidatesFiles** (SetVariable Activity)
   - Counts the number of candidate files to process
   - Variable: `v_TotalCandidateFiles = length(v_FilesToProcess)`

#### Phase 2: Sequential File Processing (ForEach Loop)

The pipeline processes files **sequentially** (`isSequential: true`) to ensure deterministic execution and avoid concurrency issues.

For each file in `v_FilesToProcess`:

1. **Get_File_Additional_Metadata** (GetMetadata Activity)
   - Retrieves file metadata: `lastModified` timestamp and `size` (bytes)
   - Used for manifest logging and audit trail

2. **Copy_ToLanding_Generic** (Copy Activity)
   - **Source**: Amazon S3 (Binary format)
   - **Sink**: Lakehouse Landing Zone (Binary format)
   - **Retry Policy**: 3 retries, 60 seconds interval
   - **Timeout**: 12 hours

3. **LoadBronzeNotebook_Generic** (TridentNotebook Activity)
   - **Notebook**: `nb_load_generic_bronze`
   - **Parameters**:
     - `LandingPath`: Full path to landing file (`Files/@p_LandingPath/yyyy-MM-dd/`)
     - `Entity`: Entity identifier (`@p_Entity`)
     - `ExecDate`: Execution date (`yyyy-MM-dd`)
   - **Functionality**:
     - Reads raw file from Landing zone
     - Applies entity-specific transformation logic
     - Normalizes column names (snake_case)
     - Adds technical metadata columns (`source_file`, `ingestion_date`, `ingestion_ts`, `entity`)
     - Enforces strict write behavior (no mergeSchema)
     - Writes to Bronze Delta table (append-only): `bronze_<entity>_raw`
   - **Retry Policy**: 2 retries, 120 seconds interval
   - **Timeout**: 12 hours

   > Note: Schema contract enforcement is primarily handled via **post-ingestion schema registry validation** (see `pl_master_ingestion` below). In-notebook validation can be added later as a hard enforcement phase if desired.

4. **CopyToArchive_Generic** (Copy Activity)
   - Moves file from Landing to immutable Archive for audit and reprocessing
   - **Retry Policy**: 3 retries, 60 seconds interval

5. **Success Path — Counter & Manifest Update**
   - Increments processed counters and updates `tech_ingestion_manifest` with status `SUCCESS`

6. **Failure Path — Counter & Manifest Update**
   - Increments failure counters and updates `tech_ingestion_manifest` with status `FAILED`

**Failure Isolation**: Each file is processed independently. A single file failure does **not** stop the entire pipeline run.

#### Phase 3: Final Status & Logging

1. **Derive_Status** (SetVariable Activity)
   - Computes final pipeline run status (SUCCESS / PARTIAL / FAILED / NO_DATA)
   - Variable: `v_Status`

2. **WriteIngestionLog_Generic** (TridentNotebook Activity)
   - **Notebook**: `nb_log_ingestion`
   - Writes run-level metrics to `tech_ingestion_log`

### Pipeline Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `v_TotalFiles` | Integer | 0 | Total files found in source |
| `v_TotalCandidateFiles` | Integer | 0 | Files selected for processing (after manifest filtering) |
| `v_ProcessedFiles` | Integer | 0 | Successfully processed files |
| `v_ProcessedFilesTmp` | Integer | 0 | Temporary counter (incremented in ForEach loop) |
| `v_FailedFiles` | Integer | 0 | Failed files count |
| `v_FailedFilesTmp` | Integer | 0 | Temporary failure counter |
| `v_FilesToProcess` | Array | [] | JSON array of candidate files to process |
| `v_Status` | String | "NO_DATA" | Final pipeline status (SUCCESS, PARTIAL, FAILED, NO_DATA) |

### Retry Policies

| Activity Type | Retry Count | Retry Interval | Timeout |
|---------------|-------------|----------------|---------|
| Copy Activities | 3 | 60 seconds | 12 hours |
| Notebook Activities | 2 | 120 seconds | 12 hours |
| GetMetadata Activities | 0 | 30 seconds | 12 hours |

---

## pl_master_ingestion (pl_bronze_master.json) — Master Orchestration Pipeline

The **orchestration pipeline** that coordinates ingestion across all entities in a deterministic sequence and runs centralized governance controls.

### Purpose

- Provides a single entry point for Bronze layer ingestion
- Ensures deterministic execution order
- Enables unified monitoring and governance
- Simplifies scheduling and dependency management
- Runs **post-ingestion schema compliance validation** to detect drift

### Execution Sequence

The pipeline invokes `pl_bronze_ingest_generic` sequentially for each entity, then executes schema validation:

1. **Invoke_Ingest_FX**
2. **Invoke_Ingest_CUSTOMER**
3. **Invoke_Ingest_FUNDAMENTALS**
4. **Invoke_Ingest_SECURITIES**
5. **Invoke_Ingest_PRICES**
6. **Invoke_Ingest_PRICES_SPLIT_ADJUSTED**
7. **Invoke_Ingest_USER**
8. **Invoke_Ingest_ETF**
9. **Invoke_Ingest_STOCK**
10. **Invoke_Ingest_CARD**
11. **Invoke_Ingest_MCC**
12. **ValidateSchemasRegistry** (TridentNotebook Activity)
   - **Notebook**: `nb_validate_bronze_schema_registry` (see governance/runtime docs)
   - **Purpose**:
     - Loads YAML-based Bronze Schema Registry contracts (one per entity)
     - Compares registry schema vs live Delta table schema (names, types, optional order)
     - Writes results to: `tech_schema_compliance`
   - **Output**:
     - Row-per-entity compliance status: PASS / FAIL (and diffs)
     - Time-stamped run audit trail for governance

> Governance stance: This validation step is **non-blocking** by default (observability-first). It provides drift detection and audit evidence without destabilizing ingestion.

### Dependency Chain

Each entity ingestion depends on the **success** of the previous entity. If any entity fails, subsequent entities are **not executed**.

Schema validation runs **after** the ingestion chain completes successfully (or can be configured to run also on partial completion depending on your operational preference).

---

## Storage Lifecycle: Landing → Bronze → Archive

### Landing Zone
- **Purpose**: Temporary staging area for raw files
- **Location**: `Files/landing/<entity>/yyyy-MM-dd/`
- **Lifecycle**: Files remain until successfully processed and archived

### Bronze Layer
- **Purpose**: Typed, standardized Delta tables (append-only)
- **Location**: `Tables/bronze_<entity>_raw`
- **Schema**: Frozen via Schema Registry + monitored via compliance notebook
- **Lifecycle**: Append-only, governed retention/compaction policies apply

### Archive Zone
- **Purpose**: Immutable audit trail and reprocessing capability
- **Location**: `Files/archive/<entity>/yyyy-MM-dd/`
- **Lifecycle**: Long retention for compliance

---

## Governance & Observability

### Manifest Table (`tech_ingestion_manifest`)
- **Purpose**: File-level lineage and incremental ingestion tracking
- **Enables**: Incremental ingestion, diagnostics, lineage reconstruction

### Ingestion Log Table (`tech_ingestion_log`)
- **Purpose**: Run-level metrics and SLA tracking
- **Enables**: Operational dashboards, SLA monitoring, failure diagnostics

### Schema Compliance Table (`tech_schema_compliance`) — NEW
- **Purpose**: Bronze contract enforcement via continuous drift detection
- **Written by**: `nb_validate_bronze_schema_registry` (executed from `pl_master_ingestion` in `01-BRONZE/pipelines/pl_bronze_master.json`)
- **Records** (typical):
  - `run_ts_utc`, `entity`, `table_name`
  - `compliance_status` (PASS/FAIL)
  - `missing_columns`, `extra_columns`, `type_mismatches`, `order_mismatch`
- **Enables**:
  - Continuous governance monitoring in Power BI
  - Evidence for “Bronze layer frozen” statements
  - Safe evolution via versioned registry updates

---

## Extensibility

To onboard a new entity:

1. Add entity logic in `nb_load_generic_bronze`
2. Create Bronze table `bronze_<entity>_raw` with correct schema
3. Add YAML contract to the Schema Registry (`GOVERNANCE/schema-registry/01-bronze/<entity>.yaml`)
4. Add invocation in `pl_master_ingestion` (inside `01-BRONZE/pipelines/pl_bronze_master.json`)
5. Run `pl_master_ingestion` and verify:
   - ingestion logs in `tech_ingestion_log`
   - file lineage in `tech_ingestion_manifest`
   - schema compliance result in `tech_schema_compliance` (PASS)

No pipeline duplication required.

---

## Key Features

✅ Unified Framework (single generic pipeline)  
✅ Parameter-driven ingestion  
✅ Manifest-based incremental processing  
✅ Failure isolation (file-level)  
✅ Retry mechanisms  
✅ Audit trail (manifest + archive)  
✅ Deterministic orchestration (sequential execution)  
✅ **Schema Registry governance (YAML contracts)**  
✅ **Post-ingestion schema compliance validation (nb_validate_bronze_schema_registry → tech_schema_compliance)**

---

## Silver Layer Pipelines

### Overview

Silver transformations are orchestrated through a single pipeline that delegates work to a **dispatcher notebook** (`nb_silver_load`). The dispatcher reads the entity control table and executes the appropriate `nb_silver_*` notebooks.

### pl_silver_load_generic

- **Pipeline**: `02-SILVER/pipelines/pl_silver_load_generic.json`
- **Execution unit**: Trident notebook `nb_silver_load`
- **Run ID**: `silver_run_id` is generated from pipeline context (`@pipeline().RunId`) and/or an optional provided reminder (`p_run_id`)

#### Pipeline Parameters (as implemented)

| Parameter | Type | Default | Description |
|---|---:|---|---|
| `p_entity_code` | string | `ALL` | Entity selector (`CARDS`, `FX`, `MCC`, `TRANSACTIONS`, `USERS`, `ALL`) |
| `p_load_mode` | string | `full` | Load strategy (`full`, `incr`) |
| `p_as_of_date` | string |  | Optional reference date |
| `p_run_id` | string |  | Optional external run id (if empty, pipeline generates one) |

For orchestration/contract details, see:
- `ORCHESTRATION/02-silver/orchestration.md`
- `ORCHESTRATION/02-silver/notebooks-contract.md`

---

## Gold Layer Pipelines

### Overview

Gold transformations are orchestrated through a single pipeline delegating to a **dispatcher notebook** (`nb_gold_load`). The dispatcher selects the entities to process and executes child notebooks (`nb_gold_dim_*`, `nb_gold_fact_*`).

### pl_gold_load_generic

- **Pipeline**: `03-GOLD/pipelines/pl_gold_load_generic.json`
- **Execution unit**: Trident notebook `nb_gold_load`
- **Run ID**: `p_gold_run_id` is set from `@pipeline().RunId`

#### Pipeline Parameters (as implemented)

| Parameter | Type | Default | Description |
|---|---:|---|---|
| `p_entity_code` | string | `dim_date` | Entity selector (example: `dim_mcc`, list, etc.) |
| `p_load_mode` | string | `FULL` | Load strategy (`FULL`) |
| `p_as_of_date` | string |  | Optional reference date |
| `p_environment` | string | `dev` | `dev` / `test` / `prod` |
| `p_triggered_by` | string | `manual` | `manual` / `schedule` |
| `p_pipeline_name` | string | `pl_gold_load_generic` | Pipeline name for logging |
| `p_gold_run_id` | string |  | Run id (pipeline-governed) |

For orchestration/contract details, see:
- `ORCHESTRATION/03-gold/orchestration.md`
- `ORCHESTRATION/03-gold/notebooks-contract.md`

---

## DWH Layer Pipelines (Data Warehouse)

### Overview

The DWH layer is executed through **Script activities** calling **T-SQL stored procedures** in the Fabric Data Warehouse (`wh_wm_analytics`).  
Execution is **job-registry-driven** using `dbo.wh_ctl_job` (group, order, criticality, required parameters).

### Group pipelines

Each group pipeline follows the same pattern:

- `GetJobList` reads enabled jobs for one `job_group` (ordered by `job_order`)
- `ForEachJobs` executes each job using a dynamic `EXEC <sp_schema>.<sp_name> ...`
- `is_critical = 1` failures stop the pipeline

Pipelines:

- `04-DWH/pipelines/pl_dwh_refresh_dimensions.json` (DIMS)
- `04-DWH/pipelines/pl_dwh_refresh_facts.json` (FACTS)
- `04-DWH/pipelines/pl_dwh_refresh_aggregates.json` (AGG)
- `04-DWH/pipelines/pl_dwh_refresh_controls.json` (CONTROLS)
- `04-DWH/pipelines/pl_dwh_publish.json` (PUBLISH)

### End-to-end orchestrator: pl_dwh_refresh_month_e2e

- **Pipeline**: `04-DWH/pipelines/pl_dwh_refresh_month_e2e.json`
- **Sequence**: DIMS → FACTS → AGG → CONTROLS → PUBLISH → Finalize_Run
- **Finalize**: `dbo.sp_pub_wh_run_refresh`

#### Pipeline Parameters (as implemented)

| Parameter | Type | Description |
|---|---|---|
| `p_TxnMonth` | string/date | Month scope for refresh/DQ/publish (typically month start) |
| `p_ExecDate` | string/date | Execution date used for logging |
| `p_RunId` | string | Optional external run id (otherwise `@pipeline().RunId`) |

For orchestration/contract details, see:
- `ORCHESTRATION/04-dwh/orchestration.md`
- `ORCHESTRATION/04-dwh/notebooks-contract.md`

