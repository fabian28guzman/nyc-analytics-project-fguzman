-- violation type dimesion

WITH violation_type_table AS (
    
    SELECT
        order_number,
        violation_class,
        rent_impairing,
        nov_type,
        nov_description

    FROM {{ref('stg_nyc_open_housing_violations')}}
    GROUP BY 
        order_number,
        violation_class,
        rent_impairing,
        nov_type,
        nov_description
),

violation_type_dimension AS (
    SELECT
        {{
            dbt_utils.generate_surrogate_key([
            'order_number',
            'violation_class',
            'rent_impairing',
            'nov_type',
            'nov_description'
            ])
        }} AS violation_type_key,
        
        order_number,
        violation_class,
        rent_impairing,
        nov_type,
        nov_description

    FROM violation_type_table
)

SELECT * FROM violation_type_dimension