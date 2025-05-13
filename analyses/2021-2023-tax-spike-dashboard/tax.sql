-- Script to gather exemptions by PIN for 2020-2023. Formats exemption columns
-- to be concatenated in R.
SELECT
    ptax.pin,
    ptax.year,
    SUBSTR(ptax.class, 1, 1) AS class,
    ptax.av_board AS bor_av,
    CASE WHEN ptax.exe_homeowner > 0 THEN 'hoe: yes' ELSE 'hoe: no' END AS hoe,
    CASE WHEN ptax.exe_senior > 0 THEN 'sr: yes' ELSE 'sr: no' END AS sr,
    CASE WHEN ptax.exe_freeze > 0 THEN 'frz: yes' ELSE 'frz: no' END AS frz,
    CASE
        WHEN ptax.exe_longtime_homeowner > 0 THEN 'lto: yes' ELSE 'lto: no'
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
    ptax.tax_bill_total AS ptax
FROM pin AS ptax
WHERE ptax.year BETWEEN '2020' AND '2023'
