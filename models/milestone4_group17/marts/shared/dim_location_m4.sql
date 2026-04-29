-- Location dimension shared by both housing violations and 311 service requests

WITH all_locations AS (
   -- Get locations from 311 requests
   SELECT DISTINCT
      borough,
      incident_zip AS zipcode,
      community_board,
      council_district
   FROM {{ ref('stg_nyc_311_service_req') }}
   WHERE borough IS NOT NULL

   UNION DISTINCT

   -- Get locations from housing violations
   SELECT DISTINCT
       borough,
       zip AS zipcode,
       community_board,
       council_district
   FROM {{ ref('stg_nyc_open_housing_violations') }}
   WHERE borough IS NOT NULL
),

location_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key([
           'borough',
           'zipcode',
           'community_board',
           'council_district'
       ]) }} AS location_key,
       borough,
       zipcode,
       community_board,
       council_district
   FROM all_locations
)

SELECT * FROM location_dimension