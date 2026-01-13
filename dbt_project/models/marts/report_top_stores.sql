WITH ranked_sales AS (
    SELECT
        TO_DATE(s.transaction_time) as transaction_date,
        s.store_token,
        st.store_name,
        SUM(s.amount) as total_sales,
        DENSE_RANK() OVER (PARTITION BY TO_DATE(s.transaction_time) ORDER BY SUM(s.amount) DESC) as ranking
    FROM {{ ref('stg_sales') }} s
    LEFT JOIN {{ ref('stg_stores') }} st ON s.store_token = st.store_token
    WHERE s.transaction_time IS NOT NULL
    GROUP BY 1, 2, 3
)

SELECT 
    CURRENT_DATE() as snapshot_date,
    transaction_date,
    ranking as range_top_id,
    total_sales,
    store_token,
    store_name
FROM ranked_sales
WHERE ranking <= 5
-- "Each transaction date must appear at most 5 times" (Top 5)
-- Report for "last 10 dates with transactions"
AND transaction_date IN (
    SELECT DISTINCT transaction_date 
    FROM ranked_sales 
    ORDER BY transaction_date DESC 
    LIMIT 10
)
ORDER BY transaction_date DESC, ranking ASC
