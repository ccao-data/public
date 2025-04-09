library(DBI)
library(dplyr)
library(glue)
library(here)
library(httr)
library(jsonlite)
library(openxlsx)
library(ptaxsim)
library(tidyr)

# NOTE: This code relies on the PTAXSIM package, which relies on a separate
# SQLite database to function correctly.
# This database must be installed and available in the working directory for
# the following code to work.
# Installation instructions can be found at
# ccao-data.github.io/ptaxsim/index.html#installation

# Once database is installed and available in the working directory, we can
# create the DB connection with the default name expected by PTAXSIM functions
ptaxsim_db_conn <- DBI::dbConnect(RSQLite::SQLite(), "./ptaxsim.db")

# Define base year to be used - base year should be two years prior to
# projected year
base_year <- 2023

# We use 2023 sales and assessment ratio studies from IDOR/
# Cook County commercial sales ratio study to determine the projected
# percent increase of property values for 2025 (we assume that assessment levels
# rise to market levels).
# Link to IDOR assessment ratios:
# tax.illinois.gov/content/dam/soi/en/web/tax/research/taxstats/propertytaxstatistics/documents/2022%20TABLE%201.pdf
# Link to CCAO commercial report w/ sales ratio study:0
# www.cookcountyil.gov/service/property-tax-reform-grou
class_2_assessment_ratio <- .081
class_3_assessment_ratio <- .0594
class_5_sale_ratio <- .7179


# Assessment ratios for classes 2, 3 for the North Tri from IDOR were converted
# to sales ratios (divide by level of assessment)
est_increases <- data.frame(
  class = c("2", "3", "5"),
  ratio =
    c(class_2_assessment_ratio, class_3_assessment_ratio, class_5_sale_ratio)
) %>%
  mutate(
    fmv_ratio = ifelse(stringr::str_sub(class, 1, 1) == "5", ratio,
      ratio / .1
    ),
    est_increase = round((1 - fmv_ratio) / fmv_ratio, 4)
  )

# We can query the CCAO Open Data parcel universe to get all PINs that fall
# within the north tri
base_url <- "https://datacatalog.cookcountyil.gov/resource/nj4t-kc8j.json"

north_tri_pins <- GET(
  base_url,
  query = list(
    year = 2023,
    triad_code = "2",
    `$select` = "pin, township_name, tax_code, class",
    `$limit` = 500000L
  )
)

north_tri_pins <- fromJSON(rawToChar(north_tri_pins$content))

# Create unique list of all tax codes associated with North tri PINs
north_tri_tax_codes <- unique(north_tri_pins$tax_code)

# The lookup_pin function queries the PTAXSIM database for all info related to
# the PIN's AV, EAV and exemptions
north_tri_pins_exemptions <- lookup_pin(
  base_year,
  north_tri_pins$pin
)

# Join the data with AV and exemption info to our other data.frame with
# PINs and tax codes
north_tri_pins <- north_tri_pins_exemptions %>%
  select(-class) %>%
  left_join(north_tri_pins, by = "pin") %>%
  mutate(
    exe_total = rowSums(across(starts_with("exe_"))),
    major_class_code = substr(class, 1, 1)
  )

# Query all active north tri agencies from base year
north_tri_agencies <- lookup_agency(
  as.integer(base_year),
  north_tri_tax_codes
) %>%
  filter(agency_total_ext > 0)

# Query TIF distributions by tax code
north_tri_tif_dists <- dbGetQuery(
  ptaxsim_db_conn,
  glue_sql("
           SELECT *
           FROM tif_distribution
           WHERE year = {base_year}
           AND tax_code_num IN ({north_tri_tax_codes*})",
    .con = ptaxsim_db_conn
  )
)

# Join projected EAV increase by class to base year north tri PINs
# Apply percent increases to the base year EAV
est_eav_tax_code <- north_tri_pins %>%
  left_join(est_increases, by = c("major_class_code" = "class")) %>%
  mutate(
    est_increase = replace_na(est_increase, 0),
    # Estimated increase is applied to total EAV, prior to removing exemptions
    est_eav = round(eav * (1 + est_increase)),
    # For PINs w/ senior freeze exemptions, their taxable EAV is calculated
    # with base year EAV minus total exemptions, as the senior freeze exemption
    # amount contingent on the base year EAV. For these PINs, their taxable
    # EAV will remain the frozen EAV amount, minus any other exemptions they
    # may have.
    taxable_frozen_eav = ifelse(
      exe_freeze > 0,
      eav - exe_total,
      NA
    ),
    # If PIN has senior freeze, future taxable EAV will be frozen EAV (minus
    # any other exemptions), otherwise, the projected EAV minus exemptions
    est_taxable_eav = if_else(
      exe_freeze > 0,
      taxable_frozen_eav,
      est_eav - exe_total
    ),
    base_year_taxable_eav =
      eav - exe_total
  ) %>%
  group_by(tax_code) %>%
  summarise(
    base_year_taxable_eav = sum(base_year_taxable_eav),
    est_taxable_eav = sum(est_taxable_eav)
  ) %>%
  left_join(north_tri_tif_dists %>%
    select(
      tax_code = tax_code_num,
      tax_code_frozen_eav
    ), by = "tax_code") %>%
  # If tax code is in TIF, keep EAV frozen if the estimated EAV is greater than frozen EAV
  mutate(
    base_year_taxable_eav = case_when(
      tax_code_frozen_eav <= base_year_taxable_eav ~
        tax_code_frozen_eav,
      TRUE ~ base_year_taxable_eav
    ),
    est_taxable_eav = case_when(
      tax_code_frozen_eav <= est_taxable_eav ~
        tax_code_frozen_eav,
      TRUE ~ est_taxable_eav
    ),
    added_tax_code_eav = est_taxable_eav - base_year_taxable_eav
  )

# Sum the calculated base and projected EAV to agency level, these amounts will
# be used in Excel WB to calculate agency tax rates
agencies_new_eav <- north_tri_agencies %>%
  left_join(est_eav_tax_code, by = "tax_code") %>%
  group_by(agency_name, agency_num, agency_major_type) %>%
  summarise(
    agency_total_ext = first(agency_total_ext),
    agency_base_year_eav_clerk = first(as.numeric(agency_total_eav)),
    # Sum base year EAV to answer question,
    # how off are we from clerk's reported EAV by agency?
    agency_base_year_eav_calc = sum(base_year_taxable_eav),
    added_agency_eav = sum(added_tax_code_eav)
  )

# Define anticipated agency levy growth from 2023 to 2025
# We assume a 4% yoy growth for agency levies, meaning an 8% growth for 2023-2025
levy_perc_growth <- .08

# Calculate the agency tax rates, calculating new base by adding
# "est_added_agency_eav_25" to the "agency_base_year_eav_clerk" in order
# to account for non-north tri portions of the base
agency_rates <- agencies_new_eav %>%
  mutate(
    est_agency_ext_25 = agency_total_ext * (1 + levy_perc_growth),
    est_agency_eav_25 = agency_base_year_eav_clerk + added_agency_eav,
    est_agency_rate_25 = est_agency_ext_25 / est_agency_eav_25,
    act_agency_rate_23 = agency_total_ext / agency_base_year_eav_clerk
  ) %>%
  left_join(
    north_tri_agencies %>%
      filter(year == base_year) %>%
      select(
        tax_code, agency_num,
        agency_minor_type
      ),
    by = "agency_num"
  ) %>%
  select(
    tax_code,
    agency_num,
    agency_name,
    agency_major_type,
    agency_minor_type,
    act_agency_ext_23 = agency_total_ext,
    act_agency_eav_23 = agency_base_year_eav_clerk,
    est_agency_ext_25,
    est_agency_eav_25,
    act_agency_rate_23,
    est_agency_rate_25
  )

tax_code_rates <- agency_rates %>%
  group_by(tax_code) %>%
  summarise(
    tax_code_rate_2023 = sum(act_agency_rate_23),
    estimated_tax_code_rate_2025 = sum(est_agency_rate_25)
  )

# Prep and export Excel workbook to be used for final deliverable
wb <- createWorkbook()

style_price <- createStyle(numFmt = "$#,##0")
style_pct <- createStyle(numFmt = "PERCENTAGE")

addWorksheet(wb, "TaxCodeRates")
writeDataTable(wb, 1, tax_code_rates)
addStyle(
  wb, 1,
  style = style_pct,
  rows = 1:10000, cols = 2:3,
  gridExpand = TRUE
)

addWorksheet(wb, "AgencyRates")
writeDataTable(wb, 2, agency_rates)
addStyle(
  wb, 2,
  style = style_price,
  rows = 1:10000, cols = 6:9,
  gridExpand = TRUE
)
addStyle(
  wb, 2,
  style = style_pct,
  rows = 1:10000, cols = 10:11,
  gridExpand = TRUE
)

saveWorkbook(wb, "Tax_Rate_Estimates_23_25.xlsx",
  overwrite = TRUE
)
