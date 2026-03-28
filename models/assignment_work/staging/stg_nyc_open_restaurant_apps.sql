-- Clean and standardize 311 DOT service request data
-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           globalid,
           time_of_submission,
           restaurant_name,
           legal_business_name,
           doing_business_as_dba,
           approved_for_sidewalk_seating,
           approved_for_roadway_seating,
           qualify_alcohol,
           seating_interest_sidewalk,
           healthcompliance_terms,
           zip,
           borough,
           business_address,
           street,
           latitude,
           longitude,
           open_data_channel_type
       ),

       -- Identifiers
       CAST(globalid AS STRING) AS globalid,

       -- Date/Time
       CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,
       
       -- Request details
       CAST(restaurant_name AS STRING) AS restaurant_name,
       CAST(legal_business_name AS STRING) AS legal_business_name,
       CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,
       CAST(approved_for_sidewalk_seating AS STRING) AS approved_for_sidewalk_seating,
       CAST(approved_for_roadway_seating AS STRING) AS approved_for_roadway_seating,
       CAST(qualify_alcohol AS STRING) AS qualify_alcohol,
       CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
       CAST(healthcompliance_terms AS STRING) AS healthcompliance_terms,
       
       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       CAST(business_address AS STRING) AS business_address,
       CAST(street AS STRING) AS street,
       CAST(cross_street_1 AS STRING) AS cross_street_1,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       #-- Clearer column name as well for this one
       # CAST(open_data_channel_type AS STRING) AS method_of_submission,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE globalid IS NOT NULL
   #(agency = 'DOT' OR agency_name LIKE '%Transportation%')
   AND time_of_submission IS NOT NULL
   AND CAST(time_of_submission AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY globalid ORDER BY created_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table: stg_nyc_open_restaurant_apps