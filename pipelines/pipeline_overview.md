# Pipeline Overview

## Pipeline Orchestration

This document describes the Fabric pipelines used for data orchestration in the Wealth Management Analytics Platform.

---

## Bronze Layer Ingestion Pipelines

### Architecture Overview

The Bronze layer uses a **unified, parameter-driven ingestion framework** that eliminates pipeline duplication. All entities (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, PRICES, SECURITIES, FUNDAMENTALS, etc.) are ingested through a single generic pipeline configured with entity-specific parameters.

---

## pl_ingest_generic — Generic Ingestion Pipeline

The **core reusable pipeline** that handles ingestion for all entities.

### Pipeline Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `p_Entity` | string | "CARD" | Entity identifier (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, PRICES, SECURITIES, FUNDAMENTALS, PRICES_SPLIT_ADJUSTED) |
| `p_SourcePath` | string | "stock-market-datasets/etf/" | Source path in S3 bucket (e.g., "FX-rates-since2004-dataset/", "NYSE-dataset/prices/") |
| `p_LandingPath` | string | "landing/etf/" | Landing zone path in Lakehouse (temporary staging) |
| `p_ArchivePath` | string | "archive/etf/" | Archive zone path in Lakehouse (immutable storage) |
| `p_IngestionMode` | string | "INCR" | Ingestion mode: "FULL" or "INCR" (incremental based on manifest) |
| `p_WatermarkDays` | int | 2 | Number of days for watermark-based filtering (incremental mode) |

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
   - **Notebook ID**: `7990d5f2-994b-4f9e-b42b-dc7bceaadde2`
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
     - Bucket: `gabefirstbucket`
     - Path: `@p_SourcePath/@item().name`
   - **Sink**: Lakehouse Landing Zone (Binary format)
     - Lakehouse: `lh_wm_core` (Workspace ID: `300f0249-d03f-436c-97fc-5b5940cc3aa3`)
     - Path: `Files/@p_LandingPath/yyyy-MM-dd/@item().name`
     - Uses execution date from `pipeline().TriggerTime`
   - **Retry Policy**: 3 retries, 60 seconds interval
   - **Timeout**: 12 hours

3. **LoadBronzeNotebook_Generic** (TridentNotebook Activity)
   - **Notebook ID**: `83c720f0-1f02-4d5d-8152-92d2aa404d02`
   - **Parameters**:
     - `LandingPath`: Full path to landing file (`Files/@p_LandingPath/yyyy-MM-dd/`)
     - `Entity`: Entity identifier (`@p_Entity`)
     - `ExecDate`: Execution date (`yyyy-MM-dd`)
   - **Functionality**:
     - Reads raw file from Landing zone
     - Applies entity-specific transformation logic
     - Normalizes column names (snake_case)
     - Adds technical metadata columns (ingestion_timestamp, exec_date, etc.)
     - Enforces schema validation
     - Writes to Bronze Delta table: `bronze_<entity>_raw`
   - **Retry Policy**: 2 retries, 120 seconds interval
   - **Timeout**: 12 hours

4. **CopyToArchive_Generic** (Copy Activity)
   - **Source**: Lakehouse Landing Zone
     - Path: `Files/@p_LandingPath/yyyy-MM-dd/@item().name`
   - **Sink**: Lakehouse Archive Zone
     - Path: `Files/@p_ArchivePath/yyyy-MM-dd/@item().name`
   - Moves file to immutable archive for audit and reprocessing
   - **Retry Policy**: 3 retries, 60 seconds interval

5. **Success Path — Counter & Manifest Update**
   - **Inc_ProcessedTmp**: Increments temporary counter (`v_ProcessedFilesTmp = v_ProcessedFiles + 1`)
   - **Set_ProcessedFromTmp**: Persists counter (`v_ProcessedFiles = v_ProcessedFilesTmp`)
   - **Update_Manifest_Success** (TridentNotebook Activity)
     - **Notebook ID**: `f4f25906-c588-4870-8761-496b0f0a3c18`
     - Updates manifest table with status "SUCCESS"
     - Records: file_path, source_name, file_size, modified_datetime, exec_date, ingestion_mode, total_source_files, total_candidate_files

6. **Failure Path — Counter & Manifest Update**
   - **Inc_FailedTmp**: Increments temporary failure counter (`v_FailedFilesTmp = v_FailedFiles + 1`)
   - **Set_FailedFromTmp**: Persists counter (`v_FailedFiles = v_FailedFilesTmp`)
   - **Update_Manifest_Failed** (TridentNotebook Activity)
     - **Notebook ID**: `f4f25906-c588-4870-8761-496b0f0a3c18`
     - Updates manifest table with status "FAILED"
     - Records failure metadata for diagnostics

**Failure Isolation**: Each file is processed independently. A single file failure does **not** stop the entire pipeline run.

#### Phase 3: Final Status & Logging

1. **Derive_Status** (SetVariable Activity)
   - Computes final pipeline run status based on counters:
     - **SUCCESS**: `v_FailedFiles = 0` AND `v_ProcessedFiles = v_TotalFiles`
     - **NO_DATA**: `v_TotalFiles = 0` (no files found in source)
     - **FAILED**: `v_ProcessedFiles = 0` AND `v_FailedFiles > 0` (all files failed)
     - **PARTIAL**: Some files succeeded, some failed
   - Variable: `v_Status`

2. **WriteIngestionLog_Generic** (TridentNotebook Activity)
   - **Notebook ID**: `6484b065-de7a-485f-8196-649e8e0e153f`
   - Writes run-level metrics to `tech_ingestion_log` table
   - Records:
     - `exec_date`: Execution date
     - `entity`: Entity identifier
     - `total_files`: Total files in source
     - `total_candidate_files`: Files selected for processing
     - `processed_files`: Successfully processed count
     - `failed_files`: Failed count
     - `status`: Final status (SUCCESS, PARTIAL, FAILED, NO_DATA)
     - `ingestion_mode`: FULL or INCR

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

### Dynamic Expressions

**Landing Path**:
```
@concat(
    'Files/',
    pipeline().parameters.p_LandingPath,
    formatDateTime(pipeline().TriggerTime,'yyyy-MM-dd'),
    '/'
)
```

**Archive Path**:
```
@concat(
    pipeline().parameters.p_ArchivePath,
    formatDateTime(pipeline().TriggerTime,'yyyy-MM-dd'),
    '/'
)
```

**File Name**: `@item().name`

---

## pl_master_ingestion — Master Orchestration Pipeline

The **orchestration pipeline** that coordinates ingestion across all entities in a deterministic sequence.

### Purpose

- Provides a single entry point for Bronze layer ingestion
- Ensures deterministic execution order
- Enables unified monitoring and governance
- Simplifies scheduling and dependency management

### Execution Sequence

The pipeline invokes `pl_ingest_generic` sequentially for each entity:

1. **Invoke_Ingest_FX**
   - Entity: `FX`
   - Source: `FX-rates-since2004-dataset/`
   - Landing: `landing/fx/`
   - Archive: `archive/fx/`
   - Mode: Default (no explicit INCR parameter)

2. **Invoke_Ingest_CUST** (depends on FX success)
   - Entity: `CUSTOMER`
   - Source: `customer_churn/`
   - Landing: `landing/customer/`
   - Archive: `archive/customer/`
   - Mode: `INCR`, Watermark: 2 days

3. **Invoke_Ingest_FUNDAMENTALS** (depends on CUST success)
   - Entity: `FUNDAMENTALS`
   - Source: `NYSE-dataset/fundamentals/`
   - Landing: `landing/fundamentals/`
   - Archive: `archive/fundamentals/`
   - Mode: `INCR`, Watermark: 2 days

4. **Invoke_Ingest_SECURITIES** (depends on FUNDAMENTALS success)
   - Entity: `SECURITIES`
   - Source: `NYSE-dataset/securities/`
   - Landing: `landing/securities/`
   - Archive: `archive/securities/`
   - Mode: `INCR`, Watermark: 2 days

5. **Invoke_Ingest_PRICES** (depends on SECURITIES success)
   - Entity: `PRICES`
   - Source: `NYSE-dataset/prices/`
   - Landing: `landing/prices/`
   - Archive: `archive/prices/`
   - Mode: `INCR`, Watermark: 2 days

6. **Invoke_Ingest_PRICES_SPLIT_ADJUSTED** (depends on PRICES success)
   - Entity: `PRICES_SPLIT_ADJUSTED`
   - Source: `NYSE-dataset/prices-split/`
   - Landing: `landing/prices-split/`
   - Archive: `archive/prices-split/`
   - Mode: `INCR`, Watermark: 2 days

7. **Invoke_Ingest_USER** (depends on PRICES_SPLIT_ADJUSTED success)
   - Entity: `USER`
   - Source: `financial-transactions-dataset/users/`
   - Landing: `landing/user/`
   - Archive: `archive/user/`
   - Mode: `INCR`, Watermark: 2 days

8. **Invoke_Ingest_ETF** (depends on USER success)
   - Entity: `ETF`
   - Source: `stock-market-datasets/etf/`
   - Landing: `landing/etf/`
   - Archive: `archive/etf/`
   - Mode: `INCR`, Watermark: 2 days

9. **Invoke_Ingest_STOCK** (depends on ETF success)
   - Entity: `STOCK`
   - Source: `stock-market-datasets/stock/`
   - Landing: `landing/stock/`
   - Archive: `archive/stock/`
   - Mode: `INCR`, Watermark: 2 days

10. **Invoke_Ingest_CARD** (depends on STOCK success)
    - Entity: `CARD`
    - Source: `financial-transactions-dataset/cards/`
    - Landing: `landing/card/`
    - Archive: `archive/card/`
    - Mode: `INCR`, Watermark: 2 days

11. **Invoke_Ingest_MCC** (depends on CARD success)
    - Entity: `MCC`
    - Source: `financial-transactions-dataset/mcc/`
    - Landing: `landing/mcc/`
    - Archive: `archive/mcc/`
    - Mode: `INCR`, Watermark: 2 days

### Pipeline Configuration

- **Pipeline ID**: `c9c5153d-3cc9-4e6b-9367-06627f30eb09` (pl_ingest_generic)
- **Workspace ID**: `eb329c81-2277-4112-8f23-571b924dcd04`
- **Connection**: `80bdbe4a-70d4-49be-bad9-f7ff3e0be25b`
- **Wait on Completion**: `true` (synchronous execution)
- **Retry Policy**: 0 retries, 30 seconds interval, 12 hours timeout

### Dependency Chain

Each entity ingestion depends on the **success** of the previous entity. If any entity fails, subsequent entities are **not executed**.

This ensures:
- Data consistency across related entities
- Clear failure isolation
- Predictable execution order
- Easier troubleshooting (know exactly where pipeline stopped)

---

## Storage Lifecycle: Landing → Bronze → Archive

### Landing Zone
- **Purpose**: Temporary staging area for raw files
- **Location**: `Files/landing/<entity>/yyyy-MM-dd/`
- **Format**: Binary (original file format)
- **Lifecycle**: Files remain until successfully processed and archived

### Bronze Layer
- **Purpose**: Typed, validated Delta tables
- **Location**: `Tables/bronze_<entity>_raw`
- **Format**: Delta Lake (Parquet)
- **Schema**: Enforced with technical metadata columns
- **Lifecycle**: Permanent storage, append-only

### Archive Zone
- **Purpose**: Immutable audit trail and reprocessing capability
- **Location**: `Files/archive/<entity>/yyyy-MM-dd/`
- **Format**: Binary (original file format)
- **Lifecycle**: Permanent retention for compliance

---

## Governance & Observability

### Manifest Table (`tech_ingestion_manifest`)
- **Purpose**: File-level lineage and incremental ingestion tracking
- **Records**: File path, source name, size, modified datetime, ingestion status, execution context
- **Enables**: Incremental ingestion, error diagnosis, lineage reconstruction

### Ingestion Log Table (`tech_ingestion_log`)
- **Purpose**: Run-level metrics and SLA tracking
- **Records**: Execution date, entity, file counts, processed/failed counts, final status, ingestion mode
- **Enables**: Operational dashboards, SLA monitoring, failure diagnostics

---

## Pipeline Dependencies

1. **Bronze Ingestion** (pl_master_ingestion → pl_ingest_generic)
   - Runs first to populate raw data
   - All entities processed sequentially

2. **Silver Transformation**
   - Runs after Bronze ingestion completes
   - Transforms raw data into cleansed, business-ready format

3. **Gold Aggregation**
   - Runs after Silver transformations
   - Creates aggregated, analytical datasets

4. **Warehouse Load**
   - Runs after Gold aggregations
   - Loads data into Data Warehouse for reporting

---

## Schedule Recommendations

- **Daily**: 01:00 UTC - Bronze incremental ingestion (pl_master_ingestion)
- **Daily**: 03:00 UTC - Silver transformations
- **Daily**: 05:00 UTC - Gold aggregations
- **Daily**: 07:00 UTC - Warehouse refresh

---

## Extensibility

To onboard a new entity:

1. **Add entity-specific logic** in `nb_load_generic_bronze` notebook
2. **Create Bronze table**: `bronze_<entity>_raw` with appropriate schema
3. **Add invocation** in `pl_master_ingestion` with entity-specific parameters
4. **Configure paths**: Source, Landing, Archive paths in S3/Lakehouse

**No pipeline duplication required** — the generic pipeline handles all entities.

---

## Key Features

✅ **Unified Framework**: Single pipeline for all entities  
✅ **Parameter-Driven**: Fully configurable via parameters  
✅ **Incremental Ingestion**: Manifest-based change detection  
✅ **Failure Isolation**: Single file failures don't stop entire run  
✅ **Retry Mechanisms**: Resilient to transient failures  
✅ **Audit Trail**: Complete manifest and logging  
✅ **Deterministic Execution**: Sequential processing ensures consistency  
✅ **Extensible**: Easy onboarding of new entities  
