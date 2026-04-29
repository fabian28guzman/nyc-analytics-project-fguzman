-- Grain: one row per violation

-- -- Pattern for fact table model:
-- --   WITH
-- --     [fact_source] AS (SELECT * FROM staging),
-- --     [dim1] AS (SELECT surrogate_key, join_keys FROM dim1),
-- --     [dim2] AS (SELECT surrogate_key, join_keys FROM dim2),
-- --     ...
-- --     final AS (
-- --       SELECT
-- --         [fact fields from staging data, maybe renamed with AS ___],
-- --         [dim1 surrogate key] as dim1_key_or_whatever_name,
-- --         [dim2 surrogate key] as dim2_key_or_whatever_name, ...
-- --       FROM [fact_source]
-- --       LEFT JOIN [dim1] ON ... (join fields match)
-- --       LEFT JOIN [dim2] ON ... (join fields match)
-- --     )
-- --   SELECT * FROM final

-- Getting all the data from the staging nyc_open_housing_violation
WITH violation_table AS (
    SELECT * FROM {{ref('stg_nyc_open_housing_violations')}}
),

-- Getting all the dimensions that was created
-- Starting with the date dimension
dim_date AS (
    SELECT date_key, full_date FROM {{ref('dim_date')}}
),

-- Location dimension
dim_location AS (
    SELECT location_key, borough, zipcode, community_board, council_district
    FROM {{ref("dim_location")}}
),

-- Building Location dimension
dim_building_location AS (
    SELECT building_key, bin, building_id, house_number, street_name, zip, borough, low_house_number, high_house_number,
    street_code
    FROM {{ref("dim_building_location")}}
),

-- Violation Status dimension
dim_violation_status AS (
    SELECT violation_status_key, current_status_id, current_status, violation_status
    FROM {{ref("dim_violation_status")}}
),

-- Violation Type dimension
dim_violation_type AS (
    SELECT violation_type_key, order_number, violation_class, rent_impairing, nov_type, nov_description
    FROM {{ref("dim_violation_type")}}
),

-- Creating final Fact TABLE

final AS (
    SELECT
        -- Creating a surrogatew key for the FACT Table
        {{dbt_utils.generate_surrogate_key(['v.violation_id'])}} AS violation_key,

        -- Natural Key
        v.violation_id,

        -- Foriegn Keys
        d_inspection.date_key AS inspection_date_key,
        d_approve.date_key AS approved_date_key,
        d_original_certify.date_key AS original_certify_by_date_key,
        d_original_correct.date_key AS original_correct_by_date_key,
        d_new_certify.date_key AS new_certify_by_date_key,
        d_new_correct.date_key AS new_correct_by_date_key,
        d_certified_date.date_key AS certified_date_key,
        d_nov.date_key AS nov_issue_date_key,
        d_current_status.date_key AS current_status_date_key,

        -- References to dimesion table that arent dates
        loc.location_key,
        vs.violation_status_key,
        vt.violation_type_key,
        dbl.building_key,

        -- Other fields
        DATE_DIFF(v.approved_date, v.inspection_date, day) AS days_between_inspection_to_approve,
        DATE_DIFF(v.current_status_date, v.inspection_date, day) AS days_between_inspection_to_current,
        DATE_DIFF(v.current_status_date, v.approved_date, day) AS days_between_approved_to_current,
        v.latitude,
        v.longitude,

        1 AS violation_count
        -- 

    FROM violation_table v

    -- Left Join with date table
    LEFT JOIN dim_date d_inspection
        ON CAST (v.inspection_date AS DATE) = d_inspection.full_date

    LEFT JOIN dim_date d_approve
        ON CAST (v.approved_date AS DATE) = d_approve.full_date

    LEFT JOIN dim_date d_original_certify
        ON CAST (v.original_certify_by_date AS DATE) = d_original_certify.full_date

    LEFT JOIN dim_date d_original_correct
        ON CAST (v.original_correct_by_date AS DATE) = d_original_correct.full_date
    
    LEFT JOIN dim_date d_new_certify
        ON CAST (v.new_certify_by_date AS DATE) = d_new_certify.full_date

    LEFT JOIN dim_date d_new_correct
        ON CAST (v.new_correct_by_date AS DATE) = d_new_correct.full_date
    
    LEFT JOIN dim_date d_certified_date
        ON CAST (v.certified_date AS DATE) = d_certified_date.full_date

    LEFT JOIN dim_date d_nov
        ON CAST (v.nov_issue_date AS DATE) = d_nov.full_date

    LEFT JOIN dim_date d_current_status
        ON CAST (v.current_status_date AS DATE) = d_current_status.full_date
    
    -- Joining Location dimension
    LEFT JOIN dim_location loc
        ON v.borough = loc.borough
        AND v.zip = loc.zipcode
        AND v.community_board = loc.community_board
        AND v.council_district = loc.council_district
    
    -- Joining dim_violation_status
    LEFT JOIN dim_violation_status vs 
        ON v.current_status_id = vs.current_status_id
        AND v.current_status = vs.current_status
        AND v.violation_status = vs.violation_status

    -- Joining dim_violation_type
    LEFT JOIN dim_violation_type vt 
        ON v.order_number = vt.order_number
        AND v.violation_class = vt.violation_class
        AND v.rent_impairing = vt.rent_impairing
        AND v.nov_type = vt.nov_type
        AND v.nov_description = vt.nov_description

    -- Joining dim_building_location
    LEFT JOIN dim_building_location dbl 
        ON v.bin = dbl.bin
        AND v.building_id = dbl.building_id
        AND v.house_number = dbl.house_number
        AND v.street_name = dbl.street_name
        AND v.zip = dbl.zip
        AND v.borough = dbl.borough
        AND v.low_house_number = dbl.low_house_number
        AND v.high_house_number = dbl.high_house_number
        AND v.street_code = dbl.street_code

)

-- Showing the final table
SELECT * FROM final