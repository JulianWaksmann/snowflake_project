-- ==========================================
-- 02_setup_security.sql
-- Goal: Create Service User for Lambda
-- ==========================================

USE ROLE SECURITYADMIN;

-- 1. Create the User
CREATE USER IF NOT EXISTS LAMBDA_USER
    PASSWORD = 'TuPasswordFuerte123'
    DEFAULT_WAREHOUSE = COMPUTE_WH
    DEFAULT_ROLE = SYSADMIN
    MUST_CHANGE_PASSWORD = FALSE;

-- 2. Grant Permissions
GRANT ROLE SYSADMIN TO USER LAMBDA_USER;
