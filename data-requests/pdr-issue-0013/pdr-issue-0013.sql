WITH incentive_classes AS (

    SELECT
        parid,
        taxyr,
        user16
    FROM iasworld.comdat
    WHERE deactivat IS NULL AND cur = 'Y'
    UNION
    SELECT
        parid,
        taxyr,
        user16
    FROM iasworld.oby
    WHERE deactivat IS NULL AND cur = 'Y'
    UNION
    SELECT
        parid,
        taxyr,
        user16
    FROM iasworld.dweldat
    WHERE deactivat IS NULL AND cur = 'Y'

)

SELECT
    par.parid,
    par.taxyr,
    par.class,
    incentive_classes.user16
FROM iasworld.pardat AS par
LEFT JOIN incentive_classes
    ON par.parid = incentive_classes.parid
    AND par.taxyr = incentive_classes.taxyr
WHERE par.deactivat IS NULL
    AND par.cur = 'Y'
    AND incentive_classes.user16 IS NOT NULL
    AND par.taxyr = '2023'
