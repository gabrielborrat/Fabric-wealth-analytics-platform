# Dataset Refresh Plan

## Refresh Frequency
- **Daily**: Full refresh of all fact tables
- **Incremental**: Dimension tables refreshed on change

## Refresh Windows
- **Primary Window**: 02:00 - 04:00 UTC (off-peak hours)
- **Backup Window**: 14:00 - 16:00 UTC (if primary fails)

## Refresh Strategy

### Fact Tables
- **fact_aum_daily**: Full refresh daily
- **fact_pnl_daily**: Full refresh daily
- **fact_positions_daily**: Full refresh daily

### Dimension Tables
- **dim_client**: Incremental refresh on change
- **dim_account**: Incremental refresh on change
- **dim_security**: Incremental refresh on change
- **dim_currency**: Static, refreshed monthly
- **dim_date**: Static, refreshed annually

## Monitoring
- Monitor refresh duration and failures
- Alert on refresh failures
- Track data freshness metrics

