# See https://github.com/ccao-data/public/issues/12
library(aws.s3)
library(DBI)
library(dplyr)
library(noctua)
library(odbc)
library(openxlsx)
library(readr)

# Local output path
out_path <- "pdr-issue-0012.xlsx"

# create CCAODATA connection object
CCAODATA <- dbConnect(
  odbc(),
  .connection_string = Sys.getenv("DB_CONFIG_CCAODATA")
)

# Gather historical exempt parcels and join them to addresses and mailing names
left_join(
  dbGetQuery(CCAODATA, read_file("exempt_parcels.sql")),
  dbGetQuery(
    conn = dbConnect(noctua::athena()),
    read_file("addresses.sql")
  ),
  by = join_by(pin, year)
) |>
  write.xlsx(out_path)

# Upload to s3
aws.s3::put_object(
  out_path,
  paste0("s3://ccao-data-public-us-east-1/", out_path),
  multipart = TRUE
)

# Remove local file
file.remove(out_path)
