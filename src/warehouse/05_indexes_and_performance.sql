-- Additional Indexes and Performance Optimizations

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_fact_aum_date_client ON fact_aum_daily(date_key, client_id);
CREATE INDEX IF NOT EXISTS idx_fact_pnl_date_client ON fact_pnl_daily(date_key, client_id);
CREATE INDEX IF NOT EXISTS idx_fact_positions_date_account ON fact_positions_daily(date_key, account_id);

-- Statistics collection
ANALYZE TABLE dim_client COMPUTE STATISTICS;
ANALYZE TABLE dim_account COMPUTE STATISTICS;
ANALYZE TABLE dim_security COMPUTE STATISTICS;
ANALYZE TABLE dim_currency COMPUTE STATISTICS;
ANALYZE TABLE dim_date COMPUTE STATISTICS;
ANALYZE TABLE fact_aum_daily COMPUTE STATISTICS;
ANALYZE TABLE fact_pnl_daily COMPUTE STATISTICS;
ANALYZE TABLE fact_positions_daily COMPUTE STATISTICS;

