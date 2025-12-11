#!/usr/bin/env python
# coding: utf-8

# ## nb_prepare_incremental_list
# 
# null

# In[ ]:


# PARAMETER_CELL
# Ces variables seront alimentées par l'activité Notebook dans le pipeline Fabric

entity = "FX"              # ex : "FX", "CUSTOMER"
ingestion_mode = "INCR"    # "INCR" ou "FULL"
source_path = ""           # ex : "FX-rates-since2004-dataset/" ou "customers/"
all_files_json = "[]"      # sortie de GetMetadata.childItems en JSON (string)


# In[ ]:


import json
from pyspark.sql import functions as F
from pyspark.sql.utils import AnalysisException
from notebookutils import mssparkutils

print("== nb_prepare_incremental_list v2 ==")
print(f"entity         = {entity}")
print(f"ingestion_mode = {ingestion_mode}")
print(f"source_path    = {source_path}")
print(f"all_files_json (raw, 500 chars max) = {all_files_json[:500]}")

# 1) Parsing brut
try:
    parsed = json.loads(all_files_json)
except Exception as e:
    print("ERREUR : impossible de parser all_files_json → on considère qu'il n'y a aucun fichier.")
    print(str(e))
    mssparkutils.notebook.exit("[]")

files_list = None

# 2) Plusieurs cas possibles selon la forme de l'output GetMetadata + @string()

# Cas standard : c'est déjà une liste de fichiers
if isinstance(parsed, list):
    files_list = parsed

# Cas : c'est un dict qui contient une liste
elif isinstance(parsed, dict):
    # on essaie plusieurs clés possibles, au cas où
    for key in ["childItems", "value", "items"]:
        if key in parsed and isinstance(parsed[key], list):
            files_list = parsed[key]
            print(f"files_list récupéré depuis parsed['{key}']")
            break

# Si après tout ça, on n'a toujours rien → liste vide
if files_list is None:
    print("Aucune liste de fichiers détectée dans all_files_json → files_list = [].")
    files_list = []

print(f"Nombre de fichiers trouvés côté source (files_list) : {len(files_list)}")

if len(files_list) == 0:
    # Rien à traiter → renvoyer une liste vide au pipeline
    mssparkutils.notebook.exit("[]")


# In[ ]:


# Cellule 3 : création du DataFrame des fichiers source

# On crée un DataFrame à partir de la liste de dicts (name, type, size, lastModified…)
df_files = spark.createDataFrame(files_list)

if "name" not in df_files.columns:
    print("ERREUR : la structure des fichiers ne contient pas de colonne 'name'.")
    df_files.printSchema()
    mssparkutils.notebook.exit("[]")

# Ajout du file_path logique (clé utilisée dans le manifest)
df_files = df_files.withColumn(
    "file_path",
    F.concat(F.lit(source_path), F.col("name"))
)

print("Schéma df_files :")
df_files.printSchema()
display(df_files.limit(10))


# In[ ]:


# Cellule 4 : lecture du manifest (tech_ingestion_manifest) si disponible

has_manifest = False

try:
    df_manifest = (
        spark.table("tech_ingestion_manifest")
             .filter(F.col("entity") == entity)
             .select("file_path", "last_status", "modified_datetime")
    )
    has_manifest = True
    nb_manifest = df_manifest.count()
    print(f"Table tech_ingestion_manifest trouvée pour entity='{entity}', lignes = {nb_manifest}")
except AnalysisException:
    print("Table tech_ingestion_manifest introuvable → aucun filtrage incrémental possible (tout sera nouveau).")
    has_manifest = False

# Logique FULL / INCR
ing_mode = (ingestion_mode or "INCR").upper()

if ing_mode == "FULL":
    print("Mode FULL : tous les fichiers source seront traités.")
    df_to_process = df_files

elif ing_mode == "INCR" and has_manifest:
    print("Mode INCR avec manifest disponible → left_anti join sur file_path")
    # On enlève les fichiers déjà présents dans le manifest pour cette entity
    df_to_process = df_files.join(
        df_manifest.select("file_path"),
        on="file_path",
        how="left_anti"
    )

else:
    # Mode INCR mais pas de manifest pour cette entity → tout est nouveau
    print("Mode INCR mais manifest absent ou vide pour cette entity → tous les fichiers sont considérés comme nouveaux.")
    df_to_process = df_files

count_to_process = df_to_process.count()
print(f"Nombre de fichiers à traiter (après filtrage incrémental) : {count_to_process}")

if count_to_process == 0:
    print("Aucun fichier à traiter après filtrage → on renvoie [].")
    mssparkutils.notebook.exit("[]")



# In[ ]:


# On ne renvoie que les colonnes nécessaires au pipeline (name + file_path)
df_result = df_to_process.select("name", "file_path")

rows = df_result.collect()
result_list = [{"name": r["name"], "file_path": r["file_path"]} for r in rows]

print("Aperçu de result_list :")
print(result_list[:5])

result_json = json.dumps(result_list)

# Très important : on renvoie une STRING JSON
# qui sera lue côté pipeline via :
# @json(activity('Prepare_Incremental_List').output.result.exitValue)
mssparkutils.notebook.exit(result_json)

