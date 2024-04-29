library(checksplanejamento)
library(data.table)

siafi <- read_datapackage(here::here("datapackages/siafi/datapackage.json"))
vale <- read_datapackage(here::here("datapackages/acordo_vale_brumadinho/datapackage.json"))
siad <- read_datapackage(here::here("datapackages/siad/datapackage.json"))
result <- fread(here::here("data/acordo-judicial-reparacao-vale.csv"), dec = ",")
