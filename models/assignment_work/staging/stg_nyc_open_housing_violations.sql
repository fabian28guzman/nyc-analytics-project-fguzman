-- Clean and nyc_open_housing_maintenance_code_violations data
-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_housing_maintenance_code_violations') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           violationid,
           novid,
           currentstatusid,
           inspectiondate,
           approveddate,
           novissueddate,
           currentstatusdate,
           zip,
           borough,
           streetname,
           latitude,
           longitude
       ),

       -- Identifiers
       CAST(violationid AS STRING) AS violationid,
       CAST(novid AS STRING) AS novid,
       CAST(currentstatusid AS STRING) AS currentstatusid,

       -- Date/Time
       CAST(inspectiondate AS TIMESTAMP) AS inspectiondate,
       CAST(approveddate AS TIMESTAMP) AS approveddate,
       CAST(novissueddate AS TIMESTAMP) AS novissueddate,
       CAST(currentstatusdate AS TIMESTAMP) AS currentstatusdate,
       CAST(certifieddate AS TIMESTAMP) AS certifieddate,
       CAST(newcertifybydate AS TIMESTAMP) AS newcertifybydate,
       CAST(newcorrectbydate AS TIMESTAMP) AS newcorrectbydate,
       CAST(originalcertifybydate AS TIMESTAMP) AS originalcertifybydate,
       CAST(originalcorrectbydate AS TIMESTAMP) AS originalcorrectbydate,

       
       -- Request details
       CAST(violationstatus AS STRING) AS violationstatus,
       CAST(bin AS STRING) AS bin,
       CAST(buildingid AS INTEGER) AS buildingid,
       CAST(ordernumber AS STRING) AS ordernumber,
       CAST(class AS STRING) AS class,
       CAST(rentimpairing AS STRING) AS rentimpairing,
       CAST(novdescription AS STRING) AS novdescription,
       
       
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

       CAST(housenumber AS STRING) AS housenumber,
       CAST(lowhousenumber AS STRING) AS lowhousenumber,
       CAST(highhousenumber AS STRING) AS highhousenumber,
       CAST(streetname AS STRING) AS streetname,
       CAST(streetcode AS STRING) AS streetcode,
       CAST(apartment AS STRING) AS apartment,
       CAST(story AS STRING) AS story,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       -- #-- Clearer column name as well for this one
       -- # CAST(open_data_channel_type AS STRING) AS method_of_submission,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE violationid IS NOT NULL
   -- #(agency = 'DOT' OR agency_name LIKE '%Transportation%')
   AND inspectiondate IS NOT NULL
   AND CAST(inspectiondate AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY violationid ORDER BY inspectiondate DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table: stg_nyc_open_housing_violations