# deploy.ps1
# Automates the Packaging and Deployment of the CloudFormation Stack
# Usage: .\scripts\deploy.ps1

param (
    [string]$SnowflakeAccount = "WUCVZIQ-PUC25430"
)

$ErrorActionPreference = "Stop"

$StackName = "retail-pipeline"
$Profile = "snowflake-project"
$Region = "us-east-1"

# Get Account ID
$AccountId = aws sts get-caller-identity --query Account --output text --profile $Profile
$BucketName = "retail-data-pipeline-deployments-$AccountId"

Write-Host "🚀 Starting Deployment for Snowflake Account: $SnowflakeAccount" -ForegroundColor Cyan

# 1. Check Deployment Bucket
Write-Host "1. Checking Deployment Bucket: $BucketName..."
$BucketExists = aws s3 ls "s3://$BucketName" --profile $Profile 2>$null
if (-not $BucketExists) {
    Write-Host "   Creating bucket..."
    aws s3 mb "s3://$BucketName" --profile $Profile --region $Region
}

# 2. Package
Write-Host "2. Packaging Application..."
aws cloudformation package `
    --template-file infrastructure/cloudformation/template.yaml `
    --s3-bucket $BucketName `
    --output-template-file infrastructure/cloudformation/packaged-template.yaml `
    --profile $Profile `
    --region $Region

# Prompt for Snowflake Password (masked)
$SnowflakePassword = Read-Host -Prompt "Enter Snowflake Password for LAMBDA_USER" -AsSecureString
$SnowflakePasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SnowflakePassword))

# 3. Deploy
Write-Host "3. Deploying Stack..."
aws cloudformation deploy `
    --template-file infrastructure/cloudformation/packaged-template.yaml `
    --stack-name $StackName `
    --capabilities CAPABILITY_NAMED_IAM `
    --parameter-overrides SnowflakeAccount=$SnowflakeAccount SnowflakePassword=$SnowflakePasswordPlain `
    --profile $Profile `
    --region $Region

Write-Host "✅ Deployment Complete!" -ForegroundColor Green
