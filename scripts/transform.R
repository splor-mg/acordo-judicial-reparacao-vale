library(toolkit)
library(spreadmart)
library(data.table)
library(dplyr)
library(writexl)
library(relatorios)

siafi <- read_datapackage("datapackages/siafi/datapackage.json")
vale <- read_datapackage("datapackages/acordo_vale_brumadinho/datapackage.json")
siad <- read_datapackage("datapackages/siad/datapackage.json")

projetos <- vale$projetos_vale[!duplicated(num_contrato_entrada)]

exec_rp <- siafi$restos_pagar[
  ano %in% 2021:2024 & num_contrato_entrada %in% projetos$num_contrato_entrada
]

exec_rp[, vlr_pago_rpnp := vlr_saldo_rpp + vlr_despesa_liquidada_rpnp - vlr_despesa_liquidada_pagar]
exec_rp[, vlr_pago_rp := vlr_pago_rpp + vlr_pago_rpnp]
exec_rp[, vlr_cancelado_rpnp := vlr_cancelado_rpnp - vlr_restabelecido_rpnp]
exec_rp[, vlr_cancelado_rpp := vlr_cancelado_rpp + vlr_desconto_rpp - vlr_restabelecido_rpp]

exec_desp <- siafi$execucao[
  ano %in% 2021:2024 & num_contrato_entrada %in% projetos$num_contrato_entrada
]

execucao <- join(exec_rp, exec_desp, 
                 by = c("ano", "uo_cod", "num_contrato_entrada", "num_contrato_saida"),
                 value.var = c("vlr_empenhado",
                               "vlr_cancelado_rpnp",
                               "vlr_cancelado_rpp",
                               "vlr_liquidado", 
                               "vlr_despesa_liquidada_rpnp",
                               "vlr_pago_orcamentario",
                               "vlr_pago_rpnp",
                               "vlr_pago_rpp"),
                 regex = FALSE)

valores_contratos <- siad$compras[
  ,
  .(vlr_total_atualizado = sum(vlr_total_atualizado)),
  .(uo_cod, 
    num_contrato_saida)
]

dt <- left_join(execucao, 
                valores_contratos, 
          by = c("uo_cod", "num_contrato_saida")) |> 
      left_join(projetos, "num_contrato_entrada")

info_contratos <- siad$compras[
  num_contrato_saida %in% dt$num_contrato_saida,
  .(uo_cod, 
    num_contrato_saida,
    num_processo_compra, 
    objeto_contrato_saida,
    data_inicio_vigencia_contrato_saida, 
    data_termino_vigencia_contrato_saida)
] |> unique()

dt <- left_join(dt, info_contratos, c("uo_cod", "num_contrato_saida"))

output <- dt[
  ,
  .(vlr_total_atualizado_contrato = sum(vlr_total_atualizado),
    vlr_empenhado = sum(vlr_empenhado),
    vlr_cancelado_rpnp = sum(vlr_cancelado_rpnp),
    vlr_cancelado_rpp = sum(vlr_cancelado_rpp),
    vlr_liquidado = sum(vlr_liquidado),
    vlr_liquidado_rpnp = sum(vlr_despesa_liquidada_rpnp),
    vlr_pago_orcamentario = sum(vlr_pago_orcamentario),
    vlr_pago_rpnp = sum(vlr_pago_rpnp),
    vlr_pago_rpp = sum(vlr_pago_rpp)
    ),
  .(uo_cod,
    num_contrato_entrada, 
    projeto, 
    num_processo_compra, 
    num_contrato_saida, 
    objeto_contrato_saida, 
    data_inicio_vigencia_contrato_saida, 
    data_termino_vigencia_contrato_saida)
]

output[, data_inicio_vigencia_contrato_saida := as.Date(data_inicio_vigencia_contrato_saida)]
output[, data_termino_vigencia_contrato_saida := as.Date(data_termino_vigencia_contrato_saida)]

names(output) <- toupper(names(output))
output$ANO <- 2024
output <- adiciona_desc(output)
output$ANO <- NULL

fwrite(output, "data/acordo-judicial-reparacao-vale.csv", bom = TRUE, dec = ",", sep = ";")

