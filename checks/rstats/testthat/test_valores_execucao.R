test_that("Valores por projeto antes e depois dos cruzamentos", {

  expect_equal(sum(exec_desp_projetos_vale$vlr_empenhado),
               sum(result$VLR_EMPENHADO))
  
  expect_equal(sum(exec_desp_projetos_vale$vlr_liquidado),
               sum(result$VLR_LIQUIDADO))

  expect_equal(sum(exec_desp_projetos_vale$vlr_pago_orcamentario),
               sum(result$VLR_PAGO_ORCAMENTARIO))

  expect_equal(sum(exec_rp_projetos_vale$vlr_despesa_liquidada_rpnp),
               sum(result$VLR_LIQUIDADO_RPNP))
    
  expect_equal(sum(exec_rp_projetos_vale$vlr_pago_rpp),
               sum(result$VLR_PAGO_RPP))
})
