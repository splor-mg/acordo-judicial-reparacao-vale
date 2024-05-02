library(dplyr)
library(validate)
library(glue)

test_that("Valores por contrato antes e depois dos cruzamentos", {
  chave_contratos <- dplyr::distinct(exec_desp_projetos_vale, uo_cod, num_contrato_saida)
  
  # filtra a tabela siad$compras por cada combinação uo_cod|num_contrato_saida existente na tabela contratos
  contratos_vale_pre_join <- semi_join(siad$compras, chave_contratos, by = c("uo_cod", "num_contrato_saida")) |> 
                             summarize(vlr_total_atualizado = sum(vlr_total_atualizado), .by = c("uo_cod", "num_contrato_saida"))
  
  contratos_vale_pos_join <- result[, .(vlr_total_atualizado_joined = unique(VLR_TOTAL_ATUALIZADO_CONTRATO)), .(UO_COD, NUM_CONTRATO_SAIDA)]
  names(contratos_vale_pos_join) <- tolower(names(contratos_vale_pos_join))
  
  contratos_vale <- merge(contratos_vale_pos_join, contratos_vale_pre_join, all = TRUE, by = c("uo_cod", "num_contrato_saida"))
  
  contratos_vale <- checksplanejamento:::as_accounting(contratos_vale)
  report <- check_that(contratos_vale, vlr_total_atualizado == vlr_total_atualizado_joined)
  valid <- summary(report)$fails == 0
  if (!valid) {
    fails <- validate::violating(contratos_vale, report)
    msg <- glue_data(fails, "'vlr_total_atualizado' do contrato {num_contrato_saida} diferente para UO {uo_cod} entre base original ({vlr_total_atualizado}) e base agregada ({vlr_total_atualizado_joined})")
    purrr::walk(msg, logger::log_warn)
  }
  expect_true(valid)
})
