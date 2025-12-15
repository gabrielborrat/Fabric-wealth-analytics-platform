#!/usr/bin/env python
# coding: utf-8

# ## nb_validate_bronze_schema_registry
# 
# null

# In[ ]:


# nb_validate_bronze_schema_registry
# Fabric Notebook (PySpark)
# Prereq: Notebook attached to Lakehouse lh_wm_core

from datetime import datetime, timezone
import json
import re

try:
    import yaml  # PyYAML
except Exception as e:
    raise ImportError("Missing dependency: PyYAML (import yaml). Please install/enable PyYAML in this Fabric environment.") from e

from pyspark.sql import Row
from pyspark.sql import functions as F
from pyspark.sql.types import (
    StructType, StructField, StringType, TimestampType
)

RUN_TS_UTC = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S%z")

# Location of the registry YAMLs in your Lakehouse Files
# Put your files under: Files/governance/schema_registry/bronze/
REGISTRY_DIR = "Files/governance/schema_registry/bronze"

# Output table (Delta) where compliance results will be appended
COMPLIANCE_TABLE = "tech_schema_compliance"

# Behavior flags
STRICT_ORDER_CHECK = True     # if True, order differences => FAIL
FAIL_ON_MISSING_TABLE = False # if True, missing table => FAIL; else status = MISSING_TABLE


# In[ ]:


def _ls(path: str):
    # Fabric notebooks typically provide mssparkutils
    try:
        return mssparkutils.fs.ls(path)
    except Exception:
        # fallback to dbutils if available
        try:
            return dbutils.fs.ls(path)
        except Exception as e:
            raise RuntimeError(f"Unable to list files at {path}. Ensure the path exists in Lakehouse Files.") from e

def _read_text(path: str) -> str:
    # mssparkutils.fs.head is convenient for small YAML files
    try:
        return mssparkutils.fs.head(path, 1024 * 1024)  # 1MB
    except Exception:
        try:
            return dbutils.fs.head(path, 1024 * 1024)
        except Exception as e:
            raise RuntimeError(f"Unable to read file: {path}") from e

def list_yaml_files(registry_dir: str):
    files = _ls(registry_dir)
    yaml_paths = []
    for f in files:
        p = f.path if hasattr(f, "path") else f[0]
        if p.lower().endswith(".yaml") and not p.lower().endswith("_template.yaml") and not p.lower().endswith("_registry_index.yaml"):
            yaml_paths.append(p)
    return sorted(yaml_paths)

yaml_files = list_yaml_files(REGISTRY_DIR)
print(f"Found {len(yaml_files)} registry YAML files:")
for p in yaml_files:
    print(" -", p)


# In[ ]:


def canonical_type(t: str) -> str:
    """Normalize types to a common uppercase vocabulary."""
    if t is None:
        return "UNKNOWN"
    t = t.strip().lower()
    mapping = {
        "string": "STRING",
        "varchar": "STRING",
        "char": "STRING",
        "int": "INT",
        "integer": "INT",
        "bigint": "BIGINT",
        "long": "BIGINT",
        "double": "DOUBLE",
        "float": "DOUBLE",
        "decimal": "DECIMAL",
        "timestamp": "TIMESTAMP",
        "date": "DATE",
        "boolean": "BOOLEAN",
        "bool": "BOOLEAN",
    }
    # Keep parametric types reasonably (e.g. decimal(10,2))
    if t.startswith("decimal"):
        return "DECIMAL"
    return mapping.get(t, t.upper())

def spark_field_type_to_registry(ftype) -> str:
    """Convert Spark data type to registry canonical type."""
    # ftype.simpleString() yields e.g. 'bigint', 'string', 'timestamp', 'date'
    return canonical_type(ftype.simpleString())

def load_registry_yaml(path: str) -> dict:
    raw = _read_text(path)
    doc = yaml.safe_load(raw)

    # Basic validation
    required_keys = ["entity", "table_name", "business_columns", "technical_columns"]
    for k in required_keys:
        if k not in doc:
            raise ValueError(f"Registry file {path} missing required key: {k}")

    # Flatten expected columns in order
    expected_cols = []
    for col in doc["business_columns"] + doc["technical_columns"]:
        expected_cols.append({
            "name": col["name"],
            "type": canonical_type(col["type"]),
            "nullable": bool(col.get("nullable", True))
        })

    return {
        "registry_path": path,
        "entity": doc["entity"],
        "table_name": doc["table_name"],
        "layer": doc.get("layer", "BRONZE"),
        "status_declared": doc.get("status", "UNKNOWN"),
        "expected_columns": expected_cols,
        "constraints": doc.get("constraints", {})
    }

def get_live_table_schema(table_name: str):
    """Return live table schema columns in order as list of dicts."""
    df = spark.table(table_name)
    live = []
    for f in df.schema.fields:
        live.append({
            "name": f.name,
            "type": canonical_type(spark_field_type_to_registry(f.dataType)),
            "nullable": bool(f.nullable)
        })
    return live

def compare_expected_vs_live(expected, live, strict_order=True):
    exp_names = [c["name"] for c in expected]
    live_names = [c["name"] for c in live]

    exp_set = set(exp_names)
    live_set = set(live_names)

    missing = [c for c in exp_names if c not in live_set]
    extra = [c for c in live_names if c not in exp_set]

    # Type mismatches on intersection
    exp_map = {c["name"]: c["type"] for c in expected}
    live_map = {c["name"]: c["type"] for c in live}

    type_mismatches = []
    for name in sorted(exp_set.intersection(live_set)):
        if exp_map[name] != live_map[name]:
            type_mismatches.append({"column": name, "expected": exp_map[name], "actual": live_map[name]})

    # Order check (only for common columns)
    order_mismatch = False
    order_details = None
    if strict_order:
        # Compare full ordered lists (names only)
        order_mismatch = (exp_names != live_names)
        if order_mismatch:
            order_details = {
                "expected_order": exp_names,
                "actual_order": live_names
            }

    # Determine status
    if missing or extra or type_mismatches or (strict_order and order_mismatch):
        status = "FAIL"
    else:
        status = "PASS"

    return {
        "status": status,
        "missing_columns": missing,
        "extra_columns": extra,
        "type_mismatches": type_mismatches,
        "order_mismatch": order_mismatch,
        "order_details": order_details
    }


# In[ ]:


results = []

for ypath in yaml_files:
    reg = load_registry_yaml(ypath)
    entity = reg["entity"]
    table_name = reg["table_name"]

    # In Fabric, Lakehouse tables are usually addressable without db prefix.
    # If you prefer fully qualified: f"lh_wm_core.{table_name}"
    table_ref = table_name

    try:
        live_cols = get_live_table_schema(table_ref)
        comparison = compare_expected_vs_live(reg["expected_columns"], live_cols, strict_order=STRICT_ORDER_CHECK)

        results.append({
            "run_ts_utc": RUN_TS_UTC,
            "layer": reg["layer"],
            "entity": entity,
            "table_name": table_name,
            "registry_path": reg["registry_path"],
            "registry_status": reg["status_declared"],
            "compliance_status": comparison["status"],
            "missing_columns": json.dumps(comparison["missing_columns"]),
            "extra_columns": json.dumps(comparison["extra_columns"]),
            "type_mismatches": json.dumps(comparison["type_mismatches"]),
            "order_mismatch": str(comparison["order_mismatch"]),
            "order_details": json.dumps(comparison["order_details"]) if comparison["order_details"] else None
        })

    except Exception as e:
        # Missing table, permission, etc.
        status = "MISSING_TABLE" if not FAIL_ON_MISSING_TABLE else "FAIL"
        results.append({
            "run_ts_utc": RUN_TS_UTC,
            "layer": reg["layer"],
            "entity": entity,
            "table_name": table_name,
            "registry_path": reg["registry_path"],
            "registry_status": reg["status_declared"],
            "compliance_status": status,
            "missing_columns": json.dumps([]),
            "extra_columns": json.dumps([]),
            "type_mismatches": json.dumps([]),
            "order_mismatch": "false",
            "order_details": None
        })
        print(f"[WARN] {entity} ({table_name}) validation error: {e}")

schema = StructType([
    StructField("run_ts_utc", StringType(), False),
    StructField("layer", StringType(), False),
    StructField("entity", StringType(), False),
    StructField("table_name", StringType(), False),
    StructField("registry_path", StringType(), False),
    StructField("registry_status", StringType(), True),
    StructField("compliance_status", StringType(), False),
    StructField("missing_columns", StringType(), True),
    StructField("extra_columns", StringType(), True),
    StructField("type_mismatches", StringType(), True),
    StructField("order_mismatch", StringType(), True),
    StructField("order_details", StringType(), True),
])

df_results = spark.createDataFrame([Row(**r) for r in results], schema=schema)

display(df_results.orderBy(F.col("compliance_status").desc(), F.col("entity")))


# In[ ]:


# Create table if not exists (append-only audit log of compliance runs)
spark.sql(f"""
CREATE TABLE IF NOT EXISTS {COMPLIANCE_TABLE} (
  run_ts_utc STRING,
  layer STRING,
  entity STRING,
  table_name STRING,
  registry_path STRING,
  registry_status STRING,
  compliance_status STRING,
  missing_columns STRING,
  extra_columns STRING,
  type_mismatches STRING,
  order_mismatch STRING,
  order_details STRING
)
USING delta
""")

df_results.write.mode("append").saveAsTable(COMPLIANCE_TABLE)

print(f"Appended {df_results.count()} rows to {COMPLIANCE_TABLE}.")


# In[ ]:


summary = (
    df_results
    .groupBy("compliance_status")
    .count()
    .orderBy(F.desc("count"))
)

display(summary)

