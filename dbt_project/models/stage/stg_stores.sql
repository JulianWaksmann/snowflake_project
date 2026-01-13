{{
    config(
        materialized='incremental',
        unique_key='store_token'
    )
}}

WITH source AS (
    SELECT * FROM {{ source('retail', 'stores') }}
    {% if is_incremental() %}
    WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})
    {% endif %}
),

cleaned AS (
    SELECT
        -- IDs
        TRIM(store_token) AS store_token,
        TRIM(store_group) AS store_group,
        TRIM(store_name) AS store_name,
        
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
            PARTITION BY store_token 
            ORDER BY loaded_at DESC
        ) AS row_num
    FROM cleaned
)

SELECT 
    store_token,
    store_group,
    store_name,
    batch_date,
    loaded_at
FROM deduplicated
WHERE row_num = 1
