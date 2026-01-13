{{
    config(
        materialized='incremental',
        unique_key='batch_date'
    )
}}

WITH raw_stats AS (
    -- Count everything from RAW, grouped by batch_date
    SELECT 
        batch_date,
        COUNT(*) as total_raw_rows
    FROM {{ source('retail', 'sales') }}
    GROUP BY 1
),

valid_stats AS (
    -- Count valid/deduplicated rows from STAGE
    SELECT 
        batch_date,
        COUNT(*) as total_valid_rows,
        MAX(loaded_at) as max_loaded_date
    FROM {{ ref('stg_sales') }}
    GROUP BY 1
),

joined AS (
    SELECT
        CURRENT_DATE() as snapshot_date,
        COALESCE(r.batch_date, v.batch_date) as batch_date,
        COALESCE(r.total_raw_rows, 0) as total_raw_rows,
        COALESCE(v.total_valid_rows, 0) as total_valid_rows,
        (COALESCE(r.total_raw_rows, 0) - COALESCE(v.total_valid_rows, 0)) as total_ignored_rows,
        v.max_loaded_date as processing_date -- Approx processing time
    FROM raw_stats r
    FULL OUTER JOIN valid_stats v ON r.batch_date = v.batch_date
)

SELECT * FROM joined

{% if is_incremental() %}
    -- Safety Lookback: Reprocess last 3 days to catch multiple files/updates for the same batch_date
    WHERE batch_date >= (SELECT DATEADD('day', -3, MAX(batch_date)) FROM {{ this }})
{% endif %}

ORDER BY batch_date DESC
LIMIT 40
