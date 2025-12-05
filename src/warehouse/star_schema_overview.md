# Star Schema Overview

## Schema Design
The data warehouse implements a star schema with the following structure:

### Fact Tables
- **fact_aum_daily**: Daily Assets Under Management snapshots
- **fact_pnl_daily**: Daily Profit & Loss calculations
- **fact_positions_daily**: Daily position holdings

### Dimension Tables
- **dim_client**: Client master data
- **dim_account**: Account master data
- **dim_security**: Security/instrument master data
- **dim_currency**: Currency reference data
- **dim_date**: Date dimension for time-based analysis

## Relationships
- All fact tables link to dim_date via date_key
- Fact tables link to relevant dimensions via foreign keys
- Supports efficient querying and aggregation for reporting

## Performance Considerations
- Indexes created on foreign keys and commonly filtered columns
- Statistics collected for query optimization
- Partitioning strategy: [Add partitioning details]

