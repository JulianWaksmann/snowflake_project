-- ==========================================
-- 02_setup_security.sql
-- Goal: Create Service User for Lambda
-- ==========================================

USE ROLE SECURITYADMIN;

-- 1. Create the User
CREATE USER IF NOT EXISTS LAMBDA_USER
    PASSWORD = ''
    DEFAULT_WAREHOUSE = COMPUTE_WH
    DEFAULT_ROLE = SYSADMIN
    MUST_CHANGE_PASSWORD = FALSE;

-- 2. Grant Permissions (Role Hierarchy)
GRANT ROLE SYSADMIN TO USER LAMBDA_USER;

-- 3. Warehouse Permissions (Requires ACCOUNTADMIN to grant to SYSADMIN if ownership drifted)
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;

-- 4. Enforce Default Warehouse
ALTER USER LAMBDA_USER SET DEFAULT_WAREHOUSE = COMPUTE_WH;
