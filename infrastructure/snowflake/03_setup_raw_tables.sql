USE ROLE SYSADMIN;
USE DATABASE RETAIL_DB;
USE SCHEMA RAW;

-- 1. STORES Raw Table
CREATE OR REPLACE TABLE RAW.STORES (
    store_group VARCHAR,
    store_token VARCHAR,
    store_name  VARCHAR,
    
    -- Metadata columns
    source_filename VARCHAR,
    batch_date DATE,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 2. SALES Raw Table
CREATE OR REPLACE TABLE RAW.SALES (
    store_token      VARCHAR,
    transaction_id   VARCHAR,
    receipt_token    VARCHAR,
    transaction_time VARCHAR,
    amount           VARCHAR,
    source_id        VARCHAR,
    user_role        VARCHAR,
    
    -- Metadata columns
    source_filename VARCHAR,
    batch_date DATE,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
