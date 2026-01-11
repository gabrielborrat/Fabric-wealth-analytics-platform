# Fabric Wealth Management Analytics Platform

This repository contains the complete implementation of a Wealth Management Analytics solution built on Microsoft Fabric, implementing a **Medallion Architecture** (Bronze → Silver → Gold).

## Overview

This platform provides end-to-end analytics capabilities for wealth management, including:
- **Bronze Layer** : Unified, parameter-driven ingestion framework for raw data from multiple sources
- **Silver Layer** : Data cleaning, validation, and enrichment
- **Gold Layer** : Star schema data warehouse optimized for analytics
- **Power BI** : Direct Lake semantic models and dashboards (AUM/PnL, Risk Exposure)
- **Governance** : Schema Registry, RBAC, data classification policies

## Architecture

This project implements a **Medallion Architecture** pattern:
- 🔷 **Bronze** : Raw data ingestion and standardization
- 🔶 **Silver** : Cleaned and validated data
- 🟡 **Gold** : Analytical data warehouse (star schema)

For detailed architecture documentation, see [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Repository Structure

```
├── 01-BRONZE/              # Bronze Layer - Raw data ingestion
│   ├── notebooks/          # Transformation notebooks
│   ├── pipelines/          # Generic ingestion pipeline
│   └── docs/               # Bronze layer documentation
│
├── 02-SILVER/              # Silver Layer - Cleaned data
│   ├── notebooks/          # Cleaning and validation notebooks
│   ├── pipelines/          # Silver pipelines
│   └── docs/               # Silver layer documentation
│
├── 03-GOLD/                # Gold Layer - Star schema data warehouse
│   ├── notebooks/          # Dimension and fact table notebooks
│   ├── pipelines/          # Gold pipelines
│   └── docs/               # Gold layer documentation
│
├── ORCHESTRATION/          # Pipeline orchestration
│   ├── 01-bronze/          # Bronze orchestration (pl_master_ingestion)
│   ├── 02-silver/          # Silver orchestration
│   ├── 03-gold/            # Gold orchestration
│   └── silos/              # Business domain silos
│
├── POWERBI/                # Power BI artifacts
│   ├── semantic-model/     # Direct Lake semantic model
│   ├── reports/            # Power BI dashboards
│   └── dataset/            # Dataset configurations
│
├── GOVERNANCE/             # Governance and policies
│   ├── schema-registry/    # YAML schema contracts (01-bronze/02-silver/03-gold)
│   ├── data_classification_policy.md
│   ├── rbac_model.md
│   └── ...
│
├── SCREENSHOTS/            # Screenshots organized by layer
│   ├── 01-bronze/
│   ├── 02-silver/
│   ├── 03-gold/
│   ├── pipelines/
│   └── powerbi/
│
└── DOCS/                   # Global documentation
    ├── architecture/
    └── pipeline_overview.md
```

## Key Features

✅ **Unified Ingestion Framework** : Single parameter-driven pipeline for all Bronze entities  
✅ **Schema Registry Governance** : YAML-based schema contracts with compliance validation  
✅ **Manifest-based Incremental** : Efficient incremental ingestion using manifest tables  
✅ **Failure Isolation** : File-level error handling and retry mechanisms  
✅ **Star Schema** : Optimized dimensional model for analytics  
✅ **Direct Lake Integration** : Native Power BI connectivity  
✅ **Complete Audit Trail** : Manifest tables + Archive zone for full traceability  

## Documentation

- **[Architecture Overview](ARCHITECTURE.md)** : Complete architecture documentation
- **[Pipeline Overview](DOCS/pipeline_overview.md)** : Detailed pipeline documentation
- **[Bronze Layer Docs](01-BRONZE/docs/)** : Bronze layer specific documentation
- **[Structure Proposal](STRUCTURE_PROPOSAL.md)** : Repository structure rationale

## Getting Started

[Add getting started instructions here]

## License

[Add license information here]

