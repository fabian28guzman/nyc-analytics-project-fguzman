-- Channel dimension for 311 service requests

WITH channel_values AS (
    SELECT DISTINCT
        method_of_submission
    FROM {{ ref('stg_nyc_311_service_req') }}
    WHERE method_of_submission IS NOT NULL
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['method_of_submission']) }} AS channel_key,
        method_of_submission AS open_data_channel_type   -- 🔥 IMPORTANT FIX
    FROM channel_values
)

SELECT * FROM final