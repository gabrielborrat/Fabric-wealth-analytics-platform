# Naming Conventions

## Overview
This document defines naming conventions for all artifacts in the Fabric Wealth Management Analytics platform.

## Tables

### Lakehouse Tables
- **Bronze**: `bronze_<source_system>_<entity>` (e.g., `bronze_s3_fx`, `bronze_kaggle_transactions`)
- **Silver**: `silver_<entity>` (e.g., `silver_fx`, `silver_transactions`)
- **Gold**: `gold_<entity>` (e.g., `gold_fact_aum_daily`, `gold_dim_client`)

### Warehouse Tables
- **Dimensions**: `dim_<entity>` (e.g., `dim_client`, `dim_account`)
- **Facts**: `fact_<entity>_<granularity>` (e.g., `fact_aum_daily`, `fact_pnl_daily`)

## Pipelines
- Format: `pl_<purpose>_<entity>` (e.g., `pl_ingest_fx`, `pl_incremental_transactions`)

## Notebooks
- Format: `nb_<purpose>_<entity>` (e.g., `nb_load_fx_bronze`, `nb_silver_transactions`)

## Workspaces
- `wm-raw-ingestion`: Raw data ingestion workspace
- `wm-analytics-engineering`: Analytics and transformation workspace
- `wm-reporting-bi`: Reporting and BI workspace

## Files
- **Schemas**: `<entity>_schema_<layer>.json` (e.g., `fx_schema_bronze.json`)
- **Config**: `config_sample.json` (actual config should be `config.json` and excluded from git)

