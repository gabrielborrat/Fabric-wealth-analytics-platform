# Orchestration

Ce dossier contient les artefacts d'orchestration organisés par **couches** (Bronze, Silver, Gold, DWH).

## Organisation

### Par Couches

Les pipelines d'orchestration sont organisés selon les couches Medallion :

- **`01-bronze/`** : Orchestration de la couche Bronze (ingestion)
- **`02-silver/`** : Orchestration de la couche Silver (nettoyage et validation)
- **`03-gold/`** : Orchestration de la couche Gold (modèle dimensionnel)
- **`04-dwh/`** : Orchestration de la couche DWH (Data Warehouse SQL + contrôles + publication)

> Note: une organisation “par silos métier” peut être ajoutée si besoin, mais ce repository ne contient pas de dossier `ORCHESTRATION/silos/` à ce jour.

---

## 01 — Bronze

### Artefacts
- **Master pipeline**: `01-BRONZE/pipelines/pl_master_ingestion.json`
- **Pipeline générique**: `01-BRONZE/pipelines/pl_bronze_ingest_generic.json` (parameter-driven)
- **Notebooks**:
  - `nb_load_generic_bronze` (transformation)
  - `nb_prepare_incremental_list`
  - `nb_update_manifest`
  - `nb_log_ingestion`
  - `nb_validate_bronze_schema_registry`

### Rôle
Ingestion **raw-but-typed**, standardisation, auditabilité (manifest + log), et validation de schéma post-ingestion.

### Documentation
- `ORCHESTRATION/01-bronze/orchestration.md`
- `ORCHESTRATION/01-bronze/notebooks-contract.md`

---

## 02 — Silver

### Artefacts
- **Pipeline**: `02-SILVER/pipelines/pl_silver_load_generic.json`
- **Dispatcher notebook**: `nb_silver_load`
- **Child notebooks**: `nb_silver_*` (cards, fx, mcc, transactions, users, etc.)

### Paramètres clés (pipeline)
- `p_entity_code`, `p_load_mode`, `p_as_of_date`
- `p_environment`, `p_triggered_by`, `p_pipeline_name`
- `p_silver_run_id` (injecté via `@pipeline().RunId`)

### Documentation
- `ORCHESTRATION/02-silver/orchestration.md`
- `ORCHESTRATION/02-silver/notebooks-contract.md`

---

## 03 — Gold

### Artefacts
- **Pipeline**: `03-GOLD/pipelines/pl_gold_load_generic.json`
- **Dispatcher notebook**: `nb_gold_load`
- **Child notebooks**: `nb_gold_dim_*`, `nb_gold_fact_*`

### Paramètres clés (pipeline)
- `p_entity_code`, `p_load_mode`, `p_as_of_date`
- `p_environment`, `p_triggered_by`, `p_pipeline_name`
- `p_gold_run_id` (injecté via `@pipeline().RunId`)

### Documentation
- `ORCHESTRATION/03-gold/orchestration.md`
- `ORCHESTRATION/03-gold/notebooks-contract.md`

---

## 04 — DWH (Data Warehouse)

### Artefacts
- **Orchestrateur E2E (mensuel)**: `04-DWH/pipelines/pl_dwh_refresh_month_e2e.json`
- **Pipelines de groupe**:
  - `04-DWH/pipelines/pl_dwh_refresh_dimensions.json` (DIMS)
  - `04-DWH/pipelines/pl_dwh_refresh_facts.json` (FACTS)
  - `04-DWH/pipelines/pl_dwh_refresh_aggregates.json` (AGG)
  - `04-DWH/pipelines/pl_dwh_refresh_controls.json` (CONTROLS)
  - `04-DWH/pipelines/pl_dwh_publish.json` (PUBLISH)
- **Exécution**: procédures SQL pilotées par `dbo.wh_ctl_job` (Script activities)

### Paramètres clés (orchestrateur)
- `p_TxnMonth`, `p_ExecDate`, `p_RunId`

### Documentation
- `ORCHESTRATION/04-dwh/orchestration.md`
- `ORCHESTRATION/04-dwh/notebooks-contract.md`

