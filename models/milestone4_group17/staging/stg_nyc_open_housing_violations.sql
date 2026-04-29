-- Clean and standardize NYC housing maintenance code violations data
-- One row per violation record

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_housing_maintenance_code_violations') }}
),

cleaned AS (
    SELECT
        -- Keep all other columns except ones transformed below
        * EXCEPT (
            violationid,
            buildingid,
            registrationid,
            boroid,
            borough,
            zip,
            housenumber,
            lowhousenumber,
            highhousenumber,
            streetname,
            streetcode,
            apartment,
            story,
            class,
            inspectiondate,
            approveddate,
            originalcertifybydate,
            originalcorrectbydate,
            newcertifybydate,
            newcorrectbydate,
            certifieddate,
            ordernumber,
            novid,
            novdescription,
            novissueddate,
            currentstatusid,
            currentstatus,
            currentstatusdate,
            novtype,
            violationstatus,
            rentimpairing,
            latitude,
            longitude,
            communityboard,
            councildistrict,
            bin,
            bbl,
            nta
        ),

        -- Identifiers
        CAST(violationid AS STRING) AS violation_id,
        CAST(buildingid AS STRING) AS building_id,
        CAST(registrationid AS STRING) AS registration_id,
        CAST(boroid AS STRING) AS boroid,
        CAST(ordernumber AS STRING) AS order_number,
        CAST(novid AS STRING) AS nov_id,
        CAST(currentstatusid AS STRING) AS current_status_id,
        CAST(bin AS STRING) AS bin,
        CAST(bbl AS STRING) AS bbl,

        -- Dates
        CAST(inspectiondate AS TIMESTAMP) AS inspection_date,
        CAST(approveddate AS TIMESTAMP) AS approved_date,
        CAST(originalcertifybydate AS TIMESTAMP) AS original_certify_by_date,
        CAST(originalcorrectbydate AS TIMESTAMP) AS original_correct_by_date,
        CAST(newcertifybydate AS TIMESTAMP) AS new_certify_by_date,
        CAST(newcorrectbydate AS TIMESTAMP) AS new_correct_by_date,
        CAST(certifieddate AS TIMESTAMP) AS certified_date,
        CAST(novissueddate AS TIMESTAMP) AS nov_issue_date,
        CAST(currentstatusdate AS TIMESTAMP) AS current_status_date,

        -- Violation details
        CAST(class AS STRING) AS violation_class,
        CAST(novdescription AS STRING) AS nov_description,
        CAST(currentstatus AS STRING) AS current_status,
        CAST(novtype AS STRING) AS nov_type,
        UPPER(TRIM(CAST(violationstatus AS STRING))) AS violation_status,
        CAST(rentimpairing AS STRING) AS rent_impairing,

        -- Zip cleaning
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN LENGTH(TRIM(CAST(zip AS STRING))) = 5 THEN TRIM(CAST(zip AS STRING))
            WHEN LENGTH(TRIM(CAST(zip AS STRING))) = 10
                 AND REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}-\d{4}$')
            THEN TRIM(CAST(zip AS STRING))
            ELSE NULL
        END AS zip,

        -- Borough: derive from boroid since borough is null
        CASE
            WHEN CAST(boroid AS STRING) = '1' THEN 'Manhattan'
            WHEN CAST(boroid AS STRING) = '2' THEN 'Bronx'
            WHEN CAST(boroid AS STRING) = '3' THEN 'Brooklyn'
            WHEN CAST(boroid AS STRING) = '4' THEN 'Queens'
            WHEN CAST(boroid AS STRING) = '5' THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        CAST(housenumber AS STRING) AS house_number,
        CAST(lowhousenumber AS STRING) AS low_house_number,
        CAST(highhousenumber AS STRING) AS high_house_number,
        CAST(streetname AS STRING) AS street_name,
        CAST(streetcode AS STRING) AS street_code,
        CAST(apartment AS STRING) AS apartment,
        CAST(story AS STRING) AS story,
        CAST(communityboard AS STRING) AS community_board,
        CAST(councildistrict AS STRING) AS council_district,
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,
        CAST(nta AS STRING) AS nta,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Minimal filtering
    WHERE violationid IS NOT NULL
      AND inspectiondate IS NOT NULL

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY violationid
        ORDER BY inspectiondate DESC
    ) = 1
)

SELECT * FROM cleaned