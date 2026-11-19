library(arrow)
library(DBI)
library(dplyr)
library(noctua)
library(openxlsx)

# I'd like a bulk extract of the legal/subdivision fields from iasworld.legdat,
# at PIN level. From your public dbt schema (iasworld.legdat.yml) and
# service-sqoop-iasworld/tables/LEGDAT.sql, the columns I'm after are: parid,
# taxyr, subdiv, subdnum, sublot, subblck, legal1, legal2, legal3, legdesc
public_folder <- Sys.getenv("AWS_PUBLIC_FOLDER")

noctua_options(unload = TRUE)
AWS_ATHENA_CONN_NOCTUA <- dbConnect(noctua::athena(), rstudio_conn_tab = FALSE)

query <- "
	SELECT leg.parid,
		leg.taxyr,
		leg.subdiv,
		leg.subdnum,
		leg.sublot,
		leg.subblck,
		leg.legal1,
		leg.legal2,
		leg.legal3,
		leg.legdesc
	FROM iasworld.legdat AS leg
	-- Join on pardat to make sure we don't include any of the PINs that have
	-- be reactivated for the treasurer.
	INNER JOIN iasworld.pardat AS par ON leg.parid = par.parid
		AND leg.taxyr = par.taxyr
		AND par.cur = 'Y'
		AND par.deactivat is NULL
	WHERE leg.cur = 'Y'
		AND leg.deactivat is NULL
"

dbGetQuery(conn = AWS_ATHENA_CONN_NOCTUA, query) %>%
  write_parquet(paste0(public_folder, "pdr-issue-0056.parquet"))
