# Fabric Wealth Management Analytics Platform

This repository contains the complete implementation of a Wealth Management Analytics solution built on Microsoft Fabric, implementing a **Medallion Architecture** (Bronze → Silver → Gold) extended with a **SQL Data Warehouse layer** and **Power BI reporting layer**.

## Overview

This platform provides end-to-end analytics capabilities for wealth management, including:

- **🔷 Bronze Layer** : Unified, parameter-driven ingestion framework for raw data from multiple sources
- **🔶 Silver Layer** : Data cleaning, validation, and enrichment
- **🟡 Gold Layer** : Star schema data warehouse optimized for analytics (Direct Lake)
- **📦 DWH Layer** : SQL-native Data Warehouse with job-driven orchestration, data quality controls, and publish gates
- **📊 Power BI Layer** : Direct Lake semantic models and dashboards (Business & Operations)
- **🛡️ Governance** : Schema Registry, RBAC, runtime governance, workspace strategy

## Architecture

This project implements an **extended Medallion Architecture** pattern:

- **🔷 Bronze** : Raw data ingestion and standardization
  - Manifest-based incremental ingestion
  - Schema Registry governance (YAML contracts)
  - File-level auditability and archive zone
  
- **🔶 Silver** : Cleaned and validated data
  - Deduplication and business rule enforcement
  - Enhanced data typing and precision
  - Strategic partitioning for performance
  
- **🟡 Gold** : Analytical data warehouse (star schema)
  - Dimensions: `dim_card`, `dim_date`, `dim_mcc`, `dim_user`
  - Facts: `fact_transactions`
  - Optimized for Direct Lake Power BI connectivity
  
- **📦 DWH** : SQL Data Warehouse (job-driven orchestration)
  - Job registry-driven execution (`dbo.wh_ctl_job`)
  - Monthly refresh orchestration
  - Data quality controls and reconciliation
  - Publish gates for downstream consumption
  
- **📊 Power BI** : Business intelligence and reporting
  - Direct Lake semantic models (Business & Operations)
  - Interactive dashboards for analytics and observability
  - Certified DAX measures for governance

For detailed architecture documentation, see:
- **[Architecture Overview](DOCS/architecture_overview.md)** : High-level entry point and navigation guide
- **[Detailed Architecture](DOCS/architecture/ARCHITECTURE.md)** : Complete architecture documentation
- **[Pipeline Overview](DOCS/pipeline_overview.md)** : Detailed pipeline documentation

## Repository Structure

```
├── 01-BRONZE/              # Bronze Layer - Raw data ingestion
│   ├── notebooks/          # Transformation notebooks
│   │   ├── nb_load_generic_bronze.ipynb
│   │   ├── nb_prepare_incremental_list.ipynb
│   │   ├── nb_update_manifest.ipynb
│   │   ├── nb_log_ingestion.ipynb
│   │   └── ...
│   ├── pipelines/          # Generic ingestion pipeline
│   │   ├── pl_bronze_ingest_generic.json
│   │   └── pl_bronze_master.json
│   └── docs/               # Bronze layer documentation
│       ├── bronze-layer-overview.md
│       ├── bronze-layer-pipeline.md
│       ├── bronze-notebook-overview.md
│       ├── bronze-schema-data-dictionary.md
│       └── bronze-manifest-logging.md
│
├── 02-SILVER/              # Silver Layer - Cleaned data
│   ├── notebooks/          # Cleaning and validation notebooks
│   │   ├── nb_silver_load.ipynb (dispatcher)
│   │   ├── nb_silver_cards.ipynb
│   │   ├── nb_silver_fx.ipynb
│   │   ├── nb_silver_mcc.ipynb
│   │   ├── nb_silver_transactions.ipynb
│   │   ├── nb_silver_users.ipynb
│   │   └── ...
│   ├── pipelines/          # Silver pipelines
│   │   ├── pl_silver_load_generic.json
│   │   └── pl_silver_master.json
│   └── docs/               # Silver layer documentation
│       ├── silver-layer-overview.md
│       ├── silver-layer-pipeline.md
│       ├── silver-notebook-overview.md
│       └── silver-schema-data-dictionary.md
│
├── 03-GOLD/                # Gold Layer - Star schema data warehouse
│   ├── notebooks/          # Dimension and fact table notebooks
│   │   ├── nb_gold_load.ipynb (dispatcher)
│   │   ├── nb_gold_dim_card.ipynb
│   │   ├── nb_gold_dim_date.ipynb
│   │   ├── nb_gold_dim_mcc.ipynb
│   │   ├── nb_gold_dim_user.ipynb
│   │   ├── nb_gold_fact_transactions.ipynb
│   │   └── ...
│   ├── pipelines/          # Gold pipelines
│   │   ├── pl_gold_load_generic.json
│   │   └── pl_gold_master.json
│   └── docs/               # Gold layer documentation
│       ├── gold-layer-overview.md
│       ├── gold-layer-pipeline.md
│       ├── gold-notebook-overview.md
│       └── gold-schema-data-dictionary.md
│
├── 04-DWH/                 # DWH Layer - SQL Data Warehouse
│   ├── dwh-model-dll.sql   # Table DDL (dimensions, facts, control tables)
│   ├── dwh-sp-ddl.sql      # Stored procedures (refresh, DQ, publish)
│   ├── pipelines/          # DWH orchestration pipelines
│   │   ├── pl_dwh_refresh_month_e2e.json (orchestrator)
│   │   ├── pl_dwh_refresh_dimensions.json
│   │   ├── pl_dwh_refresh_facts.json
│   │   ├── pl_dwh_refresh_aggregates.json
│   │   ├── pl_dwh_refresh_controls.json
│   │   └── pl_dwh_publish.json
│   └── docs/               # DWH layer documentation
│       ├── dwh-layer-overview.md
│       ├── dwh-layer-pipeline.md
│       ├── dwh-procedures-overview.md
│       └── dwh-schema-data-dictionary.md
│
├── 05-POWERBI/             # Power BI Layer - BI and reporting
│   ├── semantic-model/     # Direct Lake semantic models
│   │   ├── business/       # Business semantic model
│   │   │   ├── sm-business-measures_catalog.md
│   │   │   ├── sm-business-model.png
│   │   │   └── sm-business-relationships.png
│   │   └── operations/     # Operations semantic model
│   │       ├── sm-operations-measures_catalog.md
│   │       ├── sm-operations-model.png
│   │       └── sm-operations-relationships.png
│   ├── reports/            # Power BI dashboards
│   │   ├── business/       # Business dashboard documentation
│   │   │   └── dashboard_business.md
│   │   └── operations/     # Operations dashboard documentation
│   │       └── dashboard-operarions.md
│   ├── docs/               # Power BI layer documentation
│   │   └── powerbi-layer-overview.md
│   └── wm-reporting-bi.png
│
├── ORCHESTRATION/          # Pipeline orchestration documentation
│   ├── README.md           # Orchestration overview
│   ├── 01-bronze/          # Bronze orchestration
│   │   ├── orchestration.md
│   │   └── notebooks-contract.md
│   ├── 02-silver/          # Silver orchestration
│   │   ├── orchestration.md
│   │   └── notebooks-contract.md
│   ├── 03-gold/            # Gold orchestration
│   │   ├── orchestration.md
│   │   └── notebooks-contract.md
│   └── 04-dwh/             # DWH orchestration
│       ├── orchestration.md
│       └── notebooks-contract.md
│
├── GOVERNANCE/             # Governance and policies
│   ├── README.md           # Governance overview
│   ├── naming_conventions.md
│   ├── rbac_model.md
│   ├── workspace_strategy.md
│   ├── schema-registry/    # YAML schema contracts
│   │   ├── 01-bronze/      # Bronze schema contracts
│   │   │   ├── _registry_index.yaml
│   │   │   ├── _template.yaml
│   │   │   ├── fx.yaml
│   │   │   ├── transaction.yaml
│   │   │   └── ...
│   │   └── 02-silver/      # Silver schema contracts
│   │       ├── silver_fx.yaml
│   │       ├── silver_transactions.yaml
│   │       └── ...
│   └── runtime/            # Runtime governance
│       ├── 01-bronze/      # Bronze runtime governance
│       │   ├── overview.md
│       │   ├── run_ids_and_logging.md
│       │   └── ...
│       ├── 02-silver/      # Silver runtime governance
│       │   ├── overview.md
│       │   ├── run_ids_and_logging.md
│       │   └── ...
│       └── 03-gold/        # Gold runtime governance
│           ├── overview.md
│           ├── run_ids_and_logging.md
│           └── ...
│
├── DOCS/                   # Global documentation
│   ├── architecture_overview.md  # High-level entry point
│   ├── pipeline_overview.md       # Detailed pipeline documentation
│   └── architecture/              # Architecture documentation
│       ├── ARCHITECTURE.md
│       ├── medailion.jpg
│       └── workspace_vs_objects.png
│
└── SCREENSHOTS/            # Screenshots organized by layer
    ├── 01-bronze/
    ├── 02-silver/
    ├── 03-gold/
    ├── 04-dwh/
    ├── 05-powerBI/
    └── pipelines/
```

## Key Features

### Data Ingestion & Transformation
✅ **Unified Ingestion Framework** : Single parameter-driven pipeline for all Bronze entities  
✅ **Schema Registry Governance** : YAML-based schema contracts with compliance validation  
✅ **Manifest-based Incremental** : Efficient incremental ingestion using manifest tables  
✅ **Failure Isolation** : File-level error handling and retry mechanisms  
✅ **Complete Audit Trail** : Manifest tables + Archive zone for full traceability  

### Data Quality & Governance
✅ **Multi-layer Data Quality** : DQ checks at Silver, Gold, and DWH layers  
✅ **Anomaly Tracking** : Row-level and aggregated anomaly logging (Gold layer)  
✅ **Schema Compliance Validation** : Post-ingestion schema drift detection (Bronze layer)  
✅ **Runtime Governance** : Run IDs, execution logging, and observability across all layers  

### Analytics & Reporting
✅ **Star Schema** : Optimized dimensional model for analytics (Gold layer)  
✅ **Direct Lake Integration** : Native Power BI connectivity without data duplication  
✅ **Job-driven DWH** : SQL-native warehouse with registry-driven orchestration  
✅ **Certified Business Metrics** : Centralized DAX measures for governance  
✅ **Operational Observability** : Dedicated OPS dashboard for platform monitoring  

### Orchestration & Operations
✅ **Pipeline-driven Run IDs** : Consistent execution identity across layers  
✅ **Deterministic Execution** : Sequential orchestration with dependency management  
✅ **Publish Gates** : Data readiness checks before downstream consumption  
✅ **Comprehensive Logging** : Run-level and step-level execution logs  

## Documentation

### Quick Start
- **[Architecture Overview](DOCS/architecture_overview.md)** : High-level entry point and navigation guide
- **[Pipeline Overview](DOCS/pipeline_overview.md)** : Detailed pipeline documentation across all layers

### Layer-Specific Documentation

#### Bronze Layer
- **[Bronze Overview](01-BRONZE/docs/bronze-layer-overview.md)** : Bronze layer introduction and objectives
- **[Bronze Pipeline](01-BRONZE/docs/bronze-layer-pipeline.md)** : Pipeline architecture and flow
- **[Bronze Notebooks](01-BRONZE/docs/bronze-notebook-overview.md)** : Notebook implementation details
- **[Bronze Data Dictionary](01-BRONZE/docs/bronze-schema-data-dictionary.md)** : Schema and data dictionary
- **[Bronze Manifest & Logging](01-BRONZE/docs/bronze-manifest-logging.md)** : Audit trail and logging

#### Silver Layer
- **[Silver Overview](02-SILVER/docs/silver-layer-overview.md)** : Silver layer introduction and objectives
- **[Silver Pipeline](02-SILVER/docs/silver-layer-pipeline.md)** : Pipeline architecture and flow
- **[Silver Notebooks](02-SILVER/docs/silver-notebook-overview.md)** : Notebook implementation details
- **[Silver Data Dictionary](02-SILVER/docs/silver-schema-data-dictionary.md)** : Schema and data dictionary

#### Gold Layer
- **[Gold Overview](03-GOLD/docs/gold-layer-overview.md)** : Gold layer introduction and objectives
- **[Gold Pipeline](03-GOLD/docs/gold-layer-pipeline.md)** : Pipeline architecture and flow
- **[Gold Notebooks](03-GOLD/docs/gold-notebook-overview.md)** : Notebook implementation details
- **[Gold Data Dictionary](03-GOLD/docs/gold-schema-data-dictionary.md)** : Schema and data dictionary

#### DWH Layer
- **[DWH Overview](04-DWH/docs/dwh-layer-overview.md)** : DWH layer introduction and objectives
- **[DWH Pipeline](04-DWH/docs/dwh-layer-pipeline.md)** : Pipeline architecture and job-driven execution
- **[DWH Procedures](04-DWH/docs/dwh-procedures-overview.md)** : Stored procedures documentation
- **[DWH Data Dictionary](04-DWH/docs/dwh-schema-data-dictionary.md)** : Warehouse schema and data dictionary

#### Power BI Layer
- **[Power BI Overview](05-POWERBI/docs/powerbi-layer-overview.md)** : Power BI layer introduction and objectives
- **[Business Dashboard](05-POWERBI/reports/business/dashboard_business.md)** : Business dashboard documentation
- **[Operations Dashboard](05-POWERBI/reports/operations/dashboard-operarions.md)** : Operations dashboard documentation
- **[Business Measures Catalog](05-POWERBI/semantic-model/business/sm-business-measures_catalog.md)** : DAX measures catalog
- **[Operations Measures Catalog](05-POWERBI/semantic-model/operations/sm-operations-measures_catalog.md)** : DAX measures catalog

### Orchestration Documentation
- **[Orchestration Overview](ORCHESTRATION/README.md)** : Orchestration overview by layer
- **Layer-specific orchestration** : See `ORCHESTRATION/01-bronze/`, `ORCHESTRATION/02-silver/`, `ORCHESTRATION/03-gold/`, `ORCHESTRATION/04-dwh/`

### Governance Documentation
- **[Governance Overview](GOVERNANCE/README.md)** : Governance overview and organization
- **[Naming Conventions](GOVERNANCE/naming_conventions.md)** : Naming standards across the platform
- **[RBAC Model](GOVERNANCE/rbac_model.md)** : Role-Based Access Control model
- **[Workspace Strategy](GOVERNANCE/workspace_strategy.md)** : Workspace organization strategy
- **Schema Registry** : See `GOVERNANCE/schema-registry/01-bronze/` and `GOVERNANCE/schema-registry/02-silver/`
- **Runtime Governance** : See `GOVERNANCE/runtime/01-bronze/`, `GOVERNANCE/runtime/02-silver/`, `GOVERNANCE/runtime/03-gold/`

### Architecture Documentation
- **[Detailed Architecture](DOCS/architecture/ARCHITECTURE.md)** : Complete architecture documentation
- **[Architecture Overview](DOCS/architecture_overview.md)** : High-level entry point and navigation

## Getting Started

### Prerequisites
- Microsoft Fabric workspace access
- Lakehouse and Data Warehouse artifacts
- Power BI workspace (for reporting layer)
- Appropriate RBAC permissions (see `GOVERNANCE/rbac_model.md`)

### Initial Setup
1. Review the [Architecture Overview](DOCS/architecture_overview.md) to understand the platform structure
2. Review the [Workspace Strategy](GOVERNANCE/workspace_strategy.md) for workspace organization
3. Review the [Naming Conventions](GOVERNANCE/naming_conventions.md) for naming standards
4. Set up the Schema Registry contracts (see `GOVERNANCE/schema-registry/`)

### Running the Platform
1. **Bronze Ingestion** : Execute `pl_bronze_master` pipeline to ingest raw data
2. **Silver Transformation** : Execute `pl_silver_master` pipeline to clean and validate data
3. **Gold Aggregation** : Execute `pl_gold_master` pipeline to build the star schema
4. **DWH Refresh** : Execute `pl_dwh_refresh_month_e2e` pipeline for monthly warehouse refresh
5. **Power BI** : Refresh semantic models and dashboards (Direct Lake connectivity)

For detailed execution contracts, see:
- `ORCHESTRATION/01-bronze/notebooks-contract.md`
- `ORCHESTRATION/02-silver/notebooks-contract.md`
- `ORCHESTRATION/03-gold/notebooks-contract.md`
- `ORCHESTRATION/04-dwh/notebooks-contract.md`

## License

[Add license information here]

---

**Author**: Gabriel Borrat  
**Version**: 1.0  
**Platform**: Microsoft Fabric  
**Architecture**: Extended Medallion (Bronze → Silver → Gold → DWH → Power BI)