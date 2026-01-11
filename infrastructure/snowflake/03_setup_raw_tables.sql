USE ROLE SYSADMIN;
USE DATABASE RETAIL_DB;
USE SCHEMA RAW;

-- 1. Stores Table
CREATE TABLE IF NOT EXISTS RAW.STORES (
    store_group VARCHAR,
    store_token VARCHAR,
    store_name  VARCHAR,
    
    -- Metadata columns
    source_filename VARCHAR,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 2. Sales Table
CREATE TABLE IF NOT EXISTS RAW.SALES (
    store_token      VARCHAR,
    transaction_id   VARCHAR,
    receipt_token    VARCHAR,
    transaction_time VARCHAR,
    amount           VARCHAR,
    source_id        VARCHAR,
    user_role        VARCHAR,
    
    -- Metadata columns
    source_filename VARCHAR,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
