test_that("Valores por projeto antes e depois dos cruzamentos", {
  projetos <- vale$projetos_vale[["num_contrato_entrada"]]
  
  expect_equal(siafi$execucao[num_contrato_entrada %in% projetos, sum(vlr_empenhado)],
               result[, sum(VLR_EMPENHADO)])
  
  expect_equal(siafi$execucao[num_contrato_entrada %in% projetos, sum(vlr_liquidado)],
               result[, sum(VLR_LIQUIDADO)])

  expect_equal(siafi$execucao[num_contrato_entrada %in% projetos, sum(vlr_pago_orcamentario)],
               result[, sum(VLR_PAGO_ORCAMENTARIO)])

  expect_equal(siafi$restos_pagar[num_contrato_entrada %in% projetos, sum(vlr_despesa_liquidada_rpnp)],
               result[, sum(VLR_LIQUIDADO_RPNP)])
    
  expect_equal(siafi$restos_pagar[num_contrato_entrada %in% projetos, sum(vlr_pago_rpp)],
               result[, sum(VLR_PAGO_RPP)])

})
