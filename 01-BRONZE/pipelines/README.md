# Bronze Layer Pipelines

Ce dossier contient les pipelines spécifiques à la couche Bronze.

## Pipeline Générique d'Ingestion

### `pl_ingest_generic.json`
Pipeline paramétré et réutilisable qui gère l'ingestion de toutes les entités Bronze.

**Caractéristiques principales :**
- Pipeline unique pour toutes les entités (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, etc.)
- Configuration via paramètres (entité, chemins source/landing/archive, mode d'ingestion)
- Ingestion incrémentale basée sur manifest
- Gestion des erreurs au niveau fichier (isolation des échecs)
- Audit trail complet (manifest + archive)

**Paramètres :**
- `p_Entity` : Identifiant de l'entité (FX, CUSTOMER, STOCK, etc.)
- `p_SourcePath` : Chemin source dans le bucket S3
- `p_LandingPath` : Chemin de la zone Landing dans Lakehouse
- `p_ArchivePath` : Chemin de la zone Archive dans Lakehouse
- `p_IngestionMode` : Mode d'ingestion (FULL ou INCR)
- `p_WatermarkDays` : Nombre de jours pour le watermark (mode INCR)

Pour plus de détails, voir la documentation dans `01-BRONZE/docs/` et `DOCS/pipeline_overview.md`.

