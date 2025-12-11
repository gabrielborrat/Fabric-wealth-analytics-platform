#!/usr/bin/env python
# coding: utf-8

# ## nb_update_manifest
# 
# null

# In[ ]:


# PARAMETER_CELL
# Ces paramètres sont alimentés par le pipeline Fabric (Base parameters)

entity = ""             # ex: "FX", "CUSTOMER"
file_path = ""          # ex: "FX-rates-since2004-dataset/file.csv"
source_name = ""        # ex: "file.csv"
file_size = "-1"        # string dans les paramètres, on cast en long
modified_datetime = ""  # ex: "2025-11-30T10:15:00Z" ou vide si non dispo
exec_date = ""          # ex: "2025-11-30"
status = ""             # "SUCCESS", "FAILED", "PARTIAL", etc.
ingestion_mode = ""
total_source_files = "0"
total_candidate_files = "0"


# In[ ]:


from pyspark.sql import functions as F
from pyspark.sql.types import *
from pyspark.sql.utils import AnalysisException
from notebookutils import mssparkutils

print("== nb_update_manifest ==")
print(f"entity               = {entity}")
print(f"file_path            = {file_path}")
print(f"source_name          = {source_name}")
print(f"file_size (raw)      = {file_size}")
print(f"modified_datetime    = {modified_datetime}")
print(f"exec_date            = {exec_date}")
print(f"status               = {status}")
print(f"ingestion_mode     = {ingestion_mode}")
print(f"total_source_files   = {total_source_files}")
print(f"total_candidate_files= {total_candidate_files}")

# Sécurisation minimale
if not entity or not file_path:
    print("ERREUR : entity ou file_path manquant → aucune mise à jour manifest.")
    mssparkutils.notebook.exit("NO_UPDATE")

if not status:
    status = "UNKNOWN"

if not ingestion_mode:
    ingestion_mode = "UNKNOWN"

# Cast file_size en long
try:
    file_size_long = int(file_size)
except Exception:
    file_size_long = -1

# Cast des compteurs en int
try:
    total_source_files_int = int(total_source_files)
except Exception:
    total_source_files_int = -1

try:
    total_candidate_files_int = int(total_candidate_files)
except Exception:
    total_candidate_files_int = -1

# On garde modified_datetime tel quel, on le cast plus tard si non vide




# In[ ]:


from datetime import datetime

# Construction d'un seul enregistrement pour ce fichier
data = [(entity,
         file_path,
         source_name,
         file_size_long,
         modified_datetime if modified_datetime else None,
         exec_date,
         status,
         ingestion_mode,
         total_source_files_int,
         total_candidate_files_int
        )]

schema = StructType([
    StructField("entity", StringType(), False),
    StructField("file_path", StringType(), False),
    StructField("source_name", StringType(), True),
    StructField("file_size", LongType(), True),

    StructField("modified_datetime_raw", StringType(), True),
    StructField("exec_date_raw", StringType(), True),
    StructField("last_status", StringType(), True),

    StructField("ingestion_mode", StringType(), True),
    StructField("total_source_files_raw", IntegerType(), True),
    StructField("total_candidate_files_raw", IntegerType(), True),
])

df_stage = spark.createDataFrame(data, schema)

# Casts propres + normalisation des colonnes
df_stage = (
    df_stage
    .withColumn(
        "modified_datetime",
        F.when(
            F.col("modified_datetime_raw").isNotNull() & (F.col("modified_datetime_raw") != ""),
            F.to_timestamp("modified_datetime_raw")
        ).otherwise(F.lit(None).cast("timestamp"))
    )
    .withColumn(
        "exec_date",
        F.to_date("exec_date_raw")
    )
    .withColumn("first_ingested_datetime", F.current_timestamp())
    .withColumn("last_ingested_datetime", F.current_timestamp())
    .withColumnRenamed("total_source_files_raw", "total_source_files")
    .withColumnRenamed("total_candidate_files_raw", "total_candidate_files")
    .select(
        "entity",
        "file_path",
        "source_name",
        "file_size",
        "modified_datetime",
        "first_ingested_datetime",
        "last_ingested_datetime",
        "last_status",
        "exec_date",
        "ingestion_mode",
        "total_source_files",
        "total_candidate_files"
    )
)

print("Schéma staging (df_stage) :")
df_stage.printSchema()
display(df_stage)


# In[ ]:


# Vérification / création de la table tech_ingestion_manifest
try:
    spark.table("tech_ingestion_manifest")
    print("Table tech_ingestion_manifest déjà existante.")
except AnalysisException:
    print("Table tech_ingestion_manifest absente, création en cours...")

    (
        df_stage.limit(0)   # Ne crée que le schéma, pas de données
        .write
        .format("delta")
        .mode("overwrite")
        .saveAsTable("tech_ingestion_manifest")
    )

    print("Table tech_ingestion_manifest créée avec le schéma complet.")


# In[ ]:


# Création de la vue staging
df_stage.createOrReplaceTempView("stg_manifest_update")

merge_sql = """
MERGE INTO tech_ingestion_manifest AS tgt
USING stg_manifest_update AS src
  ON tgt.entity = src.entity
 AND tgt.file_path = src.file_path

WHEN MATCHED THEN
  UPDATE SET
    tgt.last_status             = src.last_status,
    tgt.last_ingested_datetime  = src.last_ingested_datetime,
    tgt.exec_date               = src.exec_date,
    tgt.source_name             = src.source_name,
    tgt.file_size               = src.file_size,
    tgt.modified_datetime       = src.modified_datetime,
    tgt.ingestion_mode        = src.ingestion_mode,
    tgt.total_source_files      = src.total_source_files,
    tgt.total_candidate_files   = src.total_candidate_files

WHEN NOT MATCHED THEN
  INSERT (
    entity,
    file_path,
    source_name,
    file_size,
    modified_datetime,
    first_ingested_datetime,
    last_ingested_datetime,
    last_status,
    exec_date,
    ingestion_mode,
    total_source_files,
    total_candidate_files
  )
  VALUES (
    src.entity,
    src.file_path,
    src.source_name,
    src.file_size,
    src.modified_datetime,
    src.first_ingested_datetime,
    src.last_ingested_datetime,
    src.last_status,
    src.exec_date,
    src.ingestion_mode,
    src.total_source_files,
    src.total_candidate_files
  );
"""

print("Exécution du MERGE dans tech_ingestion_manifest...")
spark.sql(merge_sql)
print("MERGE terminé.")


# In[ ]:


# ============================================================
# Cellule 6 — Retour structuré au pipeline
# ------------------------------------------------------------
# Cette cellule n’est pas obligatoire pour le fonctionnement
# du pipeline, mais elle est fortement recommandée :
#
# ✔ Permet de visualiser, dans l'Output de l’activité Notebook,
#   les informations clés sur le fichier traité.
# ✔ Facilite énormément le debug lors du développement,
#   du run initial et des tests incrémentaux.
# ✔ Permet au pipeline parent (si Invoke Pipeline) d’exploiter
#   les valeurs renvoyées (optionnel).
#
# Le résultat est sérialisé en JSON via mssparkutils.notebook.exit
# (API Fabric-compatible), puis stocké dans les logs du pipeline.
# ============================================================

import json

result = {
    "entity": entity,
    "file_path": file_path,
    "source_name": source_name,
    "status": status,
    "ingestion_mode": ingestion_mode,
    "total_source_files": total_source_files_int,
    "total_candidate_files": total_candidate_files_int,
    "last_ingested_timestamp": str(datetime.now())
}

print("== Résultat renvoyé au pipeline ==")
print(json.dumps(result, indent=2))

# Envoi au pipeline (visible dans l’Output de l’activité Notebook)
mssparkutils.notebook.exit(json.dumps(result))

