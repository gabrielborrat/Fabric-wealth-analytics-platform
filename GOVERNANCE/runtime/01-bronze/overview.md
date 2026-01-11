# Bronze Layer – Overview

## Purpose
The **Bronze layer** represents the raw, standardized, and ingested data layer of the Wealth Management Analytics platform on **Microsoft Fabric**.

It is designed to support:
- Unified ingestion from multiple heterogeneous sources (S3, external systems)
- Data standardization and normalization
- Schema Registry governance and compliance validation
- Incremental ingestion based on manifest tracking
- Auditable file-level lineage (source → Bronze)
- Downstream Silver layer consumption

## Design Principles (Banking-Grade)
- **Contract-first modeling**: schemas are explicit and enforced via Schema Registry (YAML)
- **Idempotent execution**: FULL and INCR rebuilds are deterministic
- **Strict lineage**: Bronze reads exclusively from external sources
- **Fail-fast strategy**: schema validation and quality checks stop the run and are logged
- **End-to-end traceability**: every file is tracked in manifest with full audit trail

## Target Model (v1)

### Entities
- **Market Data**: 
  - `bronze_fx_raw` – FX rates
  - `bronze_stock_raw` – Stock data
  - `bronze_etf_raw` – ETF data
  - `bronze_prices_raw` – Market prices
  - `bronze_prices_split_adjusted_raw` – Split-adjusted prices
  - `bronze_securities_raw` – Securities information
  - `bronze_fundamentals_raw` – Fundamental data
- **Customer Data**:
  - `bronze_customer_raw` – Customer data
  - `bronze_user_raw` – User data
  - `bronze_card_raw` – Card data
  - `bronze_transaction_raw` – Transaction data
- **Reference Data**:
  - `bronze_mcc_raw` – MCC codes

All Bronze tables follow the pattern: `bronze_<entity>_raw`

## Governance & Audit Tables
- `tech_ingestion_manifest` – file-level lineage and incremental tracking (one row per file)
- `tech_ingestion_log` – run-level ingestion metrics (one row per execution)
- `tech_schema_compliance` – schema registry validation results (one row per entity per run)

## Storage Lifecycle
- **Landing Zone**: Temporary staging area for raw files
- **Bronze Tables**: Typed Delta tables with technical metadata
- **Archive Zone**: Immutable audit trail for reprocessing

## Consumption
- Silver layer (downstream transformations)
- Schema Registry validation and compliance monitoring
- Operational monitoring and audit reviews

