-- ==========================================
-- 01_setup_database.sql
-- Goal: Initial Snowflake configuration
-- ==========================================

-- 1. Create Database
CREATE DATABASE IF NOT EXISTS RETAIL_DB;
USE DATABASE RETAIL_DB;

-- 2. Create Schemas (Data Layers)
CREATE SCHEMA IF NOT EXISTS RAW;       -- Bronze Layer (Raw data as it arrives)
CREATE SCHEMA IF NOT EXISTS STAGE;     -- Silver Layer (Cleaned and deduplicated data)
CREATE SCHEMA IF NOT EXISTS ANALYTICS; -- Gold Layer (Final reports)

-- 3. Create Warehouse (Compute)
-- Using X-SMALL to keep costs low during development
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WITH WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 4. File Formats
CREATE OR REPLACE FILE FORMAT RAW.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '')
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- ==========================================
-- NOTE: The following steps require the AWS Role ARN
-- Will be completed once AWS infrastructure is configured (Phase 2)
-- ==========================================

/*
-- 5. Storage Integration (Allows Snowflake to securely read from S3)
CREATE STORAGE INTEGRATION s3_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::XXXXXXXXXXXX:role/snowflake_access_role' -- <-- COMPLETE WITH ARN
  STORAGE_ALLOWED_LOCATIONS = ('s3://my-retail-inbox-bucket/');

-- 6. External Stage (Points to the bucket using the integration)
CREATE STAGE RAW.INBOX_STAGE
  URL = 's3://my-retail-inbox-bucket/inbox/'
  STORAGE_INTEGRATION = s3_int
  FILE_FORMAT = RAW.CSV_FORMAT;
*/
