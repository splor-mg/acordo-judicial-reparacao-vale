library(checksplanejamento)
library(data.table)
library(dpm)

siafi <- read_datapackage(here::here("datapackages/siafi/datapackage.json"))
vale <- read_datapackage(here::here("datapackages/acordo_vale_brumadinho/datapackage.json"))
siad <- read_datapackage(here::here("datapackages/siad/datapackage.json"))
result <- fread(here::here("data/acordo-judicial-reparacao-vale.csv"), dec = ",")

exec_desp_projetos_vale <- siafi$execucao[num_contrato_entrada %in% vale$projetos_vale$num_contrato_entrada]
exec_rp_projetos_vale <- siafi$restos_pagar[num_contrato_entrada %in% vale$projetos_vale$num_contrato_entrada]
