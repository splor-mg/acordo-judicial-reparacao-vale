library(validate)
library(dplyr)
library(toolkit)
library(spreadmart)
library(data.table)
library(here)

siafi <- read_datapackage("datapackages/siafi/datapackage.json")
folha <- read_datapackage("https://raw.githubusercontent.com/splor-mg/armazem-siafi-restos-pagar-folha-dados/main/datapackage.json")

siafi$restos_pagar[, vlr_pago_rpnp := vlr_saldo_rpp + vlr_despesa_liquidada_rpnp - vlr_despesa_liquidada_pagar]
siafi$restos_pagar[, vlr_pago_rp := vlr_pago_rpp + vlr_pago_rpnp]
siafi$restos_pagar[, vlr_cancelado_rpnp := vlr_cancelado_rpnp - vlr_restabelecido_rpnp]
siafi$restos_pagar[, vlr_cancelado_rpp := vlr_cancelado_rpp + vlr_desconto_rpp - vlr_restabelecido_rpp]

exec_rp_outros <- siafi$restos_pagar[
  ,
  .(
    vlr_inscrito_rpp_outros = sum(vlr_inscrito_rpp),
    vlr_pago_rpp_outros = sum(vlr_pago_rpp),
    vlr_cancelado_rpp_outros = sum(vlr_cancelado_rpp),
    vlr_inscrito_rpnp = sum(vlr_inscrito_rpnp),
    vlr_despesa_liquidada_rpnp = sum(vlr_despesa_liquidada_rpnp),
    vlr_pago_rpnp = sum(vlr_pago_rpnp),
    vlr_cancelado_rpnp = sum(vlr_cancelado_rpnp)
  ),
  ano
]

exec_rp_folha <- folha$restos_pagar_folha[
  ,
  .(
    vlr_inscrito_rpp_folha = sum(vlr_inscrito_rpp_folha),
    vlr_pago_rpp_folha = sum(vlr_pago_rpp_folha),
    vlr_cancelado_rpp_folha = sum(vlr_cancelado_rpp_folha)
  ),
  ano
]

exec_rp <- left_join(exec_rp_outros, exec_rp_folha, "ano") |> as.data.table()

exec_rp[, vlr_inscrito_rpp := vlr_inscrito_rpp_outros + vlr_inscrito_rpp_folha]
exec_rp[, vlr_pago_rpp := vlr_pago_rpp_outros + vlr_pago_rpp_folha]
exec_rp[, vlr_cancelado_rpp := vlr_cancelado_rpp_outros + vlr_cancelado_rpp_folha]

exec_rp <- exec_rp[ano %in% 2021:2023, .(vlr_inscrito_rpp, 
            vlr_pago_rpp, 
            vlr_cancelado_rpp,
            vlr_inscrito_rpnp,
            vlr_despesa_liquidada_rpnp,
            vlr_pago_rpnp,
            vlr_cancelado_rpnp),
        ano]

rp_publicado <- fread(here("checks/rp_publicados.csv"), dec = ",")

exec_rp - rp_publicado |> pp()
