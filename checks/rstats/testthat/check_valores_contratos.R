library(validate)

test_that("Valores por contrato antes e depois dos cruzamentos", {
  projetos <- vale$projetos_vale[["num_contrato_entrada"]]
  contratos <- siafi$execucao[num_contrato_entrada %in% projetos] |> dplyr::distinct(uo_cod, num_contrato_saida)
  
  raw <- semi_join(siad$compras, contratos, by = c("uo_cod", "num_contrato_saida"))
  raw <- raw[, .(vlr_total_atualizado = sum(vlr_total_atualizado)), .(uo_cod, num_contrato_saida)]
  
  transformed <- result[, .(vlr_total_atualizado_joined = sum(VLR_TOTAL_ATUALIZADO_CONTRATO, na.rm = TRUE)), .(UO_COD, NUM_CONTRATO_SAIDA)]
  names(transformed) <- tolower(names(transformed))
  
  dt <- merge(transformed, raw, all = TRUE, by = c("uo_cod", "num_contrato_saida"))
  
  dt <- checksplanejamento:::as_accounting(dt)
  report <- check_that(dt, vlr_total_atualizado == vlr_total_atualizado_joined)
  summary(report)
  validate::violating(dt, report, include_missing = TRUE)
})
