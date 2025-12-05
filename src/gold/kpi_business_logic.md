# KPI Business Logic

## Overview
This document explains the business logic for key performance indicators (KPIs) calculated in the Gold layer.

## AUM (Assets Under Management)
Assets Under Management represents the total market value of all assets managed for clients.

### Calculation
- Sum of all position values (quantity × price) for each client/account
- Converted to base currency using FX rates
- Calculated daily at end of day

## P&L (Profit & Loss)
Profit & Loss represents the change in portfolio value over time.

### Calculation
- Daily P&L = Current AUM - Previous Day AUM
- Includes realized and unrealized gains/losses
- Adjusted for transactions (deposits, withdrawals)

## Risk Metrics
[Add risk calculation logic here]

## FX Exposure
Foreign Exchange exposure represents the exposure to currency fluctuations.

### Calculation
- Sum of positions in non-base currencies
- Converted to base currency equivalent
- Grouped by currency pair

