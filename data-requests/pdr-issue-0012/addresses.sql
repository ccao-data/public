-- Gather addresses and mailing names
SELECT
    vpa.pin,
    vpa.year,
    vpa.prop_address_full,
    vpa.prop_address_city_name,
    vpa.prop_address_state,
    vpa.prop_address_zipcode_1,
    vpa.mail_address_name,
    vpu.lat,
    vpu.lon
FROM default.vw_pin_address AS vpa
LEFT JOIN default.vw_pin_universe AS vpu
    ON vpa.pin = vpu.pin AND vpa.year = vpu.year
