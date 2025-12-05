# Silver Layer Constraints and Business Rules

## Overview
This document defines the data quality constraints and business rules applied in the Silver layer transformations.

## Data Quality Constraints

### FX Data
- Exchange rates must be positive values
- Currency pairs must follow ISO 4217 format (e.g., USD/EUR)
- Date must be valid and not in the future

### Transactions
- Transaction amounts cannot be zero
- Transaction dates must be valid
- Account IDs must exist in the account dimension
- Currency codes must be valid ISO 4217 codes

## Business Rules

[Add specific business rules here]

