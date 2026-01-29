# Architecture Overview (High Level)

Ce document fournit une **synthèse très haut niveau** de l’architecture du projet et sert de **point d’entrée** vers la documentation “source of truth” existante.

## Architecture (vue d’ensemble)

La plateforme implémente une architecture **Medallion** (Bronze → Silver → Gold) sur Microsoft Fabric pour une plateforme d'analytique Wealth Management.

L'architecture Medallion est un modèle en couches qui permet une transformation progressive des données, de l'ingestion brute jusqu'aux données analytiques optimisées pour la consommation métier.

### Couches principales

- **🔷 Bronze** : Ingestion et standardisation des données brutes provenant de sources hétérogènes
  - Pipeline générique paramétré pour toutes les entités
  - Normalisation des colonnes (snake_case), typage strict
  - Schema Registry (YAML) + validation post-ingestion
  - Manifest (file-level) + Archive (immutable storage)
  - Ingestion incrémentale basée sur manifest

- **🔶 Silver** : Nettoyage, validation et enrichissement des données Bronze
  - Suppression des doublons, gestion des valeurs nulles
  - Jointures entre tables, calculs de champs dérivés
  - Validation de la qualité des données
  - Schema Registry pour garantir la cohérence

- **🟡 Gold** : Modèle dimensionnel (Star Schema) optimisé pour l'analytique
  - Dimensions : `dim_card`, `dim_date`, `dim_mcc`, `dim_user`
  - Faits : `fact_transactions`
  - Tables optimisées pour Direct Lake Power BI

- **📦 DWH** : Couche SQL Data Warehouse (jobs, contrôles, publication)
  - Refresh mensuel orchestré (`pl_dwh_refresh_month_e2e`)
  - Jobs SQL pilotés par registre (`dbo.wh_ctl_job`)
  - Contrôles qualité et réconciliation
  - Publication gated (freshness/completeness checks)

Voir le document global :
- `DOCS/architecture/ARCHITECTURE.md`

## “Où trouver quoi ?” (table des matières)

### Comprendre l’architecture globale
- `DOCS/architecture/ARCHITECTURE.md` (document détaillé)
- `DOCS/architecture/medailion.jpg` (diagramme Medallion)
- `DOCS/architecture/workspace_vs_objects.png` (organisation workspaces)

### Comprendre l’orchestration (pipelines / run IDs / contrats d’exécution)
- **Orchestration par couche** : `ORCHESTRATION/README.md`
- **Contrats d’exécution** (par couche) :
  - Bronze : `ORCHESTRATION/01-bronze/notebooks-contract.md`
  - Silver : `ORCHESTRATION/02-silver/notebooks-contract.md`
  - Gold : `ORCHESTRATION/03-gold/notebooks-contract.md`
  - DWH : `ORCHESTRATION/04-dwh/notebooks-contract.md`

### Comprendre le détail des pipelines
- `DOCS/pipeline_overview.md` (document transversal)

### Documentation par couche (engineering)
- **Bronze** : `01-BRONZE/docs/`
- **Silver** : `02-SILVER/docs/`
- **Gold** : `03-GOLD/docs/`
- **DWH** : `04-DWH/docs/`

### Gouvernance (Schema Registry, RBAC, workspaces, observabilité)
- Point d’entrée : `GOVERNANCE/README.md`
- Naming conventions : `GOVERNANCE/naming_conventions.md`
- RBAC : `GOVERNANCE/rbac_model.md`
- Workspace strategy : `GOVERNANCE/workspace_strategy.md`
- Schema registry :
  - Bronze : `GOVERNANCE/schema-registry/01-bronze/`
  - Silver : `GOVERNANCE/schema-registry/02-silver/`
- Runtime governance :
  - Bronze : `GOVERNANCE/runtime/01-bronze/`
  - Silver : `GOVERNANCE/runtime/02-silver/`
  - Gold : `GOVERNANCE/runtime/03-gold/`

### Power BI (semantic model, mesures, rapports)
- **Modèle Sémantique** : Direct Lake connecté directement au Lakehouse
- **Measures DAX** : AUM, PnL, FX Exposure, Risk (`POWERBI/semantic-model/measures/`)
- **Dashboards** : AUM_PnL_Dashboard, Risk_Exposure_Dashboard (`POWERBI/reports/`)
- **Dataset** : Configurations (`POWERBI/dataset/`)

## Flux de données (end-to-end)

```
Sources Externes (S3, etc.)
    ↓
[Landing Zone] (temporaire)
    ↓
🔷 BRONZE (bronze_<entity>_raw)
    - Entités : FX, STOCK, ETF, PRICES, SECURITIES, FUNDAMENTALS, 
                CUSTOMER, USER, CARD, TRANSACTION, MCC
    - Manifest file-level + Archive
    ↓ [Transformation & Nettoyage]
🔶 SILVER (silver_<entity>)
    - Entités : silver_cards, silver_fx, silver_mcc, 
                silver_transactions, silver_users
    - Contrôles qualité, déduplication
    ↓ [Enrichissement & Agrégation]
🟡 GOLD (dim_* / fact_*)
    - Dimensions : dim_card, dim_date, dim_mcc, dim_user
    - Faits : fact_transactions
    - Anomaly tracking (gold_anomaly_event, gold_anomaly_kpi)
    ↓ [Direct Lake]
📊 POWER BI (Semantic Model & Dashboards)
    - Direct Lake : connexion native au Lakehouse
    - Measures DAX : AUM, PnL, FX Exposure, Risk
    - Dashboards : AUM_PnL_Dashboard, Risk_Exposure_Dashboard
    ↓ [Optionnel]
📦 DWH (wh_wm_analytics)
    - Refresh mensuel orchestré
    - Jobs SQL (dimensions, facts, aggregates, controls, publish)
    - Contrôles qualité et réconciliation Gold vs DWH
```

## Entités par couche (résumé)

### Bronze (12 entités)
- **Market Data** : FX, STOCK, ETF, PRICES, PRICES_SPLIT_ADJUSTED, SECURITIES, FUNDAMENTALS
- **Customer Data** : CUSTOMER, USER, CARD, TRANSACTION
- **Reference Data** : MCC

Tables : `bronze_<entity>_raw` (ex: `bronze_fx_raw`, `bronze_transaction_raw`)

### Silver (5 entités)
- `silver_cards` : Données de cartes nettoyées
- `silver_fx` : Taux de change standardisés
- `silver_mcc` : Codes MCC enrichis
- `silver_transactions` : Transactions validées et enrichies
- `silver_users` : Utilisateurs dédupliqués et enrichis

### Gold (Star Schema)
- **Dimensions** : `dim_card`, `dim_date`, `dim_mcc`, `dim_user`
- **Faits** : `fact_transactions`

### DWH (Data Warehouse SQL)
- **Dimensions** : `dim_card`, `dim_date`, `dim_mcc`, `dim_month`, `dim_user`
- **Facts** : `fact_transactions`, `fact_transactions_daily`, `fact_transactions_monthly`
- **Control tables** : `wh_ctl_job`, `wh_job_run_log`, `wh_dq_check_result`, `wh_run`

## Points clés de l'architecture

✅ **Unified Framework** : Pipeline unique générique pour toutes les entités Bronze  
✅ **Schema Registry** : Contrats YAML pour gouvernance des schémas (Bronze, Silver)  
✅ **Manifest-based Incremental** : Ingestion incrémentale basée sur manifest (pas de watermark)  
✅ **Failure Isolation** : Isolation des erreurs au niveau fichier (Bronze)  
✅ **Audit Trail** : Manifest + Archive pour traçabilité complète  
✅ **Star Schema** : Modèle dimensionnel optimisé pour analytique (Gold)  
✅ **Direct Lake** : Intégration native avec Power BI via Direct Lake  
✅ **Job Registry Driven** : DWH orchestré via registre de jobs (`dbo.wh_ctl_job`)  
✅ **Pipeline-driven Run IDs** : Identité d'exécution gouvernée par pipeline (`@pipeline().RunId`)

## Conventions & “sources of truth”

- **Architecture globale** : `DOCS/architecture/ARCHITECTURE.md`
- **Description détaillée des pipelines** : `DOCS/pipeline_overview.md`
- **Contrats d’exécution** : `ORCHESTRATION/*/notebooks-contract.md` (par couche)
- **Schémas attendus** : `GOVERNANCE/schema-registry/*` (YAML contracts)
- **Gouvernance d’exécution** : `GOVERNANCE/runtime/*` (run IDs, logs, DQ/anomalies)
- **Orchestration** : `ORCHESTRATION/README.md` (vue d’ensemble par couche)
- **Gouvernance** : `GOVERNANCE/README.md` (Schema Registry, RBAC, workspaces)

