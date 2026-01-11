# Gold Layer – Overview

## Purpose
The **Gold layer** represents the final, business-ready, and governed data layer of the Wealth Management Analytics platform on **Microsoft Fabric**.

It is designed to support:
- Power BI Semantic Models (Direct Lake)
- Regulatory-grade analytics
- Auditable reporting (transactions, cards, users, MCC)
- Data quality and anomaly monitoring

## Design Principles (Banking-Grade)
- **Contract-first modeling**: schemas are explicit and enforced
- **Idempotent execution**: FULL rebuilds are deterministic
- **Strict lineage**: Gold reads exclusively from Silver
- **Fail-fast strategy**: errors stop the run and are logged
- **End-to-end traceability**: every record is linked to a `gold_run_id`

## Target Model (v1)

### Dimensions
- `gold_dim_date`
- `gold_dim_user`
- `gold_dim_card`
- `gold_dim_mcc`

### Facts
- `gold_fact_transactions`
  - Grain: 1 row per transaction
  - Partitioning: by transaction month

## Governance & Audit Tables
- `gold_log_runs` – one row per Gold execution
- `gold_log_steps` – one row per entity step (append-only)
- `gold_anomaly_event` – row-level data quality issues
- `gold_anomaly_kpi` – aggregated anomaly metrics per run

## Consumption
- Power BI (Direct Lake)
- Downstream analytics
- Operational monitoring and audit reviews
