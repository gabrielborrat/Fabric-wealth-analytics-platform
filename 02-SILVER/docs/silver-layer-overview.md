# Silver Layer Overview  
**Wealth Management Analytics Platform – Microsoft Fabric**  
**Version:** 1.0  
**Author:** Gabriel Borrat  

---

## 1. Introduction

The Silver Layer is the **cleaned and validated data tier** of the Wealth Management Analytics Platform built on Microsoft Fabric. It transforms raw Bronze data into business-ready, deduplicated, and quality-assured datasets suitable for analytics, reporting, and downstream Gold layer modeling.

Its mission is to provide **clean, consistent, and auditable business data** by enforcing:

- Data quality validation and business rule enforcement
- Deduplication based on natural keys
- Advanced data typing and precision (DECIMAL for financial amounts)
- Derived analytical columns (date hierarchies, flags, computed metrics)
- Record-level auditability (record_hash for change detection)
- Strategic partitioning for query performance
- Full lineage preservation from Bronze

The Silver layer delivers production-grade Delta tables optimized for the Gold analytical layer, Data Warehouse transformations, and Direct Lake Power BI semantic models.

---

## 2. Objectives of the Silver Layer

The Silver Layer has five key objectives:

### 2.1 Clean and validate Bronze data
Apply business rules, data quality checks, and validation logic to ensure data integrity and consistency.

### 2.2 Enforce deduplication
Remove duplicate records based on natural keys, keeping only the most recent version per business entity.

### 2.3 Enhance data precision and typing
Upgrade data types for analytical accuracy:
- Financial amounts → DECIMAL(18,2) or DECIMAL(18,8) for rates
- Dates → Proper DATE/TIMESTAMP with timezone awareness
- Flags → BOOLEAN for logical operations
- Codes → Normalized STRING formats (e.g., MCC codes padded to 4 digits)

### 2.4 Add analytical derivations
Create business-useful derived columns:
- Date hierarchies (txn_date, txn_month, fx_date, fx_month)
- Computed flags (is_success, is_active)
- Normalized codes and identifiers
- Record hashes for change detection

### 2.5 Optimize for analytics
Implement strategic partitioning and indexing to support:
- Time-based queries (monthly partitions)
- Join performance with Gold dimensions
- Direct Lake Power BI connectivity
- Data Warehouse ETL operations

---

## 3. Architecture Summary

### 3.1 pl_silver_load_generic — Unified Transformation Pipeline

The **generic Silver pipeline** handles all entity transformations using parameters only.  
Its main execution flow:

1. SetRunId (generate unique run identifier)  
2. `nb_silver_load` (dispatcher notebook)
   - Routes to entity-specific transformation notebook
   - Executes cleaning, validation, deduplication
   - Writes to target Silver Delta table

This design ensures consistency, maintainability, and operational simplicity across all Silver entities.

---

### 3.2 pl_silver_master — Orchestration Layer

The orchestrator pipeline executes the generic pipeline sequentially across entities with dependency management:

1. **MCC** (reference data, no dependencies)
2. **Users** (depends on MCC)
3. **Cards** (depends on Users)
4. **FX Rates** (depends on Cards)
5. **Transactions** (depends on FX Rates, Cards, Users, MCC)

This ordering ensures referential integrity and enables proper foreign key relationships in downstream Gold layer.

---

### 3.3 OneLake Storage Organization

All Silver Delta tables reside in the main Lakehouse (`lh_wm_core`):

- `silver_fx_rates` (partitioned by fx_month)
- `silver_users`
- `silver_cards`
- `silver_mcc`
- `silver_transactions` (partitioned by txn_month)

Tables are managed Delta tables with:
- Strict schema enforcement (no mergeSchema)
- Partitioning for query optimization
- Full audit trail (source_file, ingestion_date, ingestion_ts, record_hash)

---

## 4. Transformation Principles

### 4.1 Entity-Specific Transformation Notebooks

Each Silver entity has a dedicated transformation notebook following a consistent pattern:

- `nb_silver_fx` → `silver_fx_rates`
- `nb_silver_users` → `silver_users`
- `nb_silver_cards` → `silver_cards`
- `nb_silver_mcc` → `silver_mcc`
- `nb_silver_transactions` → `silver_transactions`

### 4.2 Standard Transformation Pattern

Each notebook follows this sequence:

1. **Read from Bronze** (entity-specific Bronze table)
2. **Structural assertions** (validate required columns exist)
3. **Rename and normalize** (align column names, normalize codes)
4. **Type casting** (enforce DECIMAL, DATE, BOOLEAN precision)
5. **Derive analytical columns** (date hierarchies, computed flags)
6. **Add technical metadata** (source_file, ingestion_date, ingestion_ts)
7. **Generate record_hash** (SHA-256 hash of key business attributes)
8. **Deduplication** (keep latest record per natural key)
9. **Project canonical schema** (strict final SELECT)
10. **Fail-fast validation** (check partition cardinality, null constraints)
11. **Write to Silver Delta table** (append mode, with partitioning)

### 4.3 Technical Columns

Added uniformly to every Silver table:

- `source_file` — Original source file from Bronze
- `ingestion_date` — Date of ingestion
- `ingestion_ts` — Precise ingestion timestamp
- `record_hash` — SHA-256 hash of key business attributes for change detection

These ensure full lineage, auditability, and change tracking.

---

## 5. Data Quality & Validation

### 5.1 Business Rule Enforcement

Silver transformations enforce business-critical rules:

- **Referential integrity**: Foreign keys must reference valid parent records
- **Data precision**: Financial amounts use DECIMAL to avoid floating-point errors
- **Code normalization**: MCC codes padded to 4 digits, currency codes uppercased
- **Date consistency**: All dates properly typed and validated
- **Null handling**: Critical fields enforced as NOT NULL

### 5.2 Deduplication Strategy

Silver implements **latest-record-wins** deduplication:

- Natural keys defined per entity (e.g., transaction_id, base_currency+currency+fx_date)
- Deduplication based on `ingestion_ts` (most recent record wins)
- Ensures idempotent processing and handles replay scenarios

### 5.3 Partition Validation

Time-partitioned tables (transactions, fx_rates) include validation:

- Partition cardinality limits (e.g., max 240 distinct months)
- Prevents partition explosion and maintains query performance
- Fail-fast if threshold exceeded

---

## 6. Partitioning Strategy

### 6.1 Time-Based Partitioning

Tables with high volume and time-series queries are partitioned by month:

- `silver_transactions` → partitioned by `txn_month` (first day of month)
- `silver_fx_rates` → partitioned by `fx_month` (first day of month)

Benefits:
- Query performance for time-range filters
- Efficient incremental processing
- Optimized Direct Lake Power BI scans

### 6.2 Non-Partitioned Tables

Reference data tables (users, cards, mcc) are not partitioned:
- Lower volume
- Full-table scans acceptable
- Simpler maintenance

---

## 7. Schema Registry & Governance

### 7.1 Schema Registry

Each Silver entity has a versioned YAML contract in `GOVERNANCE/schema-registry/02-silver/`:

- Column definitions (name, type, nullable)
- Natural keys for deduplication
- Partitioning strategy
- Quality rules
- Consumer contracts (Gold layer, Power BI)

### 7.2 Schema Enforcement

Silver notebooks enforce strict schema control:

- No dynamic schema inference
- Never using `mergeSchema` when writing Delta
- Mandatory final `select()` with exact column order
- Schema validation against registry contracts

This ensures:
- Schema stability across environments
- Predictable contracts for Gold layer
- Compliance with financial data governance standards

---

## 8. Load Modes

### 8.1 FULL mode
Processes all records from Bronze table.  
Used for:
- Initial Silver population
- Historical backfills
- Reprocessing after schema changes

### 8.2 INCREMENTAL mode
Processes only new or changed records from Bronze.  
Uses:
- `ingestion_ts` filtering
- `as_of_date` parameter for point-in-time processing

This enables efficient daily processing and reduces compute costs.

---

## 9. Error Handling & Resilience

### Retry Policies
- Notebook activities → 2 retries, 120 seconds

### Failure Isolation
Errors are isolated **per entity**, ensuring:
- Other entities can complete successfully
- Clear error diagnostics per transformation
- Operational visibility into partial failures

### Validation Failures
Silver notebooks implement **fail-fast** validation:
- Partition cardinality checks
- Null constraint violations
- Schema mismatches

These fail immediately to prevent data quality issues from propagating to Gold layer.

---

## 10. Key Benefits of the Silver Framework

### 10.1 Production-Grade Data Quality
- Full deduplication
- Business rule enforcement
- Type precision for financial calculations
- Complete audit trail

### 10.2 Strong Engineering Discipline
- Unified transformation pattern
- Entity-specific notebooks for modularity
- Explicit and stable schemas
- Strategic partitioning for performance

### 10.3 High Extensibility
Adding a new entity requires only:

1. Create entity-specific notebook (following standard pattern)
2. Add entity to `pl_silver_master` orchestration
3. Create Silver table DDL
4. Register schema in Schema Registry

No pipeline duplication is needed.

### 10.4 Analytics-Ready
- Optimized for Gold layer joins
- Direct Lake Power BI compatible
- Time-based partitioning for time-series queries
- Record-level change detection via record_hash

---

## 11. Conclusion

The Silver Layer of the Wealth Management Analytics Platform is a **robust, quality-assured, and analytics-optimized data tier**. It transforms raw Bronze data into clean, deduplicated, and business-ready datasets following strict data governance principles.

The architecture is aligned with financial industry expectations and provides:

- data quality assurance
- referential integrity
- schema stability
- query performance
- operational transparency
- full auditability

It is now ready to support the development of the Gold analytical layer, Data Warehouse transformations, and advanced Power BI reporting use cases.

---
