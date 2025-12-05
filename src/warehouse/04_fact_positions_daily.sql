-- Fact Table: Positions Daily

CREATE TABLE IF NOT EXISTS fact_positions_daily (
    position_id STRING NOT NULL,
    date_key INT NOT NULL,
    account_id STRING NOT NULL,
    client_id STRING NOT NULL,
    security_id STRING NOT NULL,
    currency_code STRING NOT NULL,
    quantity DECIMAL(18, 4) NOT NULL,
    unit_cost DECIMAL(18, 4),
    unit_price DECIMAL(18, 4),
    cost_basis DECIMAL(18, 2),
    market_value DECIMAL(18, 2),
    market_value_base_currency DECIMAL(18, 2),
    unrealized_gain_loss DECIMAL(18, 2),
    created_timestamp TIMESTAMP,
    PRIMARY KEY (position_id),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (account_id) REFERENCES dim_account(account_id),
    FOREIGN KEY (client_id) REFERENCES dim_client(client_id),
    FOREIGN KEY (security_id) REFERENCES dim_security(security_id),
    FOREIGN KEY (currency_code) REFERENCES dim_currency(currency_code)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_fact_positions_date ON fact_positions_daily(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_positions_account ON fact_positions_daily(account_id);
CREATE INDEX IF NOT EXISTS idx_fact_positions_security ON fact_positions_daily(security_id);

