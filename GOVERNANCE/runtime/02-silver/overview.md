# Silver Layer – Overview

## Purpose
The **Silver layer** represents the cleaned, validated, and enriched data layer of the Wealth Management Analytics platform on **Microsoft Fabric**.

It is designed to support:
- Data quality enforcement
- Deduplication and normalization
- Enrichment from multiple Bronze sources
- Downstream Gold layer consumption
- Auditable data lineage (Bronze → Silver)

## Design Principles (Banking-Grade)
- **Contract-first modeling**: schemas are explicit and enforced via Schema Registry
- **Idempotent execution**: FULL rebuilds are deterministic
- **Strict lineage**: Silver reads exclusively from Bronze
- **Fail-fast strategy**: quality checks stop the run and are logged
- **End-to-end traceability**: every record is linked to a `silver_run_id`

## Target Model (v1)

### Entities
- `silver_cards` – Cleaned and normalized card data
- `silver_fx` – Standardized FX rates
- `silver_mcc` – Enriched MCC codes
- `silver_transactions` – Validated and enriched transactions
  - Grain: 1 row per transaction
  - Partitioning: by transaction month
- `silver_users` – Deduplicated and enriched user data

## Governance & Audit Tables
- `silver_log_runs` – one row per Silver execution
- `silver_log_steps` – one row per entity step (append-only)
- `silver_ctl_entity` – entity-level control table

## Consumption
- Gold layer (downstream transformations)
- Direct analytics (when appropriate)
- Operational monitoring and audit reviews

