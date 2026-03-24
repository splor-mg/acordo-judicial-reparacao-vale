import io
import json
import pandas as pd
from pathlib import Path
from frictionless import Package, describe
from curl_cffi import requests

url = "https://dados.mg.gov.br/dataset/d7840175-2445-4ab3-84eb-ca645f58db31/resource/c57a6e00-a731-442b-81a5-7822b1375130/download/iniciativas_acordo_judicial_reparacao_vale.csv"

print("Iniciando download com bypass de firewall e TLS (curl_cffi)...")

try:
    # 1. Download
    response = requests.get(url, impersonate="chrome120", verify=False, timeout=300)
    if response.status_code != 200:
        raise RuntimeError(f"O servidor retornou HTTP {response.status_code}")

    print("Download concluído! Processando dados com pandas...")

    # 2. Leitura e Limpeza (sep=";", decimal="," = formato da fonte; on_bad_lines tolera linhas com ";" extra no texto)
    df = pd.read_csv(
        io.StringIO(response.text),
        sep=";",
        decimal=",",
        engine="python",
        on_bad_lines="warn",
    )
    df.rename(columns={"codigo_iniciativa": "num_contrato_entrada"}, inplace=True)

    # 3. Preparação de Diretórios usando pathlib (Inspirado no snippet do SIAFI)
    output_dir = Path("datapackages") / "acordo_vale_brumadinho"
    output_dir.mkdir(parents=True, exist_ok=True)

    # 4. Salvamento do CSV
    csv_path = output_dir / "projetos_vale.csv"
    df.to_csv(csv_path, sep=",", decimal=".", index=False, encoding="utf-8")

    print("Gerando o pacote de dados com describe()...")

    # 5. Uso do describe() para inferir schema e capturar stats (tamanho, hash, etc.)
    resource = describe(str(csv_path), stats=True)
    resource.name = "projetos_vale" # Garante o nome correto do recurso

    # Monta o pacote
    package = Package(name="acordo_vale_brumadinho")
    package.add_resource(resource)

    # 6. Conversão segura e ajuste para o padrão v1 (Downgrade de chaves)
    descriptor = package.to_dict() if hasattr(package, "to_dict") else dict(package)
    
    for res in descriptor.get("resources", []):
        res["profile"] = "tabular-data-resource"
        res["path"] = "projetos_vale.csv"  # Caminho relativo direto
        res.pop("type", None)
        res.pop("scheme", None)

    # 7. Salvamento do JSON
    json_path = output_dir / "datapackage.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(descriptor, f, indent=2, ensure_ascii=False)

    print(f"Sucesso! Pacote idêntico ao original (com stats adicionados) salvo em: '{output_dir}'")

except Exception as e:
    print(f"Erro fatal durante a extração: {e}")