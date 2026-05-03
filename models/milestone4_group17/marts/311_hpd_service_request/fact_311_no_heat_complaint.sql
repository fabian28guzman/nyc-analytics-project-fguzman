-- Fact table for 311 HPD service requests

WITH base AS (
    SELECT *
    FROM {{ ref('stg_nyc_311_service_req') }}
),

joined AS (
    SELECT
        -- Primary key
        {{ dbt_utils.generate_surrogate_key(['request_id']) }} AS complaint_key,

        -- Natural key
        base.request_id AS unique_key,

        -- Date keys
        created.date_key AS created_date_key,
        closed.date_key AS closed_date_key,
        resolution_updated.date_key AS resolution_updated_date_key,

        -- Not available in staging
        NULL AS due_date_key,

        -- Location
        loc.location_key,

        -- Core attributes
        base.agency,

        -- Status
        status_dim.status_key,

        -- Channel
        channel_dim.channel_key,

        -- Problem + resolution (model-aligned naming)
        base.descriptor AS location_detail,
        base.descriptor_2 AS complaint_detail,

        -- Resolution metric
        CASE 
            WHEN base.closed_date IS NOT NULL
            THEN DATE_DIFF(DATE(base.closed_date), DATE(base.created_date), DAY)
            ELSE NULL
        END AS resolution_days,

        -- Additive metric
        1 AS complaint_count,

        -- Coordinates
        base.latitude,
        base.longitude

    FROM base

    -- LOCATION JOIN
    LEFT JOIN {{ ref('dim_location_m4') }} loc
        ON base.borough = loc.borough
       AND base.incident_zip = loc.zipcode
       AND base.community_board = loc.community_board
       AND base.council_district = loc.council_district

    -- STATUS JOIN
    LEFT JOIN {{ ref('dim_status_311') }} status_dim
        ON base.status = status_dim.status

    -- CHANNEL JOIN
    LEFT JOIN {{ ref('dim_channel') }} channel_dim
        ON base.method_of_submission = channel_dim.open_data_channel_type

    -- DATE JOIN: created
    LEFT JOIN {{ ref('dim_date_m4') }} created
        ON DATE(base.created_date) = created.full_date

    -- DATE JOIN: closed
    LEFT JOIN {{ ref('dim_date_m4') }} closed
        ON DATE(base.closed_date) = closed.full_date

    -- DATE JOIN: resolution updated (STRING → TIMESTAMP → DATE)
    LEFT JOIN {{ ref('dim_date_m4') }} resolution_updated
        ON DATE(CAST(base.resolution_action_updated_date AS TIMESTAMP)) = resolution_updated.full_date
)

SELECT * FROM joined