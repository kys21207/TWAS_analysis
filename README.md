# SPrediXcan_run

## download immune cell
From https://zenodo.org/records/14346661 using the below step
All dataset were built using hg38.
### Install the package inborutis and load into library
library(inborutils)

doi <- "10.5281/zenodo.3923633" \n
local_path <- "data" \n
inborutils::download_zenodo(doi, local_path, quiet = TRUE) \n
list.files(local_path)

