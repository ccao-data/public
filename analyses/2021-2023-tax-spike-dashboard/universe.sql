-- Script to grab most recent census tract geoid for each PIN
WITH vpu AS (
    SELECT
        pin,
        nbhd_code AS nbhd,
        township_name AS township,
        NULLIF(ARRAY_JOIN(tax_municipality_name, ', '), '') AS municipality,
        ward_name AS ward,
        census_congressional_district_num AS congressional_district,
        census_state_representative_num AS state_rep_district,
        census_state_senate_num AS state_senate_district,
        cook_commissioner_district_num AS cook_commissioner_district,
        chicago_community_area_name AS chicago_community_area,
        ROW_NUMBER() OVER (
            PARTITION BY pin
            ORDER BY year DESC
        ) AS rank
    FROM default.vw_pin_universe
    WHERE year < '2025'

)

SELECT *
FROM vpu
WHERE rank = 1
