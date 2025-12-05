-- Dimension Tables for Star Schema

-- Client Dimension
CREATE TABLE IF NOT EXISTS dim_client (
    client_id STRING NOT NULL,
    client_name STRING,
    client_type STRING,
    country STRING,
    region STRING,
    created_date DATE,
    updated_date DATE,
    is_active BOOLEAN,
    PRIMARY KEY (client_id)
);

-- Account Dimension
CREATE TABLE IF NOT EXISTS dim_account (
    account_id STRING NOT NULL,
    client_id STRING NOT NULL,
    account_name STRING,
    account_type STRING,
    base_currency STRING,
    opened_date DATE,
    closed_date DATE,
    is_active BOOLEAN,
    PRIMARY KEY (account_id),
    FOREIGN KEY (client_id) REFERENCES dim_client(client_id)
);

-- Security Dimension
CREATE TABLE IF NOT EXISTS dim_security (
    security_id STRING NOT NULL,
    security_name STRING,
    security_type STRING,
    isin STRING,
    currency STRING,
    sector STRING,
    industry STRING,
    PRIMARY KEY (security_id)
);

-- Currency Dimension
CREATE TABLE IF NOT EXISTS dim_currency (
    currency_code STRING NOT NULL,
    currency_name STRING,
    region STRING,
    PRIMARY KEY (currency_code)
);

-- Date Dimension
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT NOT NULL,
    date_value DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name STRING,
    week INT,
    day_of_year INT,
    day_of_month INT,
    day_of_week INT,
    day_name STRING,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    PRIMARY KEY (date_key)
);

