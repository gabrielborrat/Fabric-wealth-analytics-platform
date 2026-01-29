# Governance

Ce dossier regroupe les artefacts de **gouvernance** de la plateforme Wealth Management Analytics sur Microsoft Fabric :

- conventions de nommage
- stratégie d’organisation des workspaces
- modèle RBAC (rôles & permissions)
- **Schema Registry** (contrats de schémas par couche)
- **Runtime governance** (run IDs, logging, contrôle de conformité et assets de supervision)

## Organisation du dossier

### Documents de référence
- **Conventions de nommage** : `GOVERNANCE/naming_conventions.md`
- **Modèle RBAC** : `GOVERNANCE/rbac_model.md`
- **Stratégie workspaces** : `GOVERNANCE/workspace_strategy.md`

### Schema Registry (contrats)
Contrats de schémas versionnés (YAML) par couche :

- **Bronze** : `GOVERNANCE/schema-registry/01-bronze/`
  - `_registry_index.yaml`, `_template.yaml`, et un fichier par entité (ex: `fx.yaml`, `transaction.yaml`, `user.yaml`…)
- **Silver** : `GOVERNANCE/schema-registry/02-silver/`
  - `silver_fx.yaml`, `silver_transactions.yaml`, etc.

Ces contrats définissent le **schema attendu** (colonnes / types / ordre) et servent de base à la validation de conformité.

### Runtime governance (exécution & observabilité)
Artefacts expliquant le modèle de run IDs, logging, tables de contrôle et captures d’écran d’exploitation :

- **Bronze runtime** : `GOVERNANCE/runtime/01-bronze/`
  - `overview.md`, `run_ids_and_logging.md`, `nb_validate_bronze_schema_registry.ipynb`
  - screenshots: `tech_ingestion_manifest.png`, `tech_ingestion_log.png`, `tech_schema_compliance.png`, etc.
- **Silver runtime** : `GOVERNANCE/runtime/02-silver/`
  - `overview.md`, `run_ids_and_logging.md`, `entity_payload.json`
  - screenshots: `silver_ctl_entity.png`, `silver_log_runs.png`, `silver_log_steps.png`
- **Gold runtime** : `GOVERNANCE/runtime/03-gold/`
  - `overview.md`, `run_ids_and_logging.md`
  - screenshots: `gold_log_runs.png`, `gold_log_steps.png`, `gold_ctl_entity.png`, `gold_anomaly_event.png`, `gold_anomaly_kpi.png`

## Gouvernance “par couche” (résumé)

### 01 — Bronze
- **Contrat** : schema contract-first (YAML) + validation post-ingestion via `nb_validate_bronze_schema_registry`
- **Audit** : manifest file-level (`tech_ingestion_manifest`) + log run-level (`tech_ingestion_log`) + conformité (`tech_schema_compliance`)
- **Run ID** : piloté par pipeline (`@pipeline().RunId`)

Voir :
- `GOVERNANCE/runtime/01-bronze/overview.md`
- `GOVERNANCE/runtime/01-bronze/run_ids_and_logging.md`
- `GOVERNANCE/schema-registry/01-bronze/`

### 02 — Silver
- **Contrat** : schémas explicites + exécution orchestrée via dispatcher
- **Audit** : `silver_log_runs` + `silver_log_steps`
- **Payload** : standardisé via `entity_payload.json`
- **Run ID** : `silver_run_id = @pipeline().RunId`

Voir :
- `GOVERNANCE/runtime/02-silver/overview.md`
- `GOVERNANCE/runtime/02-silver/run_ids_and_logging.md`
- `GOVERNANCE/runtime/02-silver/entity_payload.json`
- `GOVERNANCE/schema-registry/02-silver/`

### 03 — Gold
- **Contrat** : exécution orchestrée via dispatcher, run ID gouverné par pipeline
- **Audit** : `gold_log_runs` + `gold_log_steps`
- **Qualité / anomalies** : `gold_anomaly_event` (row-level) + `gold_anomaly_kpi` (agrégé)

Voir :
- `GOVERNANCE/runtime/03-gold/overview.md`
- `GOVERNANCE/runtime/03-gold/run_ids_and_logging.md`

## Architecture OneLake (captures)
Captures d’écran de l’organisation des zones (Landing / Governance / Archive) :

- `GOVERNANCE/lakehouse_Files.png`
- `GOVERNANCE/lakehouse_Files_landing.png`
- `GOVERNANCE/lakehouse_Files_governance.png`
- `GOVERNANCE/lakehouse_Files_archive.png`

