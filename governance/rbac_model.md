# RBAC Model

## Overview
This document defines the Role-Based Access Control (RBAC) model for the Fabric Wealth Management Analytics platform.

## Roles

### Data Engineer
- **Workspaces**: wm-raw-ingestion, wm-analytics-engineering
- **Permissions**: 
  - Read/Write on Bronze, Silver, Gold layers
  - Execute pipelines
  - Manage notebooks

### Analytics Engineer
- **Workspaces**: wm-analytics-engineering
- **Permissions**:
  - Read Bronze
  - Read/Write Silver, Gold
  - Execute transformation pipelines

### BI Developer
- **Workspaces**: wm-reporting-bi
- **Permissions**:
  - Read Gold (from analytics workspace)
  - Read/Write Warehouse
  - Manage Power BI datasets and reports

### Business Analyst
- **Workspaces**: wm-reporting-bi
- **Permissions**:
  - Read Warehouse
  - Read Power BI reports
  - Create personal Power BI reports

### Data Viewer
- **Workspaces**: wm-reporting-bi
- **Permissions**:
  - Read Power BI reports only

## Access by Layer

### Bronze Layer
- **Read**: Data Engineers, Analytics Engineers
- **Write**: Data Engineers only

### Silver Layer
- **Read**: Analytics Engineers, BI Developers
- **Write**: Data Engineers, Analytics Engineers

### Gold Layer
- **Read**: Analytics Engineers, BI Developers
- **Write**: Analytics Engineers

### Warehouse
- **Read**: BI Developers, Business Analysts
- **Write**: BI Developers

### Power BI
- **Read**: All roles
- **Write**: BI Developers only

