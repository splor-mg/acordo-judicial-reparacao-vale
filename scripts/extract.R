library(data.table)
library(frictionless)

dt <- fread("https://dados.mg.gov.br/dataset/d7840175-2445-4ab3-84eb-ca645f58db31/resource/c57a6e00-a731-442b-81a5-7822b1375130/download/iniciativas_acordo_judicial_reparacao_vale.csv", sep = ";", dec = ",")
setnames(dt, old = "codigo_iniciativa", new = "num_contrato_entrada")

package <- create_package()
package <- append(package, c(name = "acordo_vale_brumadinho"))
package <- add_resource(package, "projetos_vale", dt)

write_package(package, "datapackages/acordo_vale_brumadinho")
