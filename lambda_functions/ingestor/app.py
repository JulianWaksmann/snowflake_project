import json
import logging
import os
import boto3
import snowflake.connector
import re
from datetime import datetime
import snowflake.connector

# Configure Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize S3 Client (outside handler for reuse)
s3_client = boto3.client('s3')

def get_db_connection():
    """Establishes connection to Snowflake using Env Vars"""
    return snowflake.connector.connect(
        user=os.environ['SNOWFLAKE_USER'],
        password=os.environ['SNOWFLAKE_PASSWORD'],
        account=os.environ['SNOWFLAKE_ACCOUNT'],
        warehouse=os.environ['SNOWFLAKE_WAREHOUSE'],
        database=os.environ['SNOWFLAKE_DATABASE'],
        schema='RAW'
    )

def move_file_to_history(bucket, key, file_type):
    """
    Moves processed file to history/ folder with partitioning.
    Structure: history/{type}/year=YYYY/month=MM/day=DD/filename
    """
    now = datetime.now()
    partition_path = f"year={now.year}/month={now.strftime('%m')}/day={now.strftime('%d')}"
    
    # Define new key
    new_key = f"history/{file_type}/{partition_path}/{os.path.basename(key)}"
    
    logger.info(f"Moving file to: {new_key}")
    
    # Copy object
    s3_client.copy_object(
        Bucket=bucket,
        CopySource={'Bucket': bucket, 'Key': key},
        Key=new_key
    )
    
    # Delete original
    s3_client.delete_object(Bucket=bucket, Key=key)

def lambda_handler(event, context):
    """
    AWS Lambda Entry Point.
    Triggered by S3 ObjectCreated events.
    """
    logger.info(f"Event received: {json.dumps(event)}")
    
    processed_count = 0
    errors = []
    conn = None

    try:
        # Establish connection once for the batch
        conn = get_db_connection()
        cursor = conn.cursor()

        for record in event.get('Records', []):
            try:
                bucket_name = record['s3']['bucket']['name']
                file_key = record['s3']['object']['key']
                
                # Skip if not in inbox/ or if it's a folder
                if 'inbox/' not in file_key or file_key.endswith('/'):
                    logger.info(f"Skipping key: {file_key}")
                    continue

                logger.info(f"Processing File [{processed_count + 1}]: s3://{bucket_name}/{file_key}")
                
                # Determine File Type and Extract Date (YYYYMMDD)
                filename = os.path.basename(file_key).lower()
                
                # Regex to find date in filename (e.g., _20250110)
                date_match = re.search(r'(\d{8})', filename)
                batch_date_str = date_match.group(1) if date_match else datetime.now().strftime('%Y%m%d')
                
                # Format for Snowflake Date Literal (YYYY-MM-DD)
                batch_date_sql = f"'{batch_date_str[:4]}-{batch_date_str[4:6]}-{batch_date_str[6:]}'"

                if 'store' in filename:
                    # Ingest Stores Data
                    file_type = 'stores'
                    # Schema: store_group, store_token, store_name, source_filename, batch_date
                    sql = f"""
                    COPY INTO RAW.STORES (store_group, store_token, store_name, source_filename, batch_date)
                    FROM (
                        SELECT $1, $2, $3, metadata$filename, {batch_date_sql}
                        FROM @RAW.INBOX_STAGE/{os.path.basename(file_key)}
                    )
                    FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FORMAT)
                    ON_ERROR = 'CONTINUE' 
                    """
                    
                elif 'sale' in filename:
                    # Ingest Sales Data
                    file_type = 'transactions'
                    # Target Schema: store_token, transaction_id, receipt_token, transaction_time, amount, source_id, user_role, source_filename, batch_date
                    sql = f"""
                    COPY INTO RAW.SALES (
                        store_token, 
                        transaction_id, 
                        receipt_token, 
                        transaction_time, 
                        amount, 
                        source_id, 
                        user_role, 
                        source_filename,
                        batch_date
                    )
                    FROM (
                        SELECT 
                            $1, $2, $3, $4, $5, 
                            CASE WHEN $7 IS NULL THEN NULL ELSE $6 END, -- SourceID (Null if 6 cols)
                            CASE WHEN $7 IS NULL THEN $6 ELSE $7 END, -- User Role (Pos 6 or 7)
                            metadata$filename,
                            {batch_date_sql} -- Injected Date Literal
                        FROM @RAW.INBOX_STAGE/{os.path.basename(file_key)}
                    )
                    FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FORMAT ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE)
                    ON_ERROR = 'ABORT_STATEMENT'
                    """
                    
                else:
                    logger.warning(f"Unknown file type: {filename}")
                    continue

                if sql:
                    logger.info(f"Executing SQL for {filename}")
                    logger.info(f"Executing SQL: {sql}")
                    cursor.execute(sql)
                    
                    # Move to History
                    move_file_to_history(bucket_name, file_key, file_type)
                    processed_count += 1

            except Exception as e:
                error_msg = f"Error processing record {record.get('awsRegion', 'unknown')}: {str(e)}"
                logger.error(error_msg)
                errors.append(error_msg)
                # Continue processing other records
        
    except Exception as e:
        logger.error(f"Critical Connection Error: {str(e)}")
        raise e
    finally:
        if conn:
            conn.close()
    
    # Summary
    logger.info(f"Batch Complete. Processed: {processed_count}, Errors: {len(errors)}")
    
    if errors:
        raise Exception(f"Batch processed with {len(errors)} errors: {json.dumps(errors)}")

    return {
        'statusCode': 200,
        'body': json.dumps(f"Batch processed: {processed_count} files.")
    }
