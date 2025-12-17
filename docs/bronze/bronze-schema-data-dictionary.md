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

#2. bronze_card_raw  
**Payment card reference data**

| Column | Type | Description |
|------|------|-------------|
| id | BIGINT | Card identifier. |
| client_id | BIGINT | Customer identifier associated with the card. |
| card_brand | STRING | Card brand (e.g. VISA, MASTERCARD). |
| card_type | STRING | Card type (DEBIT, CREDIT). |
| card_number | STRING | Card number as provided by source. |
| expires | STRING | Card expiration date (raw string). |
| cvv | STRING | Card CVV code (raw). |
| has_chip | STRING | Chip availability indicator (YES/NO). |
| num_cards_issued | INT | Number of cards issued to the customer. |
| credit_limit | DOUBLE | Credit limit associated with the card. |
| acct_open_date | STRING | Account opening date (raw string). |
| year_pin_last_changed | INT | Year when the PIN was last changed. |
| card_on_dark_web | STRING | Indicator if card appears on dark web (YES/NO). |



---

#3. bronze_customers_raw  
**Retail banking customer reference data**

| Column | Type | Description |
|------|------|-------------|
| row_number | INT | Sequential row number from source file. |
| customer_id | BIGINT | Unique customer identifier. |
| surname | STRING | Customer surname. |
| credit_score | INT | Credit score value. |
| geography | STRING | Customer country or region. |
| gender | STRING | Customer gender. |
| age | INT | Customer age. |
| tenure | INT | Customer tenure in years. |
| balance | DOUBLE | Account balance. |
| num_of_products | INT | Number of products held by the customer. |
| has_cr_card | INT | Credit card ownership flag (0/1). |
| is_active_member | INT | Active member flag (0/1). |
| estimated_salary | DOUBLE | Estimated annual salary. |
| exited | INT | Customer churn indicator (0/1). |


---

#4. bronze_etf_raw  
**Exchange Traded Fund daily market prices**

| Column | Type | Description |
|------|------|-------------|
| date | DATE | Trading date. |
| open | DOUBLE | Opening price. |
| high | DOUBLE | Highest price of the day. |
| low | DOUBLE | Lowest price of the day. |
| close | DOUBLE | Closing price. |
| volume | BIGINT | Trading volume. |
| open_int | BIGINT | Open interest. |
| ticker | STRING | ETF ticker symbol. |



---

#5. bronze_fundamentals_raw  
**Company financial fundamentals (annual / periodic financial statements)**

| Column | Type | Description |
|------|------|-------------|
| unnamed_0 | INT | Technical row index from source dataset. |
| ticker_symbol | STRING | Stock ticker symbol (e.g. AAPL, MSFT). |
| period_ending | DATE | Financial reporting period end date. |
| accounts_payable | DOUBLE | Outstanding short-term obligations to suppliers. |
| accounts_receivable | DOUBLE | Outstanding customer receivables. |
| add_income | DOUBLE | Additional income not classified elsewhere. |
| after_tax_roe | DOUBLE | Return on equity after tax (%). |
| capital_expenditures | DOUBLE | Capital spending on property, plant, and equipment. |
| capital_surplus | DOUBLE | Paid-in capital in excess of par value. |
| cash_ratio | DOUBLE | Cash and equivalents divided by current liabilities. |
| cash_and_cash_equivalents | DOUBLE | Cash and highly liquid assets. |
| changes_in_inventories | DOUBLE | Period-over-period change in inventories. |
| common_stocks | DOUBLE | Value of issued common stock. |
| cost_of_revenue | DOUBLE | Direct costs attributable to revenue generation. |
| current_ratio | DOUBLE | Current assets divided by current liabilities. |
| deferred_asset_charges | DOUBLE | Deferred costs recorded as assets. |
| deferred_liability_charges | DOUBLE | Deferred obligations recognized as liabilities. |
| depreciation | DOUBLE | Depreciation expense for the period. |
| earnings_before_interest_and_tax | DOUBLE | EBIT – operating profitability metric. |
| earnings_before_tax | DOUBLE | Earnings before income taxes. |
| effect_of_exchange_rate | DOUBLE | FX impact on cash and financial positions. |
| equity_earnings_loss_unconsolidated_subsidiary | DOUBLE | Equity income/loss from unconsolidated subsidiaries. |
| fixed_assets | DOUBLE | Long-term tangible assets. |
| goodwill | DOUBLE | Intangible asset arising from acquisitions. |
| gross_margin | DOUBLE | Gross profit divided by revenue (%). |
| gross_profit | DOUBLE | Revenue minus cost of revenue. |
| income_tax | DOUBLE | Income tax expense. |
| intangible_assets | DOUBLE | Non-physical long-term assets. |
| interest_expense | DOUBLE | Interest paid on debt. |
| inventory | DOUBLE | Value of goods held for sale or production. |
| investments | DOUBLE | Long-term and short-term investments. |
| liabilities | DOUBLE | Total liabilities. |
| long_term_debt | DOUBLE | Debt obligations due beyond one year. |
| long_term_investments | DOUBLE | Investments held long term. |
| minority_interest | DOUBLE | Non-controlling interest in subsidiaries. |
| misc_stocks | DOUBLE | Miscellaneous equity instruments. |
| net_borrowings | DOUBLE | Net debt issuance or repayment. |
| net_cash_flow | DOUBLE | Net change in cash position. |
| net_cash_flow_operating | DOUBLE | Cash generated from operations. |
| net_cash_flows_financing | DOUBLE | Cash flows from financing activities. |
| net_cash_flows_investing | DOUBLE | Cash flows from investing activities. |
| net_income | DOUBLE | Net profit after all expenses. |
| net_income_adjustments | DOUBLE | Adjustments applied to net income. |
| net_income_applicable_to_common_shareholders | DOUBLE | Net income attributable to common equity holders. |
| net_income_cont_operations | DOUBLE | Net income from continuing operations. |
| net_receivables | DOUBLE | Receivables net of allowances. |
| non_recurring_items | DOUBLE | One-off or exceptional financial items. |
| operating_income | DOUBLE | Income from core business operations. |
| operating_margin | DOUBLE | Operating income divided by revenue (%). |
| other_assets | DOUBLE | Assets not classified elsewhere. |
| other_current_assets | DOUBLE | Short-term assets not otherwise categorized. |
| other_current_liabilities | DOUBLE | Short-term liabilities not otherwise categorized. |
| other_equity | DOUBLE | Equity components outside common/retained earnings. |
| other_financing_activities | DOUBLE | Miscellaneous financing cash flows. |
| other_investing_activities | DOUBLE | Miscellaneous investing cash flows. |
| other_liabilities | DOUBLE | Liabilities not classified elsewhere. |
| other_operating_activities | DOUBLE | Miscellaneous operating cash flows. |
| other_operating_items | DOUBLE | Other operating income/expenses. |
| pre_tax_margin | DOUBLE | Earnings before tax divided by revenue (%). |
| pre_tax_roe | DOUBLE | Return on equity before tax (%). |
| profit_margin | DOUBLE | Net income divided by revenue (%). |
| quick_ratio | DOUBLE | Liquid assets divided by current liabilities. |
| research_and_development | DOUBLE | R&D expenditure. |
| retained_earnings | DOUBLE | Accumulated earnings retained in the business. |
| sale_and_purchase_of_stock | DOUBLE | Equity issuance or buybacks. |
| sales_general_and_admin | DOUBLE | SG&A operating expenses. |
| short_term_debt_current_portion_of_long_term_debt | DOUBLE | Current portion of long-term debt. |
| short_term_investments | DOUBLE | Investments held for short-term liquidity. |
| total_assets | DOUBLE | Total company assets. |
| total_current_assets | DOUBLE | Assets expected to be liquidated within one year. |
| total_current_liabilities | DOUBLE | Liabilities due within one year. |
| total_equity | DOUBLE | Total shareholders’ equity. |
| total_liabilities | DOUBLE | Sum of short-term and long-term liabilities. |
| total_liabilities_and_equity | DOUBLE | Accounting balance check (assets = liabilities + equity). |
| total_revenue | DOUBLE | Total revenue for the period. |
| treasury_stock | DOUBLE | Company’s own shares repurchased and held. |
| for_year | INT | Fiscal year of the financial record. |
| earnings_per_share | DOUBLE | Net income per share. |
| estimated_shares_outstanding | DOUBLE | Estimated number of outstanding shares. |
| source_file | STRING | Source file path in landing zone. |
| ingestion_date | DATE | Date the record was ingested. |
| ingestion_ts | TIMESTAMP | Precise ingestion timestamp. |
| entity | STRING | Entity identifier (FUNDAMENTALS). |





---

#6. bronze_fx_raw  
**Foreign exchange reference rates**

| Column | Type | Description |
|------|------|-------------|
| currency | STRING | ISO currency code. |
| base_currency | STRING | Base currency for the exchange rate. |
| currency_name | STRING | Full currency name. |
| rate_vs_usd | DOUBLE | Exchange rate versus USD. |
| date | DATE | Rate date. |


---

#7. bronze_mcc_raw  
**Merchant Category Code reference data**

| Column | Type | Description |
|------|------|-------------|
| mcc | INT | Merchant Category Code. |
| mcc_description | STRING | Merchant category description. |


---

#8. bronze_prices_raw  
**Equity price time series (raw prices)**

| Column | Type | Description |
|------|------|-------------|
| date | TIMESTAMP | Price timestamp. |
| symbol | STRING | Security symbol. |
| open | DOUBLE | Opening price. |
| close | DOUBLE | Closing price. |
| low | DOUBLE | Lowest price. |
| high | DOUBLE | Highest price. |
| volume | DOUBLE | Trading volume. |


---

#9. bronze_prices_split_adjusted_raw  
**Split-adjusted equity price time series**

| Column | Type | Description |
|------|------|-------------|
| date | TIMESTAMP | Price timestamp. |
| symbol | STRING | Security symbol. |
| open | DOUBLE | Opening price (split-adjusted). |
| close | DOUBLE | Closing price (split-adjusted). |
| low | DOUBLE | Lowest price (split-adjusted). |
| high | DOUBLE | Highest price (split-adjusted). |
| volume | DOUBLE | Trading volume. |


---

#10. bronze_securities_raw  
**Security master reference data**

| Column | Type | Description |
|------|------|-------------|
| ticker_symbol | STRING | Security ticker symbol. |
| security | STRING | Security name. |
| sec_filings | STRING | SEC filings reference. |
| gics_sector | STRING | GICS sector classification. |
| gics_sub_industry | STRING | GICS sub-industry classification. |
| address_of_headquarters | STRING | Company headquarters address. |
| date_first_added | DATE | Date security was first added to the index. |
| cik | STRING | SEC Central Index Key. |

---

#11. bronze_stock_raw  
**Daily stock market prices (equities)**

| Column | Type | Description |
|------|------|-------------|
| ticker | STRING | Stock ticker symbol. |
| date | DATE | Trading date. |
| open | DOUBLE | Opening price for the trading day. |
| high | DOUBLE | Highest price during the trading day. |
| low | DOUBLE | Lowest price during the trading day. |
| close | DOUBLE | Closing price for the trading day. |
| volume | BIGINT | Number of shares traded during the day. |
| open_int | BIGINT | Open interest (if applicable, otherwise 0). |


---

#12. bronze_transaction_raw  
**Raw financial card transactions**

| Column | Type | Description |
|------|------|-------------|
| id | INT | Unique transaction identifier. |
| date | TIMESTAMP | Transaction timestamp. |
| client_id | INT | Unique client identifier. |
| card_id | INT | Card identifier used for the transaction. |
| amount | STRING | Transaction amount (raw format as received). |
| use_chip | STRING | Indicates if chip was used (e.g. Swipe, Online). |
| merchant_id | INT | Merchant identifier. |
| merchant_city | STRING | Merchant city. |
| merchant_state | STRING | Merchant state or region. |
| zip | DOUBLE | Merchant ZIP / postal code. |
| mcc | INT | Merchant Category Code (MCC). |
| errors | STRING | Error codes or flags from transaction processing. |

---

#13. bronze_user_raw  
**Raw user demographic and financial profile data**

| Column | Type | Description |
|------|------|-------------|
| id | BIGINT | Unique user identifier. |
| current_age | INT | User current age. |
| retirement_age | INT | Planned retirement age. |
| birth_year | INT | Year of birth. |
| birth_month | INT | Month of birth. |
| gender | STRING | User gender. |
| address | STRING | Residential address. |
| latitude | DOUBLE | Latitude of residence. |
| longitude | DOUBLE | Longitude of residence. |
| per_capita_income | DOUBLE | Per-capita income. |
| yearly_income | DOUBLE | Annual income. |
| total_debt | DOUBLE | Total outstanding debt. |
| credit_score | INT | Credit score. |
| num_credit_cards | INT | Number of credit cards owned. |

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

