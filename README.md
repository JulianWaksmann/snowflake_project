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

## Engineering Decisions
### 1. Handling "Optional Headers" (CSV)
The business requirement states that CSV headers *may or may not* be present.
*   **Technique**: "Read-All, Filter-Later".
*   **Implementation**:
    *   **Snowflake**: `SKIP_HEADER = 0` (Reads every line).
    *   **dbt (Stage Layer)**: We apply `WHERE col_name != 'col_name'` to filter out the header row if it exists.
*   **Benefit**: Zero data loss risk. We never accidentally skip a data row if the header is missing.

### 2. Batch Date vs Transaction Date
Files arrive named as `sales_YYYYMMDD.csv`.
*   **Problem**: This date (Batch Date) is critical for lineage but isn't inside the file content.
*   **Solution**:
    *   **Lambda**: Extracts `YYYYMMDD` from the filename using Regex.
    *   **Snowflake**: Injects this value into the `batch_date` column during the `COPY INTO` command.
    *   **Result**: Every record is permanently stamped with its source batch date.

## Getting Started

Check `checklist.md` to track implementation progress.
