# Acordo Judicial

A identificação dos contratos é feita com base em todos os `num_contrato_saida` que tiveram empenho nos `num_contrato_entrada` dos projetos da vale.

Crie e ative o ambiente virtual python

```bash
python -m venv venv
source venv/scripts/activate
```

Instale as dependencias do python:

```bash
python -m pip install -r requirements.txt
```

Instale as dependências do R

```R
Rscript -e 'renv::install()'
```


Atualize manualmente o conjunto [armazem-siad-dados](https://github.com/splor-mg/armazem-siad-dados).

Atualize as hashs dos commits dos arquivos em `data.toml`

Execute o comando `make all`
