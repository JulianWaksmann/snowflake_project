-- ==========================================
-- 01_setup_database.sql
-- Goal: Initial Snowflake configuration
-- ==========================================

-- 0. Set Role (Critical for permissions)
USE ROLE SYSADMIN;

-- 1. Create Database
CREATE DATABASE IF NOT EXISTS RETAIL_DB;
USE DATABASE RETAIL_DB;

-- 2. Create Schemas (Data Layers)
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGE;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- 3. Create Warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WITH WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 4. File Formats
CREATE OR REPLACE FILE FORMAT RAW.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 0
    NULL_IF = ('NULL', 'null', '')
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- 5. Storage Integration (Requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS s3_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::554074173959:role/retail-data-pipeline-snowflake-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://retail-data-pipeline-554074173959/');

-- Grant Usage to SYSADMIN
GRANT USAGE ON INTEGRATION s3_int TO ROLE SYSADMIN;

-- 6. External Stage (Switch back to SYSADMIN)
USE ROLE SYSADMIN;

CREATE OR REPLACE STAGE RAW.INBOX_STAGE
  URL = 's3://retail-data-pipeline-554074173959/inbox/'
  STORAGE_INTEGRATION = s3_int
  FILE_FORMAT = RAW.CSV_FORMAT;
