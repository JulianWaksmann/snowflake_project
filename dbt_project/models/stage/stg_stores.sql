
WITH source AS (
    SELECT * FROM {{ source('retail', 'STORES') }}
),

deduplicated AS (
    SELECT 
        store_group,
        store_token,
        store_name,
        source_filename,
        batch_date,
        loaded_at,
        ROW_NUMBER() OVER (PARTITION BY store_token ORDER BY loaded_at DESC) as row_num
    FROM source
    WHERE store_group != 'store_group' -- Filter out header row if present
)

SELECT
    store_group,
    store_token,
    store_name,
    source_filename,
    batch_date,
    loaded_at
FROM deduplicated
WHERE row_num = 1
