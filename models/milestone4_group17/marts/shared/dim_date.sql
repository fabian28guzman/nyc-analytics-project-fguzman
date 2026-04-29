-- Date dimension shared by both housing violations and 311 requests

WITH all_dates AS (
   -- Get dates from 311 requests
   SELECT DISTINCT CAST(created_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_311_service_req') }}
   WHERE created_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(closed_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_311_service_req') }}
   WHERE closed_date IS NOT NULL

   UNION DISTINCT

   -- Get dates from housing violations
   SELECT DISTINCT CAST(inspection_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE inspection_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(approved_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE approved_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(original_certify_by_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE original_certify_by_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(original_correct_by_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE original_correct_by_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(new_certify_by_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE new_certify_by_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(new_correct_by_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE new_correct_by_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(certified_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE certified_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(nov_issue_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE nov_issue_date IS NOT NULL

   UNION DISTINCT

   SELECT DISTINCT CAST(current_status_date AS DATE) AS full_date
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE current_status_date IS NOT NULL

),

date_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key(['full_date']) }} AS date_key,
       full_date,
       EXTRACT(DAY FROM full_date) AS day,
       EXTRACT(MONTH FROM full_date) AS month,
       EXTRACT(YEAR FROM full_date) AS year,
       FORMAT_DATE('%A', full_date) AS day_of_week,

       CASE
           WHEN EXTRACT(MONTH FROM full_date) IN (10, 11, 12, 1, 2, 3, 4) THEN TRUE
           ELSE FALSE
       END AS is_heating_season,

       CASE
           WHEN EXTRACT(MONTH FROM full_date) >= 10
               THEN CONCAT(CAST(EXTRACT(YEAR FROM full_date) AS STRING), '-', CAST(EXTRACT(YEAR FROM full_date) + 1 AS STRING))
           WHEN EXTRACT(MONTH FROM full_date) <= 4
               THEN CONCAT(CAST(EXTRACT(YEAR FROM full_date) - 1 AS STRING), '-', CAST(EXTRACT(YEAR FROM full_date) AS STRING))
           ELSE NULL
       END AS heating_season_year

   FROM all_dates
)

SELECT * FROM date_dimension