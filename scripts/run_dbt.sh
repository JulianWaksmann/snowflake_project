#!/bin/bash
# run_dbt.sh
# Wrapper to run dbt commands with Environment Variables injected
# Usage: ./scripts/run_dbt.sh <command>
# Example: ./scripts/run_dbt.sh debug
# Example: ./scripts/run_dbt.sh run

set -e

# Ensure we are running from the project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Configuration
export SNOWFLAKE_ACCOUNT="WUCVZIQ-PUC25430"
export SNOWFLAKE_USER="LAMBDA_USER"
export SNOWFLAKE_ROLE="SYSADMIN"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_DATABASE="RETAIL_DB"

# Check if Password is set in current shell, if not prompt
if [ -z "$SNOWFLAKE_PASSWORD" ]; then
    read -s -p "Enter Snowflake Password for LAMBDA_USER: " SNOWFLAKE_PASSWORD
    echo ""
    export SNOWFLAKE_PASSWORD
fi

if [ -z "$SNOWFLAKE_PASSWORD" ]; then
    echo "Error: Password is required."
    exit 1
fi

echo -e "\033[0;36m🚀 Running dbt command: $*\033[0m"

# Run dbt using the Virtual Environment's executable directly
cd dbt_project
"$PROJECT_ROOT/venv/Scripts/dbt.exe" "$@"
