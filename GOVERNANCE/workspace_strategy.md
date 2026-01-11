# Workspace Strategy

## Overview
This document outlines the workspace organization strategy for the Fabric Wealth Management Analytics platform.

## Workspace Structure

### wm-raw-ingestion
**Purpose**: Raw data ingestion and landing zone
- **Layers**: Bronze only
- **Access**: Data engineers, ingestion team
- **Content**: 
  - Ingestion pipelines
  - Bronze layer tables
  - Ingestion logs and manifests

### wm-analytics-engineering
**Purpose**: Data transformation and analytics
- **Layers**: Silver and Gold
- **Access**: Data engineers, analytics engineers
- **Content**:
  - Silver transformation notebooks
  - Gold aggregation notebooks
  - Business logic and transformations

### wm-reporting-bi
**Purpose**: Reporting and business intelligence
- **Layers**: Warehouse, Power BI
- **Access**: BI developers, analysts, business users
- **Content**:
  - Data warehouse
  - Power BI datasets
  - Power BI reports

## Data Flow
1. Data lands in `wm-raw-ingestion` (Bronze)
2. Transformed in `wm-analytics-engineering` (Silver → Gold)
3. Loaded to `wm-reporting-bi` (Warehouse)
4. Consumed by Power BI in `wm-reporting-bi`

## Benefits
- Clear separation of concerns
- Appropriate access control per workspace
- Scalability and maintainability
- Compliance with data governance requirements

