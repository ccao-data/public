library(arrow)
library(dplyr)
library(glue)
library(noctua)
library(openxlsx)
library(ptaxsim)
library(purrr)
library(readr)
library(skimr)
library(stringr)
library(tidycensus)
library(tidyr)

# Connect to Athena
noctua_options(unload = TRUE)
AWS_ATHENA_CONN_NOCTUA <- dbConnect(noctua::athena(), rstudio_conn_tab = FALSE)

# Very similar data can be retrieved using the CCAO Data Dept's open data, here:
# https://datacatalog.cookcountyil.gov/Property-Taxation/Assessor-Parcel-Universe-Current-Year-Only-/pabr-t5kh/about_data
# The only difference should be a very slight change in the universe of parcels
# available since this query uses 2024 and older data while the open data portal
# asset only has 2025 data.
universe <- dbGetQuery(
  conn = AWS_ATHENA_CONN_NOCTUA,
  read_file("universe.sql")
)

# Connect to PTAXSIM. See how to download and use PTAXSIM here:
# https://github.com/ccao-data/ptaxsim?tab=readme-ov-file#database-installation
ptaxsim_db_conn <- DBI::dbConnect(RSQLite::SQLite(), "data/input/ptaxsim-2023.0.0.db")

# Gather exemptions by PIN for 2020-2023. Formats exemption columns to be
# concatenated in R.
tax <- dbGetQuery(
  conn = ptaxsim_db_conn,
  read_file("tax.sql")
)

# Function to calculate diff between year and previous year exemptions
exe_diff <- \(x, years) {
  for (i in years) {
    var1 <- glue("exe_{i}vs{i + 1}")
    var2 <- sym(glue("exe_20{i}"))
    var3 <- sym(glue("exe_20{i + 1}"))

    x <- x %>%
      mutate(
        # See the walrus operator and tidy eval here:
        # https://www.tidyverse.org/blog/2020/02/glue-strings-and-tidy-eval/
        "{var1}" := case_when(
          !str_detect(!!var2, "yes") & !str_detect(!!var3, "yes") ~
            "no exe",
          str_detect(!!var2, "yes") & !str_detect(!!var3, "yes") ~
            "exe on/off",
          !str_detect(!!var2, "yes") & str_detect(!!var3, "yes") ~
            "exe off/on",
          !!var2 == !!var3 ~ "same exe",
          !!var2 != !!var3 ~ "diff exe",
        )
      ) %>%
      relocate(!!var1, .after = !!var3)
  }

  return(x)
}

# Write output
tax %>%
  left_join(universe, by = "pin") %>%
  relocate(ptax, .after = last_col()) %>%
  # Concatenate all exemptions into a single string
  unite("exe", hoe:vetdis, sep = ", ") %>%
  mutate(
    municipality = str_remove(municipality, "VILLAGE OF |CITY OF "),
    ward = str_replace(ward, "_", " "),
    across(c(township:chicago_community_area), str_to_title)
  ) %>%
  pivot_wider(
    id_cols = c(
      pin, nbhd, municipality, ward, township, congressional_district,
      state_rep_district, state_senate_district, cook_commissioner_district,
      chicago_community_area
    ),
    names_from = year,
    values_from = c(class, bor_av, exe, ptax),
    names_vary = "slowest",
  ) %>%
  # Remove any parcels that have never been class 2 2020-2023
  filter(if_any(starts_with("CLASS"), ~ . == "2")) %>%
  exe_diff(20:22) %>%
  rename_with(~ toupper(gsub("_", " ", .x)), .cols = everything()) %>%
  # Output data
  (\(output) {
    write.xlsx("data/output/tax_spike_dashboard.xlsx")
  })
