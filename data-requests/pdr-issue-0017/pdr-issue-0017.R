# See https://github.com/ccao-data/public/issues/17

library(dplyr)
library(openxlsx)
library(ptaxsim)
library(purrr)

# Create the DB connection with the default name expected by PTAXSIM functions
ptaxsim_db_conn <- DBI::dbConnect(RSQLite::SQLite(), "ptaxsim/ptaxsim.db")

# Gather a list of all '22 parcels
eav22 <- DBI::dbGetQuery(
  ptaxsim_db_conn,
  "
  SELECT DISTINCT pin
  FROM pin
  WHERE year = 2022
  "
) %>%
  pull(pin)

# Use tax_bill() to obtain EAVs for all '22 parcels, filter our rows that don't
# pertain to a parcel's municipality. It's worth noting here that this sample
# will NOT include all '22 parcels due to this filter - any parcels that don't
# include a "muni" component in their tax bill will not show up in this output
munis <- tax_bill(year_vec = 2022, pin_vec = eav22) %>%
  filter(agency_minor_type == "MUNI") %>%
  mutate("Major Class" = substr(class, 1, 1)) %>%
  rename("Minor Class" = class)

# Aggregate by class and municipality, output
c("Minor Class", "Major Class") %>%
  set_names() %>%
  map(function(x) {
    munis %>%
      summarise(
        num_pins = n(),
        median_eav = median(eav, na.rm = TRUE),
        total_eav = sum(eav, na.rm = TRUE),
        .by = c({{ x }}, agency_name)
      ) %>%
      select(
        Municipality = agency_name,
        Class = {{ x }},
        `Num Parcels` = num_pins,
        `Median EAV` = median_eav,
        `Total EAV` = total_eav
      )
  }) %>%
  write.xlsx("eavs22.xlsx")
