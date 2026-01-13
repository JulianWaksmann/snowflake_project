{{
    config(
        materialized='incremental',
        unique_key=['store_token', 'transaction_id']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('retail', 'sales') }}
    {% if is_incremental() %}
    -- Only process rows that arrived after the last processing time
    WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})
    {% endif %}
),

cleaned AS (
    SELECT
        -- IDs
        TRIM(store_token) AS store_token,
        TRIM(transaction_id) AS transaction_id,
        TRIM(receipt_token) AS receipt_token,
        
        -- Timestamp Parsing (Format: 20211001T174600.000)
        -- We handle potential formats. If standard ISO, TRY_TO_TIMESTAMP works. 
        -- Given format 'YYYYMMDD"T"HHMISS.FF3', we might need custom parsing if standard fails.
        -- Assuming standard ISO8601-like provided in requirements.
        TRY_TO_TIMESTAMP(transaction_time, 'YYYYMMDD"T"HHMISS.FF3') AS transaction_time,

        -- Amount Cleaning (Remove '$' and cast)
        TRY_CAST(REPLACE(amount, '$', '') AS NUMBER(11,2)) AS amount,

        TRIM(source_id) AS source_id,
        TRIM(user_role) AS user_role,

        -- Metadata
        source_filename,
        batch_date,
        loaded_at

    FROM source
    WHERE store_token != 'store_token' -- Filter Header Rows
      AND store_token IS NOT NULL
),

deduplicated AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY store_token, transaction_id 
            ORDER BY loaded_at DESC
        ) AS row_num
    FROM cleaned
)

SELECT 
    store_token,
    transaction_id,
    receipt_token,
    transaction_time,
    amount,
    source_id,
    user_role,
    batch_date,
    loaded_at
FROM deduplicated
WHERE row_num = 1
