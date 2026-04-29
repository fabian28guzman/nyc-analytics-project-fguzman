-- Status dimension for 311 service requests

WITH status_values AS (
    SELECT DISTINCT
        status
    FROM {{ ref('stg_nyc_311_service_req') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['status']) }} AS status_key,
        status
    FROM status_values
)

SELECT * FROM final