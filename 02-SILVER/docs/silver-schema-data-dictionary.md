# Silver Layer — Data Dictionary  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## Overview

This document provides a **professional-grade Silver Layer Data Dictionary** for the Wealth Management Analytics Platform.  
It describes the **schema, field definitions, data types, and business meaning** of every Silver table produced by the transformation framework.

It reflects the final architecture implemented through:

- the unified transformation pipeline `pl_silver_load_generic`  
- entity-specific transformation notebooks (`nb_silver_fx`, `nb_silver_users`, etc.)  
- strict schema enforcement (no schema drift, no mergeSchema)  
- standardized technical metadata (`source_file`, `ingestion_date`, `ingestion_ts`, `record_hash`)  
- deduplication based on natural keys  
- strategic partitioning for query performance  

No DDL statements are included here — these will be delivered in a separate technical document.

---

## 1. Shared Technical Columns (All Silver Tables)

Every Silver table includes the following metadata fields:

| Column | Type | Description |
|--------|-------|-------------|
| **source_file** | STRING | Full path or filename of the source Bronze file. Ensures traceability and governance. |
| **ingestion_date** | DATE | Logical processing date (UTC or pipeline execution date). |
| **ingestion_ts** | TIMESTAMP | Exact timestamp when the record was processed in Silver layer. |
| **record_hash** | STRING | SHA-256 hash of key business attributes. Used for change detection and auditability. |

These fields apply to all tables and will not be repeated for each entity.

---

## 2. silver_fx_rates  
**Daily foreign exchange rates (USD-based) cleaned, typed, deduplicated and partitioned monthly for analytics.**

| Column | Type | Description |
|--------|-------|-------------|
| **base_currency** | STRING | Base currency code (standardized to 'USD'). NOT NULL. |
| **currency** | STRING | Target currency code (ISO format, uppercased). NOT NULL. |
| **currency_name** | STRING | Full currency name. |
| **fx_date** | DATE | Exchange rate date. NOT NULL. |
| **fx_month** | DATE | First day of transaction month (YYYY-MM-01), used for partitioning. NOT NULL. |
| **rate_vs_usd** | DECIMAL(18,8) | Exchange rate versus USD. High precision for financial calculations. NOT NULL. |

**Natural Key:** (base_currency, currency, fx_date)  
**Partitioning:** `fx_month` (monthly)  
**Deduplication:** Latest record per natural key based on `ingestion_ts`

---

## 3. silver_users  
**User demographic and financial profile data cleaned, typed, and deduplicated for analytical joins.**

| Column | Type | Description |
|--------|-------|-------------|
| **client_id** | BIGINT | Unique client identifier. Primary key for joins with transactions and cards. NOT NULL. |
| **current_age** | INT | User current age. |
| **retirement_age** | INT | Planned retirement age. |
| **birth_year** | INT | Year of birth. |
| **birth_month** | INT | Month of birth (1-12). |
| **gender** | STRING | User gender (standardized, uppercased). |
| **address** | STRING | Residential address. |
| **latitude** | DECIMAL(9,6) | Latitude of residence (precision for geospatial analysis). |
| **longitude** | DECIMAL(9,6) | Longitude of residence (precision for geospatial analysis). |
| **per_capita_income** | DECIMAL(18,2) | Per-capita income in original currency. |
| **yearly_income** | DECIMAL(18,2) | Annual income in original currency. |
| **total_debt** | DECIMAL(18,2) | Total outstanding debt. |
| **credit_score** | INT | Credit score value. |
| **num_credit_cards** | INT | Number of credit cards owned. |

**Natural Key:** `client_id`  
**Partitioning:** None (reference data)  
**Deduplication:** Latest record per `client_id` based on `ingestion_ts`

---

## 4. silver_cards  
**Payment card reference data cleaned, typed, and deduplicated for analytical joins.**

| Column | Type | Description |
|--------|-------|-------------|
| **card_id** | BIGINT | Unique card identifier. Primary key. NOT NULL. |
| **client_id** | BIGINT | Customer identifier associated with the card. Foreign key to silver_users. |
| **card_brand** | STRING | Card brand (e.g., VISA, MASTERCARD). |
| **card_type** | STRING | Card type (DEBIT, CREDIT). |
| **card_number** | STRING | Card number as provided by source (may be masked). |
| **expires_raw** | STRING | Card expiration date (raw string format). |
| **expires_month** | DATE | Card expiration month (first day of month, DATE type). |
| **cvv** | STRING | Card CVV code (raw, may be masked). |
| **has_chip** | BOOLEAN | Chip availability indicator (converted from YES/NO string). |
| **num_cards_issued** | INT | Number of cards issued to the customer. |
| **credit_limit** | DECIMAL(18,2) | Credit limit associated with the card. |
| **acct_open_date** | DATE | Account opening date (converted from string). |
| **year_pin_last_changed** | INT | Year when the PIN was last changed. |
| **card_on_dark_web** | BOOLEAN | Indicator if card appears on dark web (converted from YES/NO string). |

**Natural Key:** `card_id`  
**Partitioning:** None (reference data)  
**Deduplication:** Latest record per `card_id` based on `ingestion_ts`

---

## 5. silver_mcc  
**Merchant Category Code reference data cleaned, normalized, and deduplicated for analytical joins.**

| Column | Type | Description |
|--------|-------|-------------|
| **mcc_code** | STRING | Merchant Category Code (4 characters, zero-padded). NOT NULL. |
| **mcc_description** | STRING | Merchant category description (standardized, uppercased). |

**Natural Key:** `mcc_code`  
**Partitioning:** None (reference data)  
**Deduplication:** Latest record per `mcc_code` based on `ingestion_ts`

**Note:** MCC codes are normalized to 4 digits with leading zeros (e.g., "123" becomes "0123") to ensure consistent formatting for joins.

---

## 6. silver_transactions  
**Card transaction events cleaned, typed, deduplicated, and partitioned monthly for analytics.**

| Column | Type | Description |
|--------|-------|-------------|
| **transaction_id** | BIGINT | Unique transaction identifier from source system. Primary key. NOT NULL. |
| **txn_ts** | TIMESTAMP | Transaction timestamp (event time). NOT NULL. |
| **txn_date** | DATE | Transaction calendar date derived from txn_ts. NOT NULL. |
| **txn_month** | DATE | First day of transaction month (YYYY-MM-01), used for partitioning. NOT NULL. |
| **client_id** | BIGINT | Client identifier. Foreign key to silver_users. NOT NULL. |
| **card_id** | BIGINT | Card identifier used for the transaction. Foreign key to silver_cards. NOT NULL. |
| **merchant_id** | BIGINT | Merchant identifier. NOT NULL. |
| **mcc_code** | STRING | Normalized Merchant Category Code (4 characters, zero-padded). Foreign key to silver_mcc. NOT NULL. |
| **amount** | DECIMAL(18,2) | Transaction amount in original currency. NOT NULL. |
| **use_chip** | STRING | Indicates if chip was used during transaction (e.g., Swipe, Online). |
| **merchant_city** | STRING | Merchant city. |
| **merchant_state** | STRING | Merchant state or region. |
| **zip** | STRING | Merchant postal code (converted to STRING for consistency). |
| **error_code** | INT | Transaction error code (0 = success, non-zero = error). NOT NULL. |
| **is_success** | BOOLEAN | Derived flag indicating successful transaction (error_code == 0). NOT NULL. |

**Natural Key:** `transaction_id`  
**Partitioning:** `txn_month` (monthly)  
**Deduplication:** Latest record per `transaction_id` based on `ingestion_ts`

**Special Considerations:**
- High-volume table requiring efficient partitioning
- Partition cardinality validation (max 240 distinct months)
- Foreign key relationships to users, cards, mcc must be validated
- Time-based queries optimized through monthly partitioning

---

## 7. Notes on Schema Governance

### 7.1 Strict Schema Enforcement
All schemas are enforced in the notebooks and strictly aligned to the managed Silver Delta tables. No dynamic schema inference or mergeSchema is used.

### 7.2 No Automatic Merging
`mergeSchema` is explicitly not used to avoid unintended schema drift — a critical constraint in financial-grade data environments.

### 7.3 Deterministic Transformations
Every entity transformation ends with a **strict final SELECT**, ensuring:

- reproducibility  
- schema stability  
- operational safety across environments  

### 7.4 Data Type Precision
Financial amounts use DECIMAL types to avoid floating-point errors:
- Transaction amounts: DECIMAL(18,2)
- FX rates: DECIMAL(18,8)
- Income/debt: DECIMAL(18,2)
- Coordinates: DECIMAL(9,6)

### 7.5 Deduplication Guarantees
All Silver tables implement latest-record-wins deduplication based on natural keys, ensuring:
- Idempotent processing
- Data freshness (latest version always wins)
- No duplicate records per natural key

### 7.6 Partitioning Strategy
Time-series tables (transactions, fx_rates) are partitioned by month to optimize:
- Time-range queries
- Incremental processing
- Direct Lake Power BI performance

### 7.7 Extensibility
Adding a new dataset requires:

1. Create entity-specific transformation notebook
2. Define natural key and deduplication strategy
3. Create corresponding Silver table
4. Register schema in Schema Registry

No changes to pipeline logic are required.

---

## 8. Foreign Key Relationships

Silver tables maintain referential integrity for downstream Gold layer joins:

- `silver_transactions.client_id` → `silver_users.client_id`
- `silver_transactions.card_id` → `silver_cards.card_id`
- `silver_transactions.mcc_code` → `silver_mcc.mcc_code`
- `silver_cards.client_id` → `silver_users.client_id`

These relationships are validated during transformation and enable reliable joins in the Gold analytical layer.

---

## 9. Conclusion

This Silver Data Dictionary formally defines the schemas used in the transformation layer of the Wealth Management Analytics Platform.  
It ensures clarity, traceability, and consistency across all datasets and supports downstream Gold analytical modeling, Data Warehouse transformations, and Power BI reporting activities.

This document represents a **banking-grade, audit-ready data contract** for the entire Silver architecture.

---
