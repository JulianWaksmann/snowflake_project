
WITH source AS (
    SELECT * FROM {{ source('retail', 'SALES') }}
),

cleaned AS (
    SELECT
        store_token,
        transaction_id,
        receipt_token,
        -- Clean Amount: Remove '$' and cast
        TRY_TO_NUMBER(REPLACE(amount, '$', ''), 38, 2) as amount,
        -- Cast Time
        TRY_TO_TIMESTAMP(transaction_time) as transaction_time,
        source_id,
        user_role,
        source_filename,
        batch_date,
        loaded_at,
        -- Keep raw values for debugging
        amount as _raw_amount,
        transaction_time as _raw_transaction_time
    FROM source
    WHERE store_token != 'store_token' -- Filter out header row if present
),

validated AS (
    SELECT
        *,
        CASE
            WHEN amount IS NULL AND _raw_amount IS NOT NULL THEN 'Invalid Amount Format'
            WHEN transaction_time IS NULL AND _raw_transaction_time IS NOT NULL THEN 'Invalid Timestamp Format'
            ELSE NULL
        END as validation_error
    FROM cleaned
)

SELECT * FROM validated
