{{
    config(
        materialized='incremental',
        unique_key='transaction_date'
    )
}}

WITH daily_sales AS (
    SELECT
        TO_DATE(transaction_time) as transaction_date,
        store_token,
        SUM(amount) as store_daily_sales
    FROM {{ ref('stg_sales') }}
    WHERE transaction_time IS NOT NULL

    {% if is_incremental() %}
        -- Optimization: Only scan source data for the "Lookback Window" (last 7 days).
        -- We re-aggregate these days entirely to ensure correct sums.
        AND transaction_time >= (SELECT DATEADD('day', -7, MAX(transaction_date)) FROM {{ this }})
    {% endif %}
    GROUP BY 1, 2
),

daily_stats AS (
    SELECT
        transaction_date,
        COUNT(DISTINCT store_token) as active_stores,
        SUM(store_daily_sales) as total_amount,
        AVG(store_daily_sales) as avg_store_sales
    FROM daily_sales
    GROUP BY 1
),

top_store_per_day AS (
    SELECT 
        transaction_date,
        store_token
    FROM (
        SELECT 
            transaction_date, 
            store_token, 
            RANK() OVER (PARTITION BY transaction_date ORDER BY store_daily_sales DESC) as rnk
        FROM daily_sales
    )
    WHERE rnk = 1
    -- Handle ties if needed, but requirements say "one of the stores"
    QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_date ORDER BY store_token) = 1
),

final_metrics AS (
    SELECT
        CURRENT_DATE() as snapshot_date,
        d.transaction_date,
        d.active_stores,
        d.total_amount,
        d.avg_store_sales,
        
        -- Cumulative sum for the month
        SUM(d.total_amount) OVER (
            PARTITION BY DATE_TRUNC('month', d.transaction_date) 
            ORDER BY d.transaction_date
        ) as monthly_cumulative_sales,

        t.store_token as top_store_token

    FROM daily_stats d
    LEFT JOIN top_store_per_day t ON d.transaction_date = t.transaction_date
)

SELECT * FROM final_metrics



ORDER BY transaction_date DESC
LIMIT 40
