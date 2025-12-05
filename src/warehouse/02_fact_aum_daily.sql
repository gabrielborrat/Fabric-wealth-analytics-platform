-- Fact Table: Assets Under Management Daily

CREATE TABLE IF NOT EXISTS fact_aum_daily (
    aum_id STRING NOT NULL,
    date_key INT NOT NULL,
    account_id STRING NOT NULL,
    client_id STRING NOT NULL,
    security_id STRING,
    currency_code STRING NOT NULL,
    quantity DECIMAL(18, 4),
    unit_price DECIMAL(18, 4),
    market_value DECIMAL(18, 2),
    market_value_base_currency DECIMAL(18, 2),
    fx_rate DECIMAL(18, 6),
    created_timestamp TIMESTAMP,
    PRIMARY KEY (aum_id),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (account_id) REFERENCES dim_account(account_id),
    FOREIGN KEY (client_id) REFERENCES dim_client(client_id),
    FOREIGN KEY (security_id) REFERENCES dim_security(security_id),
    FOREIGN KEY (currency_code) REFERENCES dim_currency(currency_code)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_fact_aum_date ON fact_aum_daily(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_aum_account ON fact_aum_daily(account_id);
CREATE INDEX IF NOT EXISTS idx_fact_aum_client ON fact_aum_daily(client_id);

