-- Violation Status Dimension - Each row represents a violation status

WITH violation_status_table AS (
    SELECT
        current_status_id,
        current_status,
        violation_status

    FROM {{ref('stg_nyc_open_housing_violations')}}
    GROUP BY
        current_status_id,
        current_status,
        violation_status
),

violation_status_dimension AS (
    SELECT
        {{
            dbt_utils.generate_surrogate_key(
            [
            'current_status_id',
            'current_status',
            'violation_status'  
            ]
            )
        }} AS violation_status_key,

        current_status_id,
        current_status,
        violation_status

    FROM violation_status_table
)

SELECT * FROM violation_status_dimension