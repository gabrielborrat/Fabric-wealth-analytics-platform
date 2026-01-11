# Run IDs & Logging Model

## Run ID Governance (Option A)
The platform enforces **pipeline-driven run identity** with file-level manifest tracking.

### Pipeline Execution
- `bronze_run_id = @pipeline().RunId` (for pipeline orchestration)
- `exec_date = formatDateTime(pipeline().TriggerTime, 'yyyy-MM-dd')` (logical execution date)
- The same identifiers are propagated to:
  - `tech_ingestion_log`
  - `tech_ingestion_manifest`
  - `tech_schema_compliance`
  - all Bronze tables (via technical metadata columns)

### Manual Execution
- If no pipeline context exists, a run ID and exec_date may be generated
- This mode is for development or debugging only

## Logging Tables

### tech_ingestion_log
One row per Bronze ingestion execution (run-level).

Key columns:
- `exec_date` – Logical execution date (YYYY-MM-DD)
- `entity` – Entity identifier (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, TRANSACTION, PRICES, SECURITIES, FUNDAMENTALS, PRICES_SPLIT_ADJUSTED)
- `pipeline_name` – Pipeline that triggered the ingestion
- `layer` (`bronze`)
- `status` (`SUCCESS`, `PARTIAL`, `FAILED`, `NO_DATA`)
- `start_ts`, `end_ts`, `duration_ms`
- `total_files` – Total files discovered in source
- `total_candidate_files` – Files selected for processing (after manifest filtering)
- `processed_files` – Successfully processed files
- `failed_files` – Failed files count
- `ingestion_mode` – FULL or INCR
- `params_json` – Pipeline parameters
- `error_message`

### tech_ingestion_manifest
File-level lineage table, one row per file ever ingested (append-only).

Key columns:
- `entity` – Entity identifier
- `file_path` – Full source path or filename (unique per entity)
- `source_name` – Logical file name
- `file_size` – File size in bytes
- `first_ingested_datetime` – Timestamp when file was first processed
- `last_ingested_datetime` – Timestamp of most recent ingestion attempt
- `last_status` – SUCCESS, FAILED, SKIPPED, or PARTIAL
- `exec_date` – Logical run date for the ingestion attempt
- `ingestion_mode` – FULL or INCR
- `total_source_files` – Files discovered during that run
- `total_candidate_files` – Files selected for ingestion
- `processed_files` – Files successfully processed in that run
- `failed_files` – Files that failed in that run
- `log_timestamp` – System timestamp of manifest update

This table enables:
- **Incremental ingestion**: Only new files (not in manifest) are processed in INCR mode
- **Auditability**: Complete file-level lineage and reprocessing history
- **Error diagnosis**: Per-file failure tracking
- **Historical trace**: Authoritative record of all ingestion activity

### tech_schema_compliance
Schema registry validation results, one row per entity per validation run.

Key columns:
- `run_ts_utc` – Validation execution timestamp
- `entity` – Entity identifier
- `table_name` – Bronze table name (e.g., `bronze_fx_raw`)
- `compliance_status` – PASS or FAIL
- `missing_columns` – Columns in registry but not in table
- `extra_columns` – Columns in table but not in registry
- `type_mismatches` – Column type differences
- `order_mismatch` – Column order differences
- `error_message` – Detailed compliance errors

## Technical Metadata in Bronze Tables

All Bronze tables include technical metadata columns:
- `source_file` – Source file name
- `ingestion_date` – Date of ingestion (YYYY-MM-DD)
- `ingestion_ts` – Timestamp of ingestion
- `entity` – Entity identifier

These columns enable:
- Full traceability from record to source file
- Time-based filtering and partitioning
- Audit trail reconstruction

## Manifest-Based Incremental Ingestion

The manifest table (`tech_ingestion_manifest`) is the core mechanism for incremental ingestion:

1. **File Discovery**: All files in source path are identified
2. **Candidate Selection**: `nb_prepare_incremental_list` compares discovered files with manifest
   - If file **not present** → candidate for ingestion
   - If file **present** and `ingestion_mode = INCR` → skipped
   - If file **present** and `ingestion_mode = FULL` → reprocessed
3. **Manifest Update**: After processing, manifest is updated with:
   - First/last ingestion timestamps
   - Processing status
   - File metadata

## Audit Guarantees
- Full traceability from pipeline to file to record
- Deterministic replay (via manifest and archive)
- Clear separation between orchestration and computation
- Schema compliance validation logged and auditable
- File-level lineage preserved for regulatory compliance

