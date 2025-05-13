-- Script to gather ptax data from Athena tax db. Formats exemption columns
-- to be concanenated in R.

-- Grab most recent census tract geoid for each PIN
WITH vpu AS (
    SELECT
        pin,
        nbhd_code AS nbhd,
        township_name AS township,
        tax_municipality_name AS municipality,
        ward_name AS ward,
        census_congressional_district_num AS congressional_district,
        census_state_representative_num AS state_rep_district,
        census_state_senate_num AS state_senate_district,
        cook_commissioner_district_num AS cook_commissioner_district,
        chicago_community_area_name AS chicago_community_area,
        ROW_NUMBER() OVER (PARTITION BY pin ORDER BY year DESC) AS rank
    FROM default.vw_pin_universe
    WHERE year < '2025'

)

SELECT
    ptax.pin,
    ptax.year,
    SUBSTR(ptax.class, 1, 1) AS class,
    ptax.av_board AS bor_av,
    CASE WHEN ptax.exe_homeowner > 0 THEN 'hoe: yes' ELSE 'hoe: no' END AS hoe,
    CASE WHEN ptax.exe_senior > 0 THEN 'sr: yes' ELSE 'sr: no' END AS sr,
    CASE WHEN ptax.exe_freeze > 0 THEN 'frz: yes' ELSE 'frz: no' END AS frz,
    CASE
        WHEN ptax.exe_longtime_homeowner > 0 THEN 'lto: yes' ELSE 'lot: no'
    END AS lto,
    CASE WHEN ptax.exe_disabled > 0 THEN 'dis: yes' ELSE 'dis: no' END AS dis,
    CASE
        WHEN ptax.exe_vet_returning > 0 THEN 'vetret: yes' ELSE 'vetret: no'
    END AS vetret,
    CASE
        WHEN
            ptax.exe_vet_dis_lt50
            + ptax.exe_vet_dis_50_69
            + ptax.exe_vet_dis_ge70
            > 0
            THEN 'vetdis: yes'
        ELSE 'vetdis: no'
    END AS vetdis,
    vpu.township,
    vpu.nbhd,
    NULLIF(ARRAY_JOIN(vpu.municipality, ', '), '') AS municipality,
    vpu.ward,
    vpu.congressional_district,
    vpu.state_rep_district,
    vpu.state_senate_district,
    vpu.cook_commissioner_district,
    vpu.chicago_community_area,
    ptax.tax_bill_total AS ptax
FROM tax.pin AS ptax
LEFT JOIN vpu
    ON ptax.pin = vpu.pin
    AND vpu.rank = 1
WHERE ptax.year BETWEEN '2020' AND '2023'
