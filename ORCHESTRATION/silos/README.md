# Orchestration par Silos Métier

Ce dossier contient les pipelines d'orchestration organisés par **domaines métier** (silos).

## Silos Disponibles

### Market Data (`market-data/`)
Orchestration pour les données de marché et instruments financiers :
- FX (Taux de change)
- STOCK (Actions)
- ETF (Exchange Traded Funds)
- PRICES (Prix de marché)
- PRICES_SPLIT_ADJUSTED (Prix ajustés)
- SECURITIES (Instruments de sécurité)
- FUNDAMENTALS (Données fondamentales)

### Customer Data (`customer-data/`)
Orchestration pour les données clients et transactions :
- CUSTOMER (Clients)
- USER (Utilisateurs)
- CARD (Cartes)
- TRANSACTION (Transactions)
- MCC (Merchant Category Codes)

### Reference Data (`reference-data/`)
Orchestration pour les données de référence et codes :
- Codes de référence
- Données maîtres
- Tables de correspondance

## Utilisation

Les silos permettent une orchestration fine par domaine métier, permettant de :
- Exécuter des pipelines par domaine indépendamment
- Optimiser les dépendances entre domaines
- Faciliter la maintenance et l'évolution par domaine métier

