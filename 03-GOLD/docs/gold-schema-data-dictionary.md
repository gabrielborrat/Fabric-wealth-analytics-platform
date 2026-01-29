# Gold Layer — Data Dictionary  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## Overview

This document provides a **professional-grade Gold Layer Data Dictionary** for the Wealth Management Analytics Platform.  
It describes the **business-ready dimensional model** produced by Gold notebooks and pipelines.

Gold entities are aligned with the downstream warehouse model (`04-DWH/dwh-model-dll.sql`) and are designed for analytics consumption (Power BI / semantic models).

---

## 1. Shared Columns & Modeling Conventions

Gold tables follow stable modeling conventions:

- **Natural business identifiers** (e.g. `client_id`, `card_id`, `mcc_code`)
- **Record hash** fields for deterministic change detection (e.g. `record_hash`)
- **Load timestamps** for auditing (e.g. `gold_load_ts` on facts)

> Note: In the Lakehouse, entity physical names may be prefixed with `gold_` (e.g. `gold_dim_user`). In the warehouse, the equivalent tables are named without prefix (e.g. `dim_user`). The semantic meaning is identical.

---

## 2. Dimensions

### 2.1 `gold_dim_date` (Warehouse equivalent: `dim_date`)
**Calendar date dimension**

| Column | Type | Description |
|------|------|-------------|
| date_id | INT | Natural date identifier (typically \(YYYYMMDD\)). |
| full_date | DATE | Full calendar date. |
| year | INT | Calendar year. |
| quarter | INT | Calendar quarter (1–4). |
| month | INT | Calendar month (1–12). |
| week | INT | Week number (implementation-defined). |
| day_of_week | INT | Day of week (implementation-defined). |
| is_weekend | BOOLEAN | Weekend flag. |
| is_business_day | BOOLEAN | Business day flag (calendar logic). |
| record_hash | STRING | Hash of the business attributes for change detection. |

### 2.2 `gold_dim_mcc` (Warehouse equivalent: `dim_mcc`)
**Merchant Category Code dimension**

| Column | Type | Description |
|------|------|-------------|
| mcc_code | INT | Merchant category code. |
| mcc_description | STRING | MCC description / label. |
| mcc_category | STRING | MCC grouping/category (if available). |
| record_hash | STRING | Hash of the business attributes for change detection. |

### 2.3 `gold_dim_user` (Warehouse equivalent: `dim_user`)
**User / client dimension**

| Column | Type | Description |
|------|------|-------------|
| client_id | STRING | Business identifier for the client/user. |
| current_age | INT | Current age. |
| yearly_income | DECIMAL | Annual income. |
| total_debt | DECIMAL | Total outstanding debt. |
| credit_score | INT | Credit score. |
| address | STRING | Address (may be partially masked/cleaned). |
| record_hash | STRING | Hash of the business attributes for change detection. |

### 2.4 `gold_dim_card` (Warehouse equivalent: `dim_card`)
**Payment card dimension**

| Column | Type | Description |
|------|------|-------------|
| card_id | STRING | Business identifier for the card. |
| client_id | STRING | Client identifier owning the card (FK to user natural key). |
| card_brand | STRING | Card brand (VISA, MASTERCARD, ...). |
| card_type | STRING | Card type (DEBIT/CREDIT). |
| has_chip | BOOLEAN | Chip capability flag. |
| credit_limit | DECIMAL | Credit limit. |
| num_cards_issued | INT | Number of cards issued. |
| card_on_dark_web | BOOLEAN | Flag indicating whether card appears on dark web sources. |
| record_hash | STRING | Hash of the business attributes for change detection. |

---

## 3. Facts

### 3.1 `gold_fact_transactions` (Warehouse equivalent: `fact_transactions`)
**Card transactions fact table (atomic grain)**

Grain: **one row per transaction**.

Conformance:

- Must conform to `gold_dim_user`, `gold_dim_card`, `gold_dim_mcc`, `gold_dim_date`
- Orphan rows are excluded and logged as anomalies

| Column | Type | Description |
|------|------|-------------|
| transaction_id | STRING | Transaction natural identifier. |
| txn_date | DATE | Transaction date. |
| txn_month | DATE | Month bucket (first day of month). |
| client_id / user natural key | STRING | Natural user/client identifier (used for conformance). |
| card_id / card natural key | STRING | Natural card identifier (used for conformance). |
| mcc_code | INT | Merchant category code (used for conformance). |
| amount | DECIMAL | Transaction amount. |
| currency | STRING | Currency code (if available). |
| is_success | BOOLEAN | Success flag (derived from error/status fields). |
| error_code | STRING | Error code (if any). |
| is_chip_used | BOOLEAN | Chip usage flag (derived). |
| merchant_name | STRING | Merchant name. |
| merchant_city | STRING | Merchant city. |
| merchant_state | STRING | Merchant state/region. |
| merchant_zip | STRING | Merchant ZIP/postal code. |
| record_hash | STRING | Deterministic record hash for the transaction row. |
| gold_load_ts | TIMESTAMP | Gold load timestamp. |

---

## 4. Downstream Warehouse Key Mapping (Reference)

In the Fabric Data Warehouse model, dimensions typically use **surrogate keys** (e.g. `user_key`, `card_key`, `mcc_key`, `date_key`) and facts store those surrogate keys.  
Gold in the Lakehouse may store:

- either the surrogate keys (if available at Gold build time), or
- natural keys with enforced conformance, prior to warehouse key assignment

The warehouse schema reference is defined in `04-DWH/dwh-model-dll.sql`.

---

## 5. Conclusion

This Gold Data Dictionary defines the **business-ready contracts** of the Gold layer’s star schema, providing stable, conformed entities suitable for Power BI Direct Lake and enterprise analytics.

