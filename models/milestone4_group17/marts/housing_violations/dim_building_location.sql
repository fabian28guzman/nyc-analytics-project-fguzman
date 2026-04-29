-- housing violation dimension: One row per building location

WITH building_location AS (
SELECT
    bin,
    building_id,
    house_number,
    street_name,
    zip, 
    borough,
    low_house_number,
    high_house_number,
    street_code

FROM {{ref('stg_nyc_open_housing_violations')}}
WHERE bin IS NOT NULL
GROUP BY 
    bin,
    building_id,
    house_number,
    street_name,
    zip, 
    borough,
    low_house_number,
    high_house_number,
    street_code
),

building_location_dimension AS (
    SELECT
    {{  dbt_utils.generate_surrogate_key(
        [
        'bin',
        'building_id',
        'house_number',
        'street_name',
        'zip', 
        'borough',
        'low_house_number',
        'high_house_number',
        'street_code' 
        ]
    )

    }} as building_key,
    bin,
    building_id,
    house_number,
    street_name,
    zip, 
    borough,
    low_house_number,
    high_house_number,
    street_code

    FROM building_location
)

SELECT * FROM building_location_dimension