# Data Classification Policy

## Overview
This document defines data classification levels and handling requirements for the Fabric Wealth Management Analytics platform.

## Classification Levels

### Public
- **Description**: Non-sensitive, publicly available data
- **Examples**: Currency exchange rates, market indices
- **Handling**: No restrictions

### Internal
- **Description**: Internal business data, not publicly available
- **Examples**: General portfolio metrics, aggregated KPIs
- **Handling**: Access limited to authorized personnel

### Confidential
- **Description**: Sensitive business data requiring protection
- **Examples**: Client portfolio details, transaction data
- **Handling**: 
  - Access limited to specific roles
  - Encryption at rest and in transit
  - Audit logging required

### Highly Confidential
- **Description**: Most sensitive data requiring highest protection
- **Examples**: Personal identifiable information (PII), account numbers
- **Handling**:
  - Strict access controls
  - Encryption mandatory
  - Full audit trail
  - Data masking in non-production environments

## Data Classification by Entity

### FX Rates
- **Classification**: Public
- **Location**: Bronze, Silver, Gold

### Transactions
- **Classification**: Confidential
- **Location**: Bronze, Silver, Gold
- **Requirements**: Encryption, access controls

### Client Data
- **Classification**: Highly Confidential
- **Location**: Dimensions, Warehouse
- **Requirements**: Encryption, masking, strict access controls

### AUM/P&L Metrics
- **Classification**: Confidential
- **Location**: Gold, Warehouse
- **Requirements**: Access controls, audit logging

## Compliance
- GDPR compliance for EU client data
- Financial regulations compliance
- Regular data classification reviews

