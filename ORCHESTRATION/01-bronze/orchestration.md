# Bronze Orchestration

## Orchestration Artifacts
- **Master Pipeline**: `pl_master_ingestion`
- **Generic Pipeline**: `pl_ingest_generic` (parameter-driven)
- **Transformation Notebook**: `nb_load_generic_bronze`
- **Supporting Notebooks**:
  - `nb_prepare_incremental_list`
  - `nb_log_ingestion`
  - `nb_update_manifest`
  - `nb_validate_bronze_schema_registry`

## Orchestration Philosophy
The Bronze layer uses a **unified, parameter-driven ingestion framework** where:
- The master pipeline orchestrates entity ingestion in a deterministic sequence
- The generic pipeline is parameterized and reusable for all entities
- File-level processing ensures deterministic execution and failure isolation
- Manifest-based incremental ingestion eliminates duplicate processing

## Pipeline Architecture

### Master Pipeline (`pl_master_ingestion`)
Orchestrates ingestion of all entities in a deterministic order, then executes schema validation.

### Generic Pipeline (`pl_ingest_generic`)
Reusable parameter-driven pipeline that handles ingestion for all entities.

## Generic Pipeline Parameters

| Parameter | Description |
|---------|-------------|
| `p_Entity` | Entity identifier (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, TRANSACTIONS, PRICES, SECURITIES, FUNDAMENTALS, PRICES_SPLIT_ADJUSTED) |
| `p_SourcePath` | Source path in S3 bucket (e.g., "FX-rates-since2004-dataset/", "NYSE-dataset/prices/") |
| `p_LandingPath` | Landing zone path in Lakehouse (temporary staging) |
| `p_ArchivePath` | Archive zone path in Lakehouse (immutable storage) |
| `p_IngestionMode` | Load strategy (`FULL`, `INCR`) - manifest-based incremental |
| `p_WatermarkDays` | Number of days for watermark (retained for backward compatibility, not used for INCR) |

## Execution Flow

### Master Pipeline Flow
1. Master pipeline (`pl_master_ingestion`) initializes execution context
2. For each entity (FX, CUSTOMER, FUNDAMENTALS, SECURITIES, PRICES, PRICES_SPLIT_ADJUSTED, USER, ETF, STOCK, CARD, MCC):
   - Invoke generic pipeline (`pl_ingest_generic`) with entity-specific parameters
   - Wait for completion (success or failure)
3. After all entity ingestions complete:
   - Execute schema registry validation (`nb_validate_bronze_schema_registry`)
   - Write validation results to `tech_schema_compliance`

### Generic Pipeline Flow
1. **File Discovery**: Get file list from source (S3)
2. **Candidate Selection**: `nb_prepare_incremental_list` compares files with manifest
   - INCR mode: Only new files (not in manifest)
   - FULL mode: All files (reprocess everything)
3. **Sequential File Processing** (ForEach loop):
   - For each candidate file:
     - Copy file to Landing zone
     - Execute `nb_load_generic_bronze` (transformation and load)
     - Copy file to Archive zone
     - Update manifest entry
4. **Run Logging**: `nb_log_ingestion` writes run-level metrics to `tech_ingestion_log`

## Key Rules
- The master pipeline is the **only component that defines the execution sequence**
- The generic pipeline is **stateless and reusable** across all entities
- File-level failure isolation: a single file failure does not stop the entire run
- Manifest-based incremental ingestion: no timestamp-based watermark
- Schema Registry validation runs **after** all entity ingestions complete

