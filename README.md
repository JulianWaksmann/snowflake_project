# Retail Data Pipeline

A robust, Serverless data pipeline designed to ingest, validate, and process retail data scale using **AWS** and **Snowflake**.

![Status](https://img.shields.io/badge/Status-Active-success)
![AWS](https://img.shields.io/badge/AWS-Lambda%20%7C%20S3%20%7C%20SNS-orange)
![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Cloud-blue)
![Python](https://img.shields.io/badge/Python-3.9-yellow)

## Overview

This project implements an ELT (Extract, Load, Transform) pattern:
1.  **Extract**: Partners upload CSV files (`Sales` or `Stores`) to an S3 Inbox.
2.  **Load**: AWS Lambda triggers instantly, validating the file and executing a Snowflake `COPY INTO` command to load raw data.
3.  **Transform**: **dbt** (Data Build Tool) cleans, deduplicates, and models the data into analytical tables.

### Architecture Flow
![Architecture Diagram](assets/architecture_diagram.png)

---

## Prerequisites

*   **AWS CLI** installed and configured (`v2+`).
*   **Snowflake Account** (Standard or higher).
*   **Python 3.9+** and `pip`.
*   **git**.

---

## Getting Started

### 1. Configure AWS Credentials
Ensure you have an AWS Profile named `snowflake-project` configured in your environment.
```bash
aws configure --profile snowflake-project
```

### 2. Setup Snowflake Environment
Run the setup scripts in your Snowflake Worksheet (as `ACCOUNTADMIN`):
1.  `infrastructure/snowflake/01_setup_database.sql` (Creates DB, Warehouse, Integration).
2.  `infrastructure/snowflake/02_setup_security.sql` (Creates Users & Roles).
3.  `infrastructure/snowflake/03_setup_raw_tables.sql` (Creates Tables).

### 3. Deploy Infrastructure
We use a unified Bash script to package and deploy the AWS stack (Lambda, S3, IAM).

```bash
cd scripts/
./deploy.sh
```
*You will be prompted for your Snowflake Password during deployment.*

---

## Usage

To process data, simply upload a file to the S3 `inbox/` folder.

**Upload Sales Data:**
```bash
aws s3 cp test_data/sales_20250111.csv s3://<BUCKET_NAME>/inbox/ --profile snowflake-project
```

**What happens next?**
1.  File lands in `inbox/`.
2.  Lambda detects file type (`store` vs `sale`) and extracts Batch Date from filename.
3.  Data is loaded into `RAW.STORES` or `RAW.SALES`.
4.  File is moved to `history/<type>/year=YYYY/month=MM/day=DD/`.
5.  If error: File stays in `inbox/` and you receive an alert.

---

---
---

## Transformation Strategy (dbt)

We leverage **dbt** for scalable, modular transformations. A key architectural decision was to favor **Incremental Tables** over Views to handle potentially massive datasets efficiently.

### 1. Stage Layer (Cleaning & Deduplication)
*   **Materialization**: `incremental` (Table).
*   **Strategy**: **UPSERT**.
*   **Key**: `store_token` (Stores) / `store_token + transaction_id` (Sales).
*   **Logic**:
    *   We query `RAW` filtering only data that arrived *after* the last run (`loaded_at > max(this.loaded_at)`).
    *   This ensures we process only the "delta", making the pipeline extremely fast and cost-effective.

### 2. Marts Layer (Analytics)
*   **Materialization**: `incremental`.
*   **Strategy**: **Lookback Window**.
*   **Logic**:
    *   Since Marts accumulate metrics (sums, counts), a simple upsert of new rows would corrupt the totals.
    *   Instead, we re-process a safety window (last 7 days) to ensure any late-arriving data or corrections are correctly aggregated into the daily totals.

---

### 4. Orchestration (Daily Run)
In a production environment, you would schedule the transformation job to run after data ingestion.
*   **Command**: `dbt run` (Processes only new data).
*   **Production Evolution**:
    *   **AWS ECS (Fargate)**: Run dbt in a container. This effectively decouples the "Runner" from any specific server, allowing for Event-Driven execution (S3 -> Lambda -> ECS Task) if real-time transformations are needed.

---

## Future Improvements & Production Readiness
1.  **Security Hardening**:
    *   Migrate credentials from Environment Variables to **AWS Secrets Manager**.
    *   Implement **PrivateLink** for secure S3-Snowflake communication without traversing the public internet.
2.  **Infrastructure as Code**:
    *   Migrate from Bash/CloudFormation to **AWS CDK (TypeScript/Python)**. It allows defining infrastructure using real programming languages, offering better abstraction and testing than raw YAML.
3.  **Observability**:
    *   Implement **Data Contracts** to catch schema changes at the source.

---

## Engineering Decisions

### Handling "Optional Headers"
*   **Problem**: Files may or may not have headers.
*   **Solution**: `SKIP_HEADER = 0` (Read all lines). We filter the header row downstream in **dbt** using `WHERE col != 'col_name'`.
*   **Why**: Prevents data loss if a file without header is wrongly skipped.

### Batch Date Extraction
*   **Problem**: Filename contains critical "Batch Date" metadata not present in row data.
*   **Solution**: Lambda RegEx extracts date -> Python injects it into `COPY INTO` command -> Persisted in `batch_date` column.

---

## Repository Structure

```text
/
├── dbt_project/            # dbt Models & Config (Phase 4)
├── infrastructure/         
│   ├── cloudformation/     # AWS Stack (template.yaml)
│   └── snowflake/          # SQL DDLs for Database setup
├── lambda_functions/       # Python Source Code for Ingestion
├── scripts/                # Deployment utilities
├── test_data/              # Sample CSVs for QA
└── README.md               # You are here
```
