#!/bin/bash
# deploy.sh
# Automates the Packaging and Deployment of the CloudFormation Stack
# Usage: ./scripts/deploy.sh <SnowflakeAccount>
# Example: ./scripts/deploy.sh

set -e # Exit immediately if a command exits with a non-zero status.

# Ensure we are running from the project root
cd "$(dirname "$0")/.."

SNOWFLAKE_ACCOUNT="WUCVZIQ-PUC25430"

STACK_NAME="retail-pipeline"
PROFILE="snowflake-project"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile $PROFILE)
BUCKET_NAME="retail-data-pipeline-deployments-$ACCOUNT_ID"

echo -e "\033[0;36m🚀 Starting Deployment for Snowflake Account: $SNOWFLAKE_ACCOUNT\033[0m"

# 1. Check Deployment Bucket
BUCKET_NAME="retail-data-pipeline-deployments-$ACCOUNT_ID"
echo "1. Checking Deployment Bucket: $BUCKET_NAME..."
if ! aws s3 ls "s3://$BUCKET_NAME" --profile $PROFILE > /dev/null 2>&1; then
    echo "   Creating bucket..."
    aws s3 mb "s3://$BUCKET_NAME" --profile $PROFILE --region $REGION
fi

# 2. Package
echo "2. Packaging Application..."
aws cloudformation package \
    --template-file infrastructure/cloudformation/template.yaml \
    --s3-bucket $BUCKET_NAME \
    --output-template-file infrastructure/cloudformation/packaged-template.yaml \
    --profile $PROFILE \
    --region $REGION

# Prompt for Snowflake Password (Hidden input)
read -s -p "Enter Snowflake Password for LAMBDA_USER: " SNOWFLAKE_PASSWORD
echo ""

# 3. Deploy
echo "3. Deploying Stack..."
aws cloudformation deploy \
    --template-file infrastructure/cloudformation/packaged-template.yaml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        SnowflakeAccount=$SNOWFLAKE_ACCOUNT \
        SnowflakePassword=$SNOWFLAKE_PASSWORD \
    --profile $PROFILE \
    --region $REGION

echo -e "\033[0;32m✅ Deployment Complete!\033[0m"
