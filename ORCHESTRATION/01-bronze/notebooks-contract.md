# Notebook Execution Contract – Bronze Layer

## Generic Transformation Notebook (`nb_load_generic_bronze`)

Responsibilities:
- Read raw file from Landing zone
- Apply entity-specific transformation logic
- Normalize column names (snake_case)
- Add technical metadata columns (`source_file`, `ingestion_date`, `ingestion_ts`, `entity`)
- Enforce strict write behavior (no mergeSchema)
- Write to Bronze Delta table (append-only): `bronze_<entity>_raw`

### Parameters
- `LandingPath`: Full path to landing file (`Files/<p_LandingPath>/<yyyy-MM-dd>/`)
- `Entity`: Entity identifier (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, TRANSACTIONS, PRICES, SECURITIES, FUNDAMENTALS, PRICES_SPLIT_ADJUSTED)
- `ExecDate`: Execution date (`yyyy-MM-dd`)

### Mandatory Steps
1. Read raw file from Landing zone
2. Apply entity-specific transformation logic:
   - Column normalization (snake_case)
   - Data type casting (strict typing)
   - Value standardization
3. Add technical metadata columns:
   - `source_file`: Source file name
   - `ingestion_date`: Execution date (DATE)
   - `ingestion_ts`: Ingestion timestamp (TIMESTAMP)
   - `entity`: Entity identifier (STRING)
4. Write to Bronze Delta table:
   - Table name: `bronze_<entity>_raw`
   - Append-only mode
   - Strict schema enforcement (no mergeSchema)
   - Partition by `ingestion_date` if applicable

### Key Rules
- **No schema drift allowed**: Table schema must match Schema Registry contract
- **Idempotent execution**: Same file can be reprocessed (FULL mode) without duplicates
- **Strict typing**: All columns must be explicitly typed
- **Fail-fast**: Schema mismatches stop execution

## Supporting Notebooks

### `nb_prepare_incremental_list`
Prepares the list of candidate files for ingestion.

Responsibilities:
- Compare source file list with `tech_ingestion_manifest`
- Identify new/unprocessed files (INCR mode) or all files (FULL mode)
- Update manifest table with new file entries
- Return JSON array of candidate files

Input:
- `entity`: Entity identifier
- `ingestion_mode`: FULL or INCR
- `source_path`: Source path in S3
- `all_files_json`: JSON array of all files from source

Output:
- JSON array of candidate files with metadata (name, file_path)

### `nb_log_ingestion`
Logs run-level ingestion metrics.

Responsibilities:
- Write run-level metrics to `tech_ingestion_log`
- Include entity, status, file counts, timing information

Input:
- `exec_date`: Execution date
- `entity`: Entity identifier
- `total_files`: Total files discovered
- `total_candidate_files`: Files selected for processing
- `processed_files`: Successfully processed files
- `failed_files`: Failed files count
- `status`: Final status (SUCCESS, PARTIAL, FAILED, NO_DATA)
- `ingestion_mode`: FULL or INCR

### `nb_update_manifest`
Updates the manifest table with file processing status.

Responsibilities:
- Update `tech_ingestion_manifest` with file processing status
- Record success or failure status per file
- Store file metadata (size, timestamps)

Input:
- `status`: SUCCESS or FAILED
- `entity`: Entity identifier
- `file_path`: Source file path
- `source_name`: File name
- `file_size`: File size in bytes
- `modified_datetime`: File modification timestamp
- `exec_date`: Execution date
- `ingestion_mode`: FULL or INCR
- `total_source_files`: Total files in source
- `total_candidates_files`: Files selected for processing

### `nb_validate_bronze_schema_registry`
Validates Bronze tables against Schema Registry contracts.

Responsibilities:
- Load YAML-based Schema Registry contracts
- Compare registry schema vs live Delta table schema
- Detect schema drift (missing columns, extra columns, type mismatches)
- Write validation results to `tech_schema_compliance`

Key rule:
This notebook runs **after** all entity ingestions complete (from master pipeline).

## Key Principles
- **Unified framework**: Single generic pipeline and notebook for all entities
- **Parameter-driven**: Entity-specific configuration via parameters
- **Manifest-based incremental**: No timestamp-based watermark
- **File-level isolation**: Single file failures do not stop the run
- **Schema Registry governance**: Contracts enforced via post-ingestion validation
- **Audit trail**: Complete file-level lineage in manifest

