#!/usr/bin/env python
# coding: utf-8

# ## nb_log_ingestion
# 
# null

# In[ ]:


# ============================================================
# Notebook : nb_log_ingestion (v2 – Fabric clean)
# Rôle : écrire un log "run-level" dans tech_ingestion_log
# ============================================================

# PARAMETER_CELL
# Paramètres fournis par le pipeline Fabric (Base parameters)
exec_date = ""              # ex: "2025-12-02" (format yyyy-MM-dd)
entity = ""                 # ex: "FX", "CUSTOMER"
total_files = "0"           # v_TotalFiles (source brute)
processed_files = "0"       # v_ProcessedFiles
failed_files = "0"          # v_FailedFiles
status = ""                 # SUCCESS / PARTIAL / FAILED / NO_DATA
ingestion_mode = ""       # FULL / INCR
total_candidate_files = "0" # v_TotalCandidateFiles (après filtre incrémental)



# In[1]:


# ============================================================
# Cellule 2 – Imports, log des paramètres et cast
# ============================================================
from pyspark.sql import functions as F
from pyspark.sql.types import *
from pyspark.sql.utils import AnalysisException
from notebookutils import mssparkutils
from datetime import datetime

print("== nb_log_ingestion v3 ==")
print(f"exec_date             = {exec_date}")
print(f"entity                = {entity}")
print(f"total_files (raw)     = {total_files}")
print(f"processed_files (raw) = {processed_files}")
print(f"failed_files (raw)    = {failed_files}")
print(f"status                = {status}")
print(f"ingestion_mode      = {ingestion_mode}")
print(f"total_candidate_files = {total_candidate_files}")

# Sécurisation minimale
if not entity:
    print("ERREUR : entity manquant → aucun log écrit.")
    mssparkutils.notebook.exit("NO_LOG")

if not status:
    status = "UNKNOWN"

if not ingestion_mode:
    ingestion_mode = "UNKNOWN"

# Cast des entiers
try:
    total_source_files_int = int(total_files)
except Exception:
    total_source_files_int = -1

try:
    processed_files_int = int(processed_files)
except Exception:
    processed_files_int = -1

try:
    failed_files_int = int(failed_files)
except Exception:
    failed_files_int = -1

try:
    total_candidate_files_int = int(total_candidate_files)
except Exception:
    total_candidate_files_int = -1

# Cast de la date d'exécution en vrai Date Python
try:
    exec_date_py = datetime.strptime(exec_date, "%Y-%m-%d").date()
except Exception:
    # Si problème de format, on met la date du jour
    exec_date_py = datetime.utcnow().date()



# In[ ]:


from pyspark.sql import Row

schema = StructType([
    StructField("exec_date", DateType(), False),
    StructField("entity", StringType(), False),
    StructField("ingestion_mode", StringType(), True),
    StructField("total_source_files", IntegerType(), True),
    StructField("total_candidate_files", IntegerType(), True),
    StructField("processed_files", IntegerType(), True),
    StructField("failed_files", IntegerType(), True),
    StructField("status", StringType(), True),
    StructField("log_timestamp", TimestampType(), True),
])

row = Row(
    exec_date=exec_date_py,
    entity=entity,
    ingestion_mode=ingestion_mode,
    total_source_files=total_source_files_int,
    total_candidate_files=total_candidate_files_int,
    processed_files=processed_files_int,
    failed_files=failed_files_int,
    status=status,
    log_timestamp=datetime.utcnow()
)

df_stage = spark.createDataFrame([row], schema)

print("Schéma df_stage (tech_ingestion_log) :")
df_stage.printSchema()
display(df_stage)


# In[ ]:


# ============================================================
# Cellule 4 – Création de la table tech_ingestion_log si besoin
# ============================================================

try:
    spark.table("tech_ingestion_log")
    print("Table tech_ingestion_log déjà existante.")
except AnalysisException:
    print("Table tech_ingestion_log absente, création en cours...")
    (
        df_stage.limit(0)
        .write
        .format("delta")
        .mode("overwrite")
        .saveAsTable("tech_ingestion_log")
    )
    print("Table tech_ingestion_log créée.")



# In[ ]:


# ============================================================
# Cellule 5 – Écriture append dans tech_ingestion_log
# ============================================================
(
    df_stage
    .write
    .format("delta")
    .mode("append")
    .saveAsTable("tech_ingestion_log")
)

print("Ligne de log ajoutée dans tech_ingestion_log.")



# In[ ]:


# ============================================================
# Cellule 6 – Retour structuré au pipeline (facultatif mais recommandé)
# ============================================================
import json

result = {
    "exec_date": str(exec_date_py),
    "entity": entity,
    "ingestion_mode": ingestion_mode,
    "total_source_files": total_source_files_int,
    "total_candidate_files": total_candidate_files_int,
    "processed_files": processed_files_int,
    "failed_files": failed_files_int,
    "status": status,
    "log_timestamp": datetime.utcnow().isoformat()
}

print("== Résultat renvoyé au pipeline (nb_log_ingestion v3) ==")
print(json.dumps(result, indent=2))

mssparkutils.notebook.exit(json.dumps(result))


