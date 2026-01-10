# Serverless Retail Data Pipeline

This project implements a scalable, Serverless data pipeline to process retail store and sales data using **AWS** and **Snowflake**.

## Architecture

- **Ingestion**: AWS Lambda (Python) + S3 Event Notifications.
- **Storage**: Snowflake (Raw, Stage, Analytics layers).
- **Transformation**: dbt (Data Build Tool).
- **Orchestration**: Event-driven (S3 -> Lambda).
- **Error Handling**: AWS SNS for immediate failure notifications.

## Repository Structure

```text
/
├── dbt_project/            # dbt Transformations (SQL Models)
├── infrastructure/         # IaC Scripts (Snowflake DDLs, S3 setup, IAM)
├── lambda_functions/       # Python Code
├── scripts/                # Utility scripts
└── tests/                  # Unit tests
```

## Getting Started

Check `checklist.md` to track implementation progress.
