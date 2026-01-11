# Proposition d'Arborescence - Architecture Medallion

## Structure Recommandée (Avec Modifications Demandées)

Cette structure met en évidence la compréhension de l'architecture medallion (Bronze → Silver → Gold) et facilite la navigation pour un recruteur, avec une organisation claire par couches et une séparation logique des responsabilités.

```
Fabric-wealth-analytics-platform/
│
├── 📋 README.md                          # Vue d'ensemble du projet
├── 📋 ARCHITECTURE.md                    # Architecture medallion expliquée
│
├── 🔷 01-BRONZE/                         # COUCHE BRONZE - Données brutes standardisées
│   ├── 📁 notebooks/                     # Notebooks de transformation Bronze
│   │   ├── nb_load_generic_bronze.ipynb
│   │   ├── nb_prepare_incremental_list.ipynb
│   │   ├── nb_log_ingestion.ipynb
│   │   ├── nb_update_manifest.ipynb
│   │   └── nb_validate_bronze_schema_registry.ipynb
│   │
│   ├── 📁 pipelines/                     # Pipelines spécifiques Bronze
│   │   ├── pl_ingest_generic.json       # Pipeline générique paramétré
│   │   └── README.md                     # Documentation spécifique Bronze
│   │
│   └── 📁 docs/                          # Documentation Bronze
│       ├── bronze-layer-overview.md
│       ├── bronze-layer-pipeline.md
│       ├── bronze-manifest-logging.md
│       ├── bronze-notebook-overview.md
│       └── bronze-schema-data-dictionary.md
│
├── 🔶 02-SILVER/                         # COUCHE SILVER - Données nettoyées et validées
│   ├── 📁 notebooks/                     # Notebooks de transformation Silver
│   │   ├── nb_silver_ddl.ipynb
│   │   ├── nb_load_silver.ipynb
│   │   ├── nb_silver_cards.ipynb
│   │   ├── nb_silver_fx.ipynb
│   │   ├── nb_silver_mcc.ipynb
│   │   ├── nb_silver_transactions.ipynb
│   │   ├── nb_silver_users.ipynb
│   │   └── nb_silver_utils.ipynb
│   │
│   ├── 📁 pipelines/                     # Pipelines spécifiques Silver
│   │   └── (pipelines Silver si nécessaire)
│   │
│   └── 📁 docs/                          # Documentation Silver
│       └── (documentation Silver)
│
├── 🟡 03-GOLD/                           # COUCHE GOLD - Données analytiques (Star Schema)
│   ├── 📁 notebooks/                     # Notebooks de transformation Gold
│   │   ├── nb_gold_ddl.ipynb
│   │   ├── nb_gold_dim_card.ipynb
│   │   ├── nb_gold_dim_date.ipynb
│   │   ├── nb_gold_dim_mcc.ipynb
│   │   ├── nb_gold_dim_user.ipynb
│   │   └── nb_gold_fact_transactions.ipynb
│   │
│   ├── 📁 pipelines/                     # Pipelines spécifiques Gold
│   │   └── (pipelines Gold si nécessaire)
│   │
│   └── 📁 docs/                          # Documentation Gold
│       └── (documentation schéma dimensionnel)
│
├── 🔄 ORCHESTRATION/                     # Pipelines d'orchestration (cross-layer)
│   ├── 📁 01-bronze/                     # Orchestration Bronze
│   │   ├── pl_master_ingestion.json     # Master pipeline Bronze
│   │   └── README.md
│   │
│   ├── 📁 02-silver/                     # Orchestration Silver
│   │   └── (pipelines d'orchestration Silver si nécessaire)
│   │
│   ├── 📁 03-gold/                       # Orchestration Gold
│   │   └── (pipelines d'orchestration Gold si nécessaire)
│   │
│   ├── 📁 silos/                         # Orchestration par silos métier
│   │   ├── 📁 market-data/               # Silos Market Data (FX, STOCK, ETF, PRICES, etc.)
│   │   │   └── pl_orchestrate_market_data.json
│   │   │
│   │   ├── 📁 customer-data/             # Silos Customer Data (CUSTOMER, USER, CARD, TRANSACTION)
│   │   │   └── pl_orchestrate_customer_data.json
│   │   │
│   │   └── 📁 reference-data/            # Silos Reference Data (MCC, SECURITIES, FUNDAMENTALS)
│   │       └── pl_orchestrate_reference_data.json
│   │
│   └── README.md                         # Documentation orchestration globale
│
├── 📊 POWERBI/                           # Visualisation et Analytics
│   ├── 📁 semantic-model/                # Modèle sémantique (Direct Lake)
│   │   ├── model.bim
│   │   ├── relationships.png
│   │   ├── tables_schema.json
│   │   └── 📁 measures/
│   │       ├── aum_measures.dax
│   │       ├── fx_exposure_measures.dax
│   │       ├── pnl_measures.dax
│   │       └── risk_measures.dax
│   │
│   ├── 📁 reports/                       # Dashboards Power BI
│   │   ├── AUM_PnL_Dashboard/
│   │   │   ├── AUM_PnL_Dashboard.pbip
│   │   │   ├── README.md
│   │   │   └── 📁 screenshots/
│   │   │
│   │   ├── Risk_Exposure_Dashboard/
│   │   │   ├── Risk_Exposure_Dashboard.pbip
│   │   │   ├── README.md
│   │   │   └── 📁 screenshots/
│   │   │
│   │   └── Navigation_Map/
│   │       └── report_navigation_map.png
│   │
│   └── 📁 dataset/                       # Configuration datasets
│       ├── dataset_definition.json
│       ├── partitions_info.json
│       └── refresh_plan.md
│
├── 🛡️ GOVERNANCE/                        # Gouvernance et politiques
│   ├── 📁 schema-registry/               # Schema Registry centralisé
│   │   ├── 📁 01-bronze/                 # Contrats YAML Bronze
│   │   │   ├── _registry_index.yaml
│   │   │   ├── _template.yaml
│   │   │   ├── card.yaml
│   │   │   ├── customer.yaml
│   │   │   ├── etf.yaml
│   │   │   ├── fundamentals.yaml
│   │   │   ├── fx.yaml
│   │   │   ├── mcc.yaml
│   │   │   ├── prices.yaml
│   │   │   ├── prices_split_adjusted.yaml
│   │   │   ├── securities.yaml
│   │   │   ├── stock.yaml
│   │   │   ├── transaction.yaml
│   │   │   └── user.yaml
│   │   │
│   │   ├── 📁 02-silver/                 # Contrats YAML Silver
│   │   │   ├── silver_cards.yaml
│   │   │   ├── silver_fx.yaml
│   │   │   ├── silver_mcc.yaml
│   │   │   ├── silver_transactions.yaml
│   │   │   └── silver_users.yaml
│   │   │
│   │   └── 📁 03-gold/                   # Contrats YAML Gold (si nécessaire)
│   │       └── (schémas Gold)
│   │
│   ├── 📁 runtime/                       # Données de runtime (ex: entity_payload.json)
│   │   └── silver/
│   │       └── entity_payload.json
│   │
│   ├── data_classification_policy.md
│   ├── devops_cicd_strategy.md
│   ├── naming_conventions.md
│   ├── rbac_model.md
│   └── workspace_strategy.md
│
├── 📸 SCREENSHOTS/                       # Captures d'écran organisées par couche
│   ├── 📁 01-bronze/
│   │   ├── lakehouse_bronze_card_raw.png
│   │   ├── lakehouse_bronze_customer_raw.png
│   │   ├── lakehouse_bronze_etf_raw.png
│   │   ├── lakehouse_bronze_fundamentals_raw.png
│   │   ├── lakehouse_bronze_fx_raw.png
│   │   ├── lakehouse_bronze_mcc_raw.png
│   │   ├── lakehouse_bronze_overview.png
│   │   ├── lakehouse_bronze_prices_raw.png
│   │   ├── lakehouse_bronze_prices_split_adjusted_raw.png
│   │   ├── lakehouse_bronze_securities_raw.png
│   │   ├── lakehouse_bronze_stock_raw.png
│   │   ├── lakehouse_bronze_transactions_raw.png
│   │   └── lakehouse_bronze_user_raw.png
│   │
│   ├── 📁 02-silver/
│   │   └── (screenshots Silver)
│   │
│   ├── 📁 03-gold/
│   │   └── (screenshots Gold)
│   │
│   ├── 📁 pipelines/
│   │   ├── lakehouse_tech_ingestion_log.png
│   │   ├── lakehouse_tech_ingestion_manifest.png
│   │   ├── lakehouse_tech_schema_compliance.png
│   │   ├── pl_generic_overview.png
│   │   └── pl_master_ingestion.png
│   │
│   └── 📁 powerbi/
│       ├── powerbi_aum_pnl_overview.png
│       ├── powerbi_fx_exposure_page.png
│       └── powerbi_risk_exposure_page.png
│
└── 📚 DOCS/                              # Documentation globale et architecture
    ├── 📁 architecture/                  # Diagrammes d'architecture globale
    │   └── (diagrammes d'architecture)
    │
    └── pipeline_overview.md              # Vue d'ensemble des pipelines
```

## Caractéristiques de cette Structure

### ✅ Organisation par Couches Medallion (01-, 02-, 03-)
- **01-BRONZE/** : Données brutes standardisées
- **02-SILVER/** : Données nettoyées et validées
- **03-GOLD/** : Données analytiques (Star Schema)
- Chaque couche a 3 sous-dossiers : `notebooks/`, `pipelines/`, `docs/`

### ✅ Orchestration Organisée
- **Par couches** : `ORCHESTRATION/01-bronze/`, `ORCHESTRATION/02-silver/`, `ORCHESTRATION/03-gold/`
- **Par silos métier** : `ORCHESTRATION/silos/market-data/`, `customer-data/`, `reference-data/`

### ✅ Schema Registry Centralisé dans Governance
- `GOVERNANCE/schema-registry/01-bronze/` : Contrats Bronze
- `GOVERNANCE/schema-registry/02-silver/` : Contrats Silver
- `GOVERNANCE/schema-registry/03-gold/` : Contrats Gold (si nécessaire)

### ✅ Autres Dossiers
- **POWERBI/** : Semantic model, reports, datasets
- **GOVERNANCE/** : Politiques, schémas, stratégies
- **SCREENSHOTS/** : Organisés par couche et fonctionnalité
- **DOCS/** : Documentation globale et architecture

## Avantages pour un Recruteur

✅ **Visibilité immédiate** : Les 3 couches medallion numérotées au premier niveau  
✅ **Progression logique** : Bronze → Silver → Gold suit le flux de données  
✅ **Séparation des responsabilités** : notebooks, pipelines, docs bien organisés  
✅ **Facilité de navigation** : Structure claire et prévisible  
✅ **Démonstration de compréhension** : Montre une maîtrise de l'architecture medallion  
✅ **Orchestration structurée** : Organisation par couches ET par silos métier  
✅ **Governance centralisée** : Schema registry unifié avec séparation par couches  

## Migration Recommandée

1. **Créer les dossiers** avec préfixes numériques (`01-BRONZE/`, `02-SILVER/`, `03-GOLD/`)
2. **Créer les sous-dossiers** `notebooks/`, `pipelines/`, `docs/` dans chaque couche
3. **Déplacer les fichiers** existants :
   - `src/bronze/*.ipynb` → `01-BRONZE/notebooks/`
   - `src/silver/*.ipynb` → `02-SILVER/notebooks/`
   - `src/gold/*.ipynb` → `03-GOLD/notebooks/`
   - `pipelines/pl_ingest_generic.json` → `01-BRONZE/pipelines/`
   - `pipelines/pl_master_ingestion.json` → `ORCHESTRATION/01-bronze/`
   - `governance/schema_registry/bronze/` → `GOVERNANCE/schema-registry/01-bronze/`
   - `governance/schema_registry/silver/` → `GOVERNANCE/schema-registry/02-silver/`
   - `docs/bronze/*.md` → `01-BRONZE/docs/`
   - `docs/screenshots/*` → `SCREENSHOTS/01-bronze/` (et autres)
4. **Créer la structure ORCHESTRATION** avec dossiers `01-bronze/`, `02-silver/`, `03-gold/`, `silos/`
5. **Mettre à jour les chemins** dans les pipelines JSON si nécessaire
6. **Créer un ARCHITECTURE.md** qui explique la structure medallion
7. **Mettre à jour le README.md** avec la nouvelle structure

## Note sur les Silos

Les silos dans `ORCHESTRATION/silos/` peuvent être organisés par domaine métier :
- **market-data** : FX, STOCK, ETF, PRICES, SECURITIES, FUNDAMENTALS
- **customer-data** : CUSTOMER, USER, CARD, MCC, TRANSACTION
- **reference-data** : Codes de référence, données maîtres

Cette organisation permet une orchestration fine par domaine métier tout en conservant la logique par couches.

