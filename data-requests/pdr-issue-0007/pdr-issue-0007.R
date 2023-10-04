# See https://github.com/ccao-data/public/issues/7

# Load necessary libraries
library(ccao)
library(DBI)
library(dplyr)
library(here)
library(jsonlite)
library(noctua)
library(openxlsx)
library(purrr)
library(readr)
library(stringr)

# Establish database connections
AWS_ATHENA_CONN_NOCTUA <- dbConnect(
  noctua::athena(),
  aws_access_key_id = Sys.getenv("AWS_ACCESS_KEY_ID"),
  aws_secret_access_key = Sys.getenv("AWS_SECRET_ACCESS_KEY")
)

# Gather all PINs from Broadview for TY 2022
broadview <- dbGetQuery(
  conn = AWS_ATHENA_CONN_NOCTUA, "
SELECT
    vpa.pin,
    vpa.prop_address_full AS property_address,
    vpa.prop_address_city_name AS property_city,
    vpa.mail_address_name AS taxpayer_name,
    vpu.tax_tif_district_num,
    vpu.tax_tif_district_name,
    vpv.certified_tot,
    vpv.board_tot
FROM default.vw_pin_address AS vpa
LEFT JOIN default.vw_pin_universe AS vpu
    ON vpa.pin = vpu.pin
    AND vpa.year = vpu.year
LEFT JOIN default.vw_pin_value AS vpv
    ON vpa.pin = vpv.pin
    AND vpa.year = vpv.year
WHERE vpa.prop_address_city_name = 'BROADVIEW'
    AND vpa.year = '2022'
")

# Load 2022 BOR open data
bor <- read_json(
  paste0(
    "https://datacatalog.cookcountyil.gov/resource/7pny-nedm.json?",
    "$where=tax_year=2022&$limit=1000000"
  ),
  simplifyVector = TRUE
)

# Export for part 1
broadview |>
  inner_join(
    # Limit output to class 3 & 5
    bor %>% filter(substr(class, 1, 1) %in% c('3', '5')),
    by = c("pin" = "pin")
  ) %>%
  mutate(
    class = substr(class, 1, 3),
    pin = pin_format_pretty(pin, full_length = TRUE)
  ) |>
  select(-c(
    centroid_geom,
    tax_tif_district_num,
    tax_tif_district_name,
    certified_tot,
    board_tot
  )) |>
  relocate(class, .after = pin) |>
  write.xlsx(here("pdr-007.xlsx"))

# Export for part 2
part2 <- broadview |>
  mutate(in_tif = tax_tif_district_name != "[]") |>
  summarise(
    parcels = n(),
    ccao_av = sum(certified_tot),
    bor_av = sum(board_tot),
    .by = in_tif
  )

bind_rows(part2, c("in_tif" = NA, colSums(part2 %>% select(-in_tif))))
