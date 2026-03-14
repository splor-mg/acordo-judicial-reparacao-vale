import os
import io
import json
import pandas as pd
from frictionless import Package, Resource
from curl_cffi import requests

url = "https://dados.mg.gov.br/dataset/d7840175-2445-4ab3-84eb-ca645f58db31/resource/c57a6e00-a731-442b-81a5-7822b1375130/download/iniciativas_acordo_judicial_reparacao_vale.csv"

print("Iniciando download com bypass de firewall e TLS (curl_cffi)...")

try:
    # Faz o download mascarado de navegador Chrome para evitar o Erro 403 e problemas de SSL
    response = requests.get(url, impersonate="chrome120", verify=False, timeout=300)
    
    if response.status_code != 200:
        raise RuntimeError(f"O servidor retornou HTTP {response.status_code}")

    print("Download concluído! Processando dados com pandas...")

    # Lê os dados em memória
    df = pd.read_csv(io.StringIO(response.text), sep=";", decimal=",")

    # Renomeia a coluna como no código R original
    df.rename(columns={"codigo_iniciativa": "num_contrato_entrada"}, inplace=True)

    # Prepara o diretório de saída
    output_dir = "datapackages/acordo_vale_brumadinho"
    os.makedirs(output_dir, exist_ok=True)

    # Salva o arquivo CSV físico
    csv_path = os.path.join(output_dir, "projetos_vale.csv")
    df.to_csv(csv_path, sep=";", decimal=",", index=False, encoding="utf-8")

    print("Inferindo schema e criando o pacote de dados...")

    # Aponta para o arquivo físico recém-salvo para que o infer() consiga ler e adivinhar as colunas
    resource = Resource(path=csv_path, name="projetos_vale")
    resource.infer()

    # Cria o pacote e adiciona o recurso
    package = Package(name="acordo_vale_brumadinho")
    package.add_resource(resource)

    # Exporta para dicionário para fazermos o "downgrade" para o formato v1
    descriptor = package.to_dict()
    
    for res in descriptor.get("resources", []):
        # Força o caminho relativo apenas com o nome do arquivo (igual ao R)
        res["path"] = "projetos_vale.csv"
        # Retorna o profile clássico da v1
        res["profile"] = "tabular-data-resource"
        # Remove as chaves exclusivas da v2
        res.pop("type", None)
        res.pop("scheme", None)

    # Salva o arquivo datapackage.json no disco
    json_path = os.path.join(output_dir, "datapackage.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(descriptor, f, indent=2, ensure_ascii=False)

    print(f"Sucesso! Pacote idêntico ao do R salvo em: '{output_dir}'")

except Exception as e:
    print(f"Erro fatal durante a extração: {e}")