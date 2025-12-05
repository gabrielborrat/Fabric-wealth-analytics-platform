# Pipeline Overview

## Pipeline Orchestration

This document describes the Fabric pipelines used for data orchestration.

## Ingestion Pipelines

### pl_ingest_fx
- **Purpose**: Initial load of FX data from S3 to Bronze layer
- **Frequency**: One-time or on-demand
- **Notebook**: `nb_load_fx_bronze.ipynb`

### pl_ingest_transactions
- **Purpose**: Initial load of transactions data from Kaggle to Bronze layer
- **Frequency**: One-time or on-demand
- **Notebook**: `nb_load_transactions_bronze.ipynb`

## Incremental Pipelines

### pl_incremental_fx
- **Purpose**: Incremental ingestion of FX data
- **Frequency**: Daily
- **Notebook**: `nb_fx_incremental_from_s3.ipynb`
- **Dependencies**: Checks manifest for processed files

### pl_incremental_transactions
- **Purpose**: Incremental ingestion of transactions data
- **Frequency**: Daily
- **Notebook**: `nb_transactions_incremental_from_kaggle.ipynb`
- **Dependencies**: Checks manifest for processed files

## Pipeline Dependencies
1. Ingestion pipelines run first (Bronze layer)
2. Silver transformation pipelines run after ingestion
3. Gold aggregation pipelines run after Silver
4. Warehouse load runs after Gold

## Schedule
- **Daily**: 01:00 UTC - Incremental ingestion
- **Daily**: 03:00 UTC - Silver transformations
- **Daily**: 05:00 UTC - Gold aggregations
- **Daily**: 07:00 UTC - Warehouse refresh

