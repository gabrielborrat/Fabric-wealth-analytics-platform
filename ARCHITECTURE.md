# Architecture Medallion - Fabric Wealth Management Analytics Platform

## Vue d'ensemble

Ce projet implémente une architecture **Medallion** (Bronze → Silver → Gold) sur Microsoft Fabric pour une plateforme d'analytique Wealth Management.

L'architecture Medallion est un modèle en couches qui permet une transformation progressive des données, de l'ingestion brute jusqu'aux données analytiques optimisées pour la consommation métier.

---

## 🔷 Couche Bronze (01-BRONZE)

### Objectif
Ingestion et standardisation des données brutes provenant de sources hétérogènes.

### Fonctionnalités principales
- **Ingestion unifiée** : Pipeline générique paramétré pour toutes les entités
- **Standardisation** : Normalisation des colonnes (snake_case), typage strict
- **Métadonnées techniques** : Ajout systématique de `source_file`, `ingestion_date`, `ingestion_ts`, `entity`
- **Gouvernance** : Schema Registry (YAML) + validation post-ingestion
- **Audit trail** : Manifest (file-level) + Archive (immutable storage)
- **Ingestion incrémentale** : Basée sur manifest pour éviter les reprocessements

### Entités ingérées
- Market Data : FX, STOCK, ETF, PRICES, PRICES_SPLIT_ADJUSTED, SECURITIES, FUNDAMENTALS
- Customer Data : CUSTOMER, USER, CARD, TRANSACTION
- Reference Data : MCC

### Structure
```
01-BRONZE/
├── notebooks/      # Notebooks de transformation Bronze
├── pipelines/      # Pipeline générique pl_ingest_generic.json
└── docs/           # Documentation spécifique Bronze
```

---

## 🔶 Couche Silver (02-SILVER)

### Objectif
Nettoyage, validation et enrichissement des données Bronze pour créer des datasets de qualité production.

### Fonctionnalités principales
- **Nettoyage** : Suppression des doublons, gestion des valeurs nulles, validation des contraintes
- **Enrichissement** : Jointures entre tables, calculs de champs dérivés
- **Qualité** : Validation de la qualité des données
- **Schémas validés** : Schema Registry pour garantir la cohérence

### Entités traitées
- `silver_cards` : Données de cartes nettoyées
- `silver_fx` : Taux de change standardisés
- `silver_mcc` : Codes MCC enrichis
- `silver_transactions` : Transactions validées et enrichies
- `silver_users` : Utilisateurs dédupliqués et enrichis

### Structure
```
02-SILVER/
├── notebooks/      # Notebooks de transformation Silver
├── pipelines/      # Pipelines Silver (si nécessaire)
└── docs/           # Documentation spécifique Silver
```

---

## 🟡 Couche Gold (03-GOLD)

### Objectif
Création d'un modèle dimensionnel (Star Schema) optimisé pour l'analytique et la consommation Power BI.

### Fonctionnalités principales
- **Star Schema** : Modèle dimensionnel avec faits et dimensions
- **Agrégations** : Pré-calculs pour optimiser les performances
- **Business logic** : Logique métier incorporée dans les transformations
- **Optimisation** : Tables optimisées pour Direct Lake Power BI

### Structure du modèle
**Dimensions :**
- `dim_card` : Dimension des cartes
- `dim_date` : Dimension temporelle
- `dim_mcc` : Dimension des codes MCC
- `dim_user` : Dimension des utilisateurs

**Faits :**
- `fact_transactions` : Table des faits transactions

### Structure
```
03-GOLD/
├── notebooks/      # Notebooks de transformation Gold
├── pipelines/      # Pipelines Gold (si nécessaire)
└── docs/           # Documentation spécifique Gold
```

---

## 🔄 Orchestration

### Organisation
Les pipelines d'orchestration sont organisés par **couches** et par **silos métier**.

### Structure
```
ORCHESTRATION/
├── 01-bronze/      # Orchestration Bronze (pl_master_ingestion)
├── 02-silver/      # Orchestration Silver
├── 03-gold/        # Orchestration Gold
└── silos/          # Orchestration par silos métier
    ├── market-data/      # Market Data (FX, STOCK, ETF, PRICES)
    ├── customer-data/    # Customer Data (CUSTOMER, USER, CARD, TRANSACTION)
    └── reference-data/   # Reference Data (MCC, SECURITIES, FUNDAMENTALS)
```

### Pipeline Master Bronze
Le pipeline `pl_master_ingestion` orchestre l'ingestion de toutes les entités Bronze dans un ordre déterminé, puis exécute la validation du schema registry.

---

## 📊 Visualisation (POWERBI)

### Modèle Sémantique
- **Direct Lake** : Modèle sémantique connecté directement au Lakehouse
- **Measures DAX** : Mesures calculées pour AUM, PnL, FX Exposure, Risk
- **Relationships** : Relations définies entre dimensions et faits

### Dashboards
- **AUM_PnL_Dashboard** : Assets Under Management et Profit & Loss
- **Risk_Exposure_Dashboard** : Exposition aux risques (FX, concentration)

---

## 🛡️ Gouvernance

### Schema Registry
Contrats YAML centralisés définissant les schémas pour chaque couche :

```
GOVERNANCE/schema-registry/
├── 01-bronze/    # Contrats Bronze (12 entités)
├── 02-silver/    # Contrats Silver (5 entités)
└── 03-gold/      # Contrats Gold (si nécessaire)
```

### Politiques
- **Data Classification Policy** : Classification des données
- **RBAC Model** : Modèle de contrôle d'accès basé sur les rôles
- **Naming Conventions** : Conventions de nommage
- **DevOps CI/CD Strategy** : Stratégie de déploiement continu
- **Workspace Strategy** : Stratégie d'organisation des workspaces

---

## Flux de Données

```
Sources Externes (S3, etc.)
    ↓
[Landing Zone] (temporaire)
    ↓
🔷 BRONZE (bronze_<entity>_raw)
    ↓ [Transformation & Nettoyage]
🔶 SILVER (silver_<entity>)
    ↓ [Enrichissement & Agrégation]
🟡 GOLD (dim_* / fact_*)
    ↓ [Direct Lake]
📊 POWER BI (Semantic Model & Dashboards)
```

---

## Points Clés de l'Architecture

✅ **Unified Framework** : Pipeline unique générique pour toutes les entités Bronze  
✅ **Schema Registry** : Contrats YAML pour gouvernance des schémas  
✅ **Manifest-based Incremental** : Ingestion incrémentale basée sur manifest  
✅ **Failure Isolation** : Isolation des erreurs au niveau fichier  
✅ **Audit Trail** : Manifest + Archive pour traçabilité complète  
✅ **Star Schema** : Modèle dimensionnel optimisé pour analytique  
✅ **Direct Lake** : Intégration native avec Power BI via Direct Lake  

---

## Documentation Complémentaire

- **Pipeline Overview** : `DOCS/pipeline_overview.md`
- **Bronze Layer** : `01-BRONZE/docs/`
- **Structure Proposal** : `STRUCTURE_PROPOSAL.md`

