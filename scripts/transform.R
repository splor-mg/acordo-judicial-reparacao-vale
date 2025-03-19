library(data.table)
library(dplyr)
library(writexl)
library(relatorios)

siafi <- dpm::read_datapackage("datapackages/siafi/datapackage.json")
vale <- dpm::read_datapackage("datapackages/acordo_vale_brumadinho/datapackage.json")
siad <- dpm::read_datapackage("datapackages/siad/datapackage.json")

projetos <- vale$projetos_vale[!duplicated(num_contrato_entrada)]

exec_rp <- siafi$restos_pagar[
  ano %in% 2021:2025 & num_contrato_entrada %in% projetos$num_contrato_entrada
]

exec_rp[, vlr_pago_rpnp := vlr_saldo_rpp + vlr_despesa_liquidada_rpnp - vlr_despesa_liquidada_pagar]
exec_rp[, vlr_pago_rp := vlr_pago_rpp + vlr_pago_rpnp]
exec_rp[, vlr_cancelado_rpp := vlr_cancelado_rpp + vlr_desconto_rpp]

exec_desp <- siafi$execucao[
  ano %in% 2021:2025 & num_contrato_entrada %in% projetos$num_contrato_entrada
]

execucao <- rbind(exec_desp, exec_rp, fill = TRUE)
cols = c(
  "vlr_empenhado",
  "vlr_cancelado_rpnp",
  "vlr_restabelecido_rpnp",
  "vlr_cancelado_rpp",
  "vlr_restabelecido_rpp",
  "vlr_liquidado",
  "vlr_despesa_liquidada_rpnp",
  "vlr_pago_orcamentario",
  "vlr_pago_rpnp",
  "vlr_pago_rpp")
setnafill(execucao, type = "const", fill = 0, cols = cols)

execucao <- execucao[
  ,
  .(vlr_empenhado = sum(vlr_empenhado),
    vlr_cancelado_rpnp = sum(vlr_cancelado_rpnp),
    vlr_restabelecido_rpnp = sum(vlr_restabelecido_rpnp),
    vlr_cancelado_rpp = sum(vlr_cancelado_rpp),
    vlr_restabelecido_rpp = sum(vlr_restabelecido_rpp),
    vlr_liquidado = sum(vlr_liquidado),
    vlr_liquidado_rpnp = sum(vlr_despesa_liquidada_rpnp),
    vlr_pago_orcamentario = sum(vlr_pago_orcamentario),
    vlr_pago_rpnp = sum(vlr_pago_rpnp),
    vlr_pago_rpp = sum(vlr_pago_rpp)
  ),
  .(uo_cod,
    num_contrato_saida,
    num_contrato_entrada)
]

valores_contratos <- siad$compras[
  ,
  .(vlr_total_atualizado = sum(vlr_total_atualizado)),
  .(uo_cod,
    num_contrato_saida)
]

nrows_execucao <- nrow(execucao)

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

dt[, data_inicio_vigencia_contrato_saida := as.Date(data_inicio_vigencia_contrato_saida)]
dt[, data_termino_vigencia_contrato_saida := as.Date(data_termino_vigencia_contrato_saida)]

col_order <- c("uo_cod",
               "num_contrato_entrada",
               "iniciativa",
               "num_processo_compra",
               "num_contrato_saida",
               "objeto_contrato_saida",
               "data_inicio_vigencia_contrato_saida",
               "data_termino_vigencia_contrato_saida",
               "vlr_total_atualizado",
               "vlr_empenhado",
               "vlr_cancelado_rpnp",
               "vlr_restabelecido_rpnp",
               "vlr_cancelado_rpp",
               "vlr_restabelecido_rpp",
               "vlr_liquidado",
               "vlr_liquidado_rpnp",
               "vlr_pago_orcamentario",
               "vlr_pago_rpnp",
               "vlr_pago_rpp")

setcolorder(dt, col_order)
setnames(dt, "vlr_total_atualizado", "vlr_total_atualizado_contrato")
setorderv(dt, c("uo_cod", "num_contrato_entrada", "num_processo_compra", "num_contrato_saida"))

names(dt) <- toupper(names(dt))
dt$ANO <- 2025
dt <- adiciona_desc(dt)
dt$ANO <- NULL
dt$ANEXO <- NULL
dt$VALOR_INICIATIVA <- NULL

fwrite(dt, "data/acordo-judicial-reparacao-vale.csv", bom = TRUE, dec = ",", sep = ";")
