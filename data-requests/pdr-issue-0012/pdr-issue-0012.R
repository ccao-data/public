# See https://github.com/ccao-data/public/issues/13
library(aws.s3)
library(DBI)
library(dplyr)
library(noctua)
library(odbc)
library(openxlsx)
library(purrr)
library(readr)

# Local output path
out_path <- "pdr-issue-0012.xlsx"

# create CCAODATA connection object
CCAODATA <- dbConnect(odbc(), .connection_string = Sys.getenv("DB_CONFIG_CCAODATA"))

# Count net additions and subtractions over time
exempt_parcels <- dbGetQuery(CCAODATA, "
SELECT PIN, TAX_YEAR FROM AS_HEADBR WHERE CLASS = '0'

")


# Gather all 2023 parcels with non-NULL values for user16 (alt CDU) across the
# three iasWorld tables that contain that column and join descriptions for each
# value of user16 we're privy to.
left_join(
  # Gather alternate CDUs from comdat, oby, and dweldat
  dbGetQuery(
    conn = dbConnect(noctua::athena()),
    read_file("pdr-issue-0013.sql")
  ),
  # Ingest and consolidate CDU descriptions
  map(
    getSheetNames(file),
    function(x) {
      read.xlsx(file, sheet = x, startRow = 2) |>
        select(Value.2, Long.Desc)
    }
  ) |>
    bind_rows() |>
    distinct() |>
    mutate(Long.Desc = paste0(Long.Desc, collapse = ", "), .by = Value.2) |>
    distinct(),
  by = join_by(user16 == Value.2)
) |>
  rename("alt cdu" = "user16", "alt cdu description" = "Long.Desc") |>
  write.xlsx(out_path)

# Upload to s3
aws.s3::put_object(
  out_path,
  paste0("s3://ccao-data-public-us-east-1/", out_path)
  )

# Remove local file
file.remove(out_path)
