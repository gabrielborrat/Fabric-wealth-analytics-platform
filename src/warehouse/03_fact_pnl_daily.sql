-- Fact Table: Profit & Loss Daily

CREATE TABLE IF NOT EXISTS fact_pnl_daily (
    pnl_id STRING NOT NULL,
    date_key INT NOT NULL,
    account_id STRING NOT NULL,
    client_id STRING NOT NULL,
    security_id STRING,
    currency_code STRING NOT NULL,
    realized_pnl DECIMAL(18, 2),
    unrealized_pnl DECIMAL(18, 2),
    total_pnl DECIMAL(18, 2),
    pnl_base_currency DECIMAL(18, 2),
    fx_impact DECIMAL(18, 2),
    created_timestamp TIMESTAMP,
    PRIMARY KEY (pnl_id),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (account_id) REFERENCES dim_account(account_id),
    FOREIGN KEY (client_id) REFERENCES dim_client(client_id),
    FOREIGN KEY (security_id) REFERENCES dim_security(security_id),
    FOREIGN KEY (currency_code) REFERENCES dim_currency(currency_code)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_fact_pnl_date ON fact_pnl_daily(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_pnl_account ON fact_pnl_daily(account_id);
CREATE INDEX IF NOT EXISTS idx_fact_pnl_client ON fact_pnl_daily(client_id);

