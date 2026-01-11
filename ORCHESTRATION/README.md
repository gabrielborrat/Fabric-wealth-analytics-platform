# Orchestration

Ce dossier contient tous les pipelines d'orchestration organisés par **couches** et par **silos métier**.

## Organisation

### Par Couches

Les pipelines d'orchestration sont organisés selon les couches Medallion :

- **`01-bronze/`** : Orchestration de la couche Bronze (ingestion)
- **`02-silver/`** : Orchestration de la couche Silver (nettoyage et validation)
- **`03-gold/`** : Orchestration de la couche Gold (modèle dimensionnel)

### Par Silos Métier

Les pipelines peuvent également être organisés par domaines métier pour une orchestration fine :

- **`silos/market-data/`** : Orchestration pour les données de marché (FX, STOCK, ETF, PRICES, SECURITIES, FUNDAMENTALS)
- **`silos/customer-data/`** : Orchestration pour les données clients (CUSTOMER, USER, CARD, TRANSACTION, MCC)
- **`silos/reference-data/`** : Orchestration pour les données de référence (codes, données maîtres)

## Pipeline Master Bronze

Le pipeline principal `01-bronze/pl_master_ingestion.json` orchestre l'ingestion de toutes les entités Bronze dans un ordre déterminé.

Voir la documentation dans `01-bronze/README.md` pour plus de détails.

