# Bronze Layer — Data Dictionary  
**Wealth Management Analytics Platform — Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## Overview

This document provides a **professional-grade Bronze Layer Data Dictionary** for the Wealth Management Analytics Platform.  
It describes the **schema, field definitions, data types, and business meaning** of every Bronze table produced by the ingestion framework.

It reflects the final architecture implemented through:

- the unified ingestion pipeline `pl_ingest_generic`  
- entity-specific transformation functions in `nb_load_generic_bronze`  
- strict schema enforcement (no schema drift, no mergeSchema)  
- standardized technical metadata (`source_file`, `ingestion_date`, `ingestion_ts`, `entity`)  

No DDL statements are included here — these will be delivered in a separate technical document.

---

# 1. Shared Technical Columns (All Bronze Tables)

Every Bronze table includes the following metadata fields:

| Column | Type | Description |
|--------|-------|-------------|
| **source_file** | STRING | Full path or filename of the ingested file. Ensures traceability and governance. |
| **ingestion_date** | DATE | Logical ingestion date (UTC or pipeline execution date). |
| **ingestion_ts** | TIMESTAMP | Exact timestamp when the record was processed. |
| **entity** | STRING | Entity identifier (FX, CUSTOMER, STOCK, ETF, USER, etc.). |

These fields apply to all tables and will not be repeated for each entity.

---

# 2. bronze_fx_raw  
**Foreign exchange reference rates since 2004**

| Column | Type | Description |
|--------|-------|-------------|
| date | DATE | FX rate date. |
| currency | STRING | Currency code (e.g., USD, EUR, GBP). Uppercased for consistency. |
| rate | DOUBLE | FX rate value vs. base currency (often USD). |
| rate_type | STRING | Optional rate category (spot, mid, etc.) depending on dataset. |

---

# 3. bronze_customer_raw  
**Customer demographic and banking attributes**

| Column | Type | Description |
|--------|-------|-------------|
| row_number | BIGINT | Unique row identifier from source. |
| customer_id | BIGINT | Unique customer ID. |
| surname | STRING | Customer surname (cleaned, trimmed). |
| credit_score | INT | Customer credit risk score. |
| geography | STRING | Customer region/country (UPPER/TRIM). |
| gender | STRING | Gender code. |
| age | INT | Customer age. |
| tenure | INT | Years with the bank. |
| balance | DOUBLE | Current account balance. |
| num_of_products | INT | Number of bank products held. |
| has_cr_card | STRING | “YES/NO” flag: owns a credit card. |
| is_active_member | STRING | “YES/NO” customer activity flag. |
| estimated_salary | DOUBLE | Customer annual income estimate. |

---

# 4. bronze_stock_raw  
**Daily OHLCV for listed stocks**

| Column | Type | Description |
|--------|-------|-------------|
| ticker | STRING | Stock symbol extracted from source. |
| date | DATE | Trading day. |
| open | DOUBLE | Opening price. |
| high | DOUBLE | Highest price of the day. |
| low | DOUBLE | Lowest price of the day. |
| close | DOUBLE | Closing price. |
| volume | BIGINT | Trading volume. |
| open_int | BIGINT | Open interest (if provided). |

---

# 5. bronze_etf_raw  
**Daily OHLCV for Exchange-Traded Funds**

Schema identical to stocks:

| Column | Type | Description |
|--------|-------|-------------|
| ticker | STRING | ETF symbol. |
| date | DATE | Trading day. |
| open | DOUBLE | Opening NAV/price. |
| high | DOUBLE | Daily high. |
| low | DOUBLE | Daily low. |
| close | DOUBLE | Closing NAV/price. |
| volume | BIGINT | Daily volume. |
| open_int | BIGINT | Open interest (if available). |

---

# 6. bronze_card_raw  
**Customer card metadata (fraud detection, limits, attributes)**

| Column | Type | Description |
|--------|-------|-------------|
| id | BIGINT | Card record ID. |
| client_id | BIGINT | Reference to customer entity. |
| card_brand | STRING | Brand (VISA, MASTERCARD…). |
| card_type | STRING | Type (CREDIT, DEBIT…). |
| card_number | STRING | Masked or anonymized number. |
| cvv | STRING | Masked CVV representation. |
| expires | STRING | Expiry date (cleaned but not transformed to DATE in Bronze). |
| acct_open_date | STRING | Date when card account was opened (raw form). |
| has_chip | STRING | “YES/NO” device capability flag. |
| card_on_dark_web | STRING | “YES/NO”: exposure indicator. |
| num_cards_issued | INT | Total number of cards issued to the client. |
| year_pin_last_changed | INT | Year of last PIN update. |
| credit_limit | DOUBLE | Card limit (monetary). |

---

# 7. bronze_user_raw  
**Demographic, geographic, and financial user-level data**

| Column | Type | Description |
|--------|-------|-------------|
| id | BIGINT | User identifier. |
| current_age | INT | Age today. |
| retirement_age | INT | Projected retirement age. |
| birth_year | INT | Year of birth. |
| birth_month | INT | Month of birth. |
| gender | STRING | Gender category (UPPER/TRIM). |
| address | STRING | User address (trimmed). |
| latitude | DOUBLE | Geolocation latitude. |
| longitude | DOUBLE | Geolocation longitude. |
| per_capita_income | DOUBLE | Average income of the user’s region. |
| yearly_income | DOUBLE | User annual salary (cleaned). |
| total_debt | DOUBLE | Total outstanding debts. |
| credit_score | INT | Credit scoring metric. |
| num_credit_cards | INT | Number of cards owned. |

---

# 8. bronze_mcc_raw  
**Merchant Category Codes (MCC) metadata**

| Column | Type | Description |
|--------|-------|-------------|
| mcc | STRING | Merchant Category Code (ISO standard). |
| mcc_description | STRING | Textual description of the merchant category. |
| category | STRING | Aggregated group/category. |
| subcategory | STRING | Sub-classification of merchant type. |
| risk_level | STRING | Risk classification (if provided in dataset). |

(Exact fields may vary depending on MCC dataset; schema aligned to ingestion normalization.)

---

# 9. bronze_transaction_raw  
**Customer transaction data (cards, users, MCC enrichment at later stages)**

| Column | Type | Description |
|--------|-------|-------------|
| transaction_id | STRING | Unique transaction identifier. |
| user_id | BIGINT | Reference to user. |
| card_id | BIGINT | Reference to card. |
| transaction_date | DATE | Transaction date. |
| amount | DOUBLE | Monetary amount (cleaned). |
| currency | STRING | Original transaction currency. |
| mcc | STRING | Merchant category code. |
| merchant | STRING | Merchant name (cleaned). |
| city | STRING | City of transaction. |
| state | STRING | State/region. |
| country | STRING | Country code. |
| entry_mode | STRING | How payment was processed (CHIP, CONTACTLESS…). |
| fraud_flag | STRING | “YES/NO” indicator for potential fraud cases. |

---

# 10. bronze_securities_raw  
**Reference dataset for financial instruments (equities, ETFs, bonds, etc.)**

| Column | Type | Description |
|--------|-------|-------------|
| ticker | STRING | Unique instrument symbol. |
| name | STRING | Security name. |
| exchange | STRING | Listing exchange. |
| asset_class | STRING | Asset category (EQUITY, ETF, BOND…). |
| sector | STRING | Sector classification. |
| industry | STRING | Industry group. |
| country | STRING | Country of listing or incorporation. |

---

# 11. bronze_fundamentals_raw  
**Financial fundamentals for listed companies**

| Column | Type | Description |
|--------|-------|-------------|
| ticker | STRING | Reference to stock symbol. |
| period | STRING | Period or quarter. |
| revenue | DOUBLE | Company revenue. |
| earnings | DOUBLE | Net income / earnings. |
| eps | DOUBLE | Earnings per share. |
| book_value | DOUBLE | Book value per share. |
| market_cap | DOUBLE | Market capitalization. |
| pe_ratio | DOUBLE | Price/Earnings ratio. |

---

# 12. bronze_prices_raw  
**Historical prices (non-adjusted)**

| Column | Type | Description |
|--------|-------|-------------|
| ticker | STRING | Asset symbol. |
| date | DATE | Trading date. |
| open | DOUBLE | Opening price. |
| high | DOUBLE | Daily high. |
| low | DOUBLE | Daily low. |
| close | DOUBLE | Daily close. |
| volume | BIGINT | Trading volume. |

---

# 13. bronze_prices_split_adjusted_raw  
**Historical prices adjusted for splits, dividends, or corporate events**

| Column | Type | Description |
|--------|-------|-------------|
| ticker | STRING | Asset symbol. |
| date | DATE | Trading date. |
| open | DOUBLE | Adjusted open. |
| high | DOUBLE | Adjusted high. |
| low | DOUBLE | Adjusted low. |
| close | DOUBLE | Adjusted close. |
| volume | BIGINT | Adjusted volume (if applicable). |

---

# 14. Notes on Schema Governance

### Strict schema enforcement
All schemas are enforced in the notebook and strictly aligned to the managed Bronze Delta tables.

### No automatic merging
`mergeSchema` is explicitly not used to avoid unintended schema drift — a critical constraint in financial-grade data environments.

### Deterministic transformations
Every entity transformation ends with a **strict final SELECT**, ensuring:

- reproducibility  
- schema stability  
- operational safety across environments  

### Extensibility
Adding a new dataset requires:

1. A loader function in the notebook  
2. Updating the entity dispatcher  
3. Creating a corresponding Bronze table  

No changes to pipeline logic are required.

---

# 15. Conclusion

This Bronze Data Dictionary formally defines the schemas used in the ingestion layer of the Wealth Management Analytics Platform.  
It ensures clarity, traceability, and consistency across all datasets and supports downstream Silver and Gold modeling activities.

This document represents a **banking-grade, audit-ready data contract** for the entire Bronze architecture.

