# Bronze Layer — Notebook Documentation  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

This document provides a detailed technical description of the **Bronze ingestion notebooks** used in the Wealth Management Analytics Platform, specifically:

- `nb_load_generic_bronze` — the unified transformation notebook  
- `nb_log_ingestion` — the run-level logging notebook  

These notebooks form the core of the Bronze ingestion workflow, providing schema standardization, entity-specific transformations, technical metadata injection, and run-level governance logging.

The design follows **banking-grade engineering** principles: deterministic transformations, strict schema control, full lineage, and reproducible ingestion.

---

# 2. nb_load_generic_bronze — Unified Transformation Notebook

`nb_load_generic_bronze` is the central notebook responsible for transforming raw files into structured Bronze Delta tables. It supports all entities through a modular, parameterized, and auditable design.

---

## 2.1 Notebook Parameters (Fabric-Compliant Parameter Cells)

The notebook expects the following parameters, injected from the pipeline:

| Parameter | Description |
|-----------|-------------|
| `entity` | Entity identifier (FX, CUSTOMER, STOCK, ETF, USER, CARD, MCC, TRANSACTION…). |
| `input_path` | Full OneLake path to the file in the Landing zone. |
| `exec_date` | Logical ingestion date. |
| `source_file` | Original filename or URI. |

These parameters ensure full decoupling from pipeline logic and are mandatory for reproducibility and lineage.

---

## 2.2 High-Level Processing Flow

The notebook performs the following sequence:

1. **Read raw file from Landing**  
2. **Normalize column names** to snake_case (`normalize_columns()`)  
3. **Entity dispatch** to the correct transformation function  
4. **Apply entity-specific cleaning, typing, and selection**  
5. **Add technical metadata columns**  
6. **Write to target Bronze Delta table** using append mode  

The notebook is explicitly bound to the **Lakehouse (`lh_wm_core`)**, ensuring managed Delta tables are accessible.

---

# 3. Normalization Framework

## 3.1 Column Normalization (snake_case)

A helper function enforces consistent naming across all entities by:

- converting CamelCase → snake_case  
- trimming spaces  
- removing illegal characters  
- aligning all datasets to a unified naming standard  

This creates predictability for downstream layers (Silver, Gold, Warehouse).

---

## 3.2 Standard Metadata Columns

After entity transformation, the notebook adds four mandatory metadata fields:

| Column | Description |
|--------|-------------|
| `source_file` | Captures the original file name for auditability. |
| `ingestion_date` | Contains the pipeline execution date. |
| `ingestion_ts` | High-precision timestamp of ingestion. |
| `entity` | Identifier for the dataset ingested. |

These fields apply to every Bronze table and ensure audit readiness.

---

# 4. Entity Dispatcher Architecture

The notebook contains a **dispatcher** that routes transformation based on the `entity` parameter:

if entity_upper == "FX":
df_core = transform_fx(df_raw)

elif entity_upper == "CUSTOMER":
df_core = transform_customer(df_raw)

elif entity_upper == "STOCK":
df_core = load_stock(df_raw)

elif entity_upper == "ETF":
df_core = load_etf(df_raw)

elif entity_upper == "CARD":
df_core = load_cards(df_raw)

elif entity_upper == "USER":
df_core = load_users(df_raw)

elif entity_upper == "MCC":
df_core = load_mcc(df_raw)

elif entity_upper == "TRANSACTION":
df_core = load_transactions(df_raw)

elif entity_upper == "SECURITIES":
df_core = load_securities(df_raw)

elif entity_upper == "FUNDAMENTALS":
df_core = load_fundamentals(df_raw)

elif entity_upper == "PRICES":
df_core = load_prices(df_raw)

elif entity_upper == "PRICES_SPLIT_ADJUSTED":
df_core = load_prices_split_adjusted(df_raw)


This pattern provides:

- clean modularity  
- easy extensibility  
- strict isolation of transformation logic per entity  

Adding a new dataset requires only a new function + dispatcher entry.

---

# 5. Entity-Specific Transformation Modules

Each module follows a strict structure:

1. Input: Raw DataFrame  
2. Column normalization  
3. Type casting (dates, doubles, ints, flags)  
4. Text cleanup (UPPER, TRIM)  
5. Removal of irrelevant fields  
6. Strict final `select()` with exact schema  
7. Output: Clean DataFrame matching the Bronze DDL  

Below is a summary of the transformation expectations per entity.

---

## 5.1 FX — `transform_fx(df_raw)`

- Normalize currency codes  
- Convert rate fields to DOUBLE  
- Convert date to DATE  
- Ensure final shape: (date, currency, rate, rate_type?, metadata)

---

## 5.2 CUSTOMER — `transform_customer(df_raw)`

- Convert salary/balance fields to DOUBLE  
- Standardize boolean flags (`YES/NO`)  
- Clean categorical fields (gender, geography)  
- Enforce integer types for credit_score, age, tenure  
- Ensure strict final schema alignment

---

## 5.3 STOCK & ETF — `load_stock()`, `load_etf()`

- Parse ticker directly from file content  
- Parse trading date  
- Cast OHLCV fields to DOUBLE/BIGINT  
- Optional: derive missing open_int if dataset provides it  
- Final schema identical between stocks & ETFs for consistency

---

## 5.4 CARD — `load_cards()`

- Clean credit_limit using regexp_replace to strip currency symbols  
- Standardize categorical features (brand, type, chip flag)  
- Preserve masked sensitive fields (card_number, cvv)  
- Maintain raw date fields as STRING (converted later in Silver)

---

## 5.5 USER — `load_users()`

- Clean income and debt fields  
- Cast latitude/longitude to DOUBLE  
- Standardize gender and text fields  
- Select final schema only (remove any redundant raw columns)

---

## 5.6 MCC — `load_mcc()`

- Normalize MCC codes  
- Standardize risk-level categories  
- Final schema depends on dataset but must remain stable and strict

---

## 5.7 TRANSACTION — `load_transactions()`

- Convert amount to DOUBLE  
- Standardize merchant and location text fields  
- Convert transaction_date to DATE  
- Prepare foreign keys for later joins (user_id, card_id, mcc)

---

## 5.8 SECURITIES — `load_securities()`

- Enforce consistent instrument metadata schema  
- Standardize exchange, sector, industry fields  
- Ensure ticker is normalized and uppercased

---

## 5.9 FUNDAMENTALS — `load_fundamentals()`

- Clean numeric values (market_cap, eps, revenue…)  
- Convert reporting period fields  
- Maintain clear financial structure for Silver computations

---

## 5.10 PRICES & PRICES_SPLIT_ADJUSTED — `load_prices()`

- Enforce strict OHLCV schema  
- Adjusted and non-adjusted treated as separate entities  
- Guarantee alignment with Delta table structure

---

# 6. Strict Schema Enforcement

The notebook ensures **strict schema control** by:

- Avoiding dynamic schema inference  
- Never using `mergeSchema` when writing Delta  
- Applying a mandatory `select()` at the end of every transform  
- Keeping transformation functions immutable and testable  

Reasons:

- Prevent schema drift  
- Ensure stable contracts for Silver & Gold  
- Comply with financial data governance standards  

---

# 7. Writing to Bronze Tables

After transformation and metadata injection:

df_final.write.format("delta")
.mode("append")
.saveAsTable("bronze_<entity>_raw")


Requirements:

- Lakehouse binding must be active  
- Bronze table must exist with matching schema  
- Notebook retries are enabled at pipeline level  

This ensures consistent ingestion and error isolation.

---

# 8. nb_log_ingestion — Run-Level Logging Notebook

This lightweight notebook logs ingestion metrics into `tech_ingestion_log`.

## 8.1 Parameters

| Parameter | Description |
|----------|-------------|
| `entity` | Entity processed. |
| `exec_date` | Run date. |
| `total_source_files` | Count of files discovered. |
| `total_candidate_files` | Count of files selected for ingestion. |
| `processed_files` | Files processed successfully. |
| `failed_files` | Files that failed. |
| `status` | SUCCESS, PARTIAL, FAILED, NO_DATA. |

---

## 8.2 Processing Flow

1. Build a single-row DataFrame containing metrics  
2. Add `log_timestamp` with current system timestamp  
3. Append the row into the managed table `tech_ingestion_log`  

This produces an auditable run history aligned with operational best practices.

---

# 9. Extensibility of the Notebook Framework

To ingest a new dataset:

1. Add new transformation function (e.g., `load_options(df_raw)`)  
2. Add dispatcher entry in notebook  
3. Create the Bronze table in the Lakehouse  
4. Register entity in the pipeline configuration  

No changes to pipeline structure are required.

This modularity is intentional and supports enterprise-scale ingestion.

---

# 10. Conclusion

The Bronze notebooks create a **robust, auditable, and extensible ingestion foundation** for the Wealth Management Analytics Platform. Key strengths include:

- unified normalization framework  
- strict schema enforcement  
- modular entity transformations  
- technical metadata injection  
- predictable append-only behavior  
- clean integration with Fabric pipelines and Lakehouse  

This notebook architecture ensures that all Bronze datasets are **consistent, compliant, and ready for downstream Silver and Gold modeling**.

---

