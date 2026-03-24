"""
Concatena recursos dos pacotes SIAFI em streaming e gera o datapackage.json.
Substitui `dpm concat` + `frictionless describe` + jq do Makefile.
"""
import csv
import gzip
import json
import sys
from pathlib import Path

from frictionless import describe

SIAFI_YEARS = ("2021", "2022", "2023", "2024", "2025", "2026")
ENCODING = "utf-8"


def _open_table(path: Path):
    """Abre CSV ou CSV.gz para leitura em texto."""
    if path.suffix == ".gz" or path.name.endswith(".csv.gz"):
        return gzip.open(path, "rt", encoding=ENCODING)
    return open(path, "r", encoding=ENCODING)


def _infer_delimiter(path: Path) -> str:
    """Infere delimitador pela primeira linha."""
    with _open_table(path) as f:
        first = f.readline()
    return ";" if first.count(";") > first.count(",") else ","


def _get_resource(pkg: dict, name: str) -> dict | None:
    """Retorna o recurso de nome `name` no pacote, ou None."""
    for r in pkg.get("resources", []):
        if r.get("name") == name:
            return r
    return None


def _stream_concat_one(
    packages: list[dict],
    pkg_dirs: list[Path],
    resource_name: str,
    out_path: Path,
) -> None:
    """
    Concatena um recurso de vários pacotes em um CSV, em streaming.
    Cabeçalho do primeiro arquivo; colunas diferentes são alinhadas por nome.
    """
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_columns = None
    delimiter = ","

    with open(out_path, "w", encoding=ENCODING, newline="") as out:
        writer = None
        for pkg, pkg_dir in zip(packages, pkg_dirs):
            res = _get_resource(pkg, resource_name)
            if not res:
                print(f"  [{resource_name}] Pulando {pkg_dir.name}: recurso não encontrado.", file=sys.stderr)
                continue
            data_path = pkg_dir / res["path"]
            if not data_path.exists():
                print(f"  Aviso: {data_path} não encontrado.", file=sys.stderr)
                continue
            print(f"  [{resource_name}] Concatena: {data_path}", file=sys.stderr)
            if out_columns is None:
                delimiter = _infer_delimiter(data_path)
            with _open_table(data_path) as f:
                reader = csv.reader(f, delimiter=delimiter)
                header = next(reader, None)
                if not header:
                    continue
                if out_columns is None:
                    out_columns = header
                    writer = csv.writer(out, delimiter=delimiter)
                    writer.writerow(out_columns)
                for row in reader:
                    if len(row) != len(header):
                        continue
                    row_by_name = dict(zip(header, row))
                    writer.writerow([row_by_name.get(c, "") for c in out_columns])
    print(out_path)


def _load_packages(repo: Path) -> tuple[list[dict], list[Path]]:
    """Carrega descriptors e diretórios dos pacotes SIAFI existentes."""
    descriptors = []
    dirs = []
    for year in SIAFI_YEARS:
        p = repo / "datapackages" / f"siafi_{year}" / "datapackage.json"
        if p.exists():
            with open(p, encoding=ENCODING) as f:
                descriptors.append(json.load(f))
            dirs.append(p.parent)
    return descriptors, dirs


def _common_resource_names(packages: list[dict]) -> set[str]:
    """Nomes de recursos presentes em todos os pacotes."""
    if not packages:
        return set()
    names = {r["name"] for r in packages[0].get("resources", [])}
    for pkg in packages[1:]:
        names &= {r["name"] for r in pkg.get("resources", [])}
    return names


def _write_siafi_datapackage(repo: Path, data_dir: Path) -> None:
    """
    Gera datapackage.json a partir dos CSVs em data_dir (análogo ao extract.py).
    Descreve cada CSV como resource e monta o pacote com paths relativos (evita
    erro "path is not safe" do Frictionless em caminhos absolutos no Windows).
    """
    resources = []
    for csv_path in sorted(data_dir.glob("*.csv")):
        resource = describe(str(csv_path), type="resource", stats=True)
        res_dict = resource.to_dict() if hasattr(resource, "to_dict") else dict(resource)
        res_dict["name"] = csv_path.stem
        res_dict["path"] = f"data/{csv_path.name}"
        res_dict["profile"] = "tabular-data-resource"
        resources.append(res_dict)
    descriptor = {"name": "siafi", "resources": resources}
    out_path = repo / "datapackages" / "siafi" / "datapackage.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding=ENCODING) as f:
        json.dump(descriptor, f, indent=2, ensure_ascii=False)
    print(out_path)


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    packages, pkg_dirs = _load_packages(repo)
    if not packages:
        print("Nenhum datapackage.json SIAFI encontrado.", file=sys.stderr)
        sys.exit(1)

    print("Pastas lidas (datapackages):", file=sys.stderr)
    for d in pkg_dirs:
        print(f"  - {d}", file=sys.stderr)

    resource_names = _common_resource_names(packages)
    if not resource_names:
        print("Nenhum recurso comum entre os pacotes.", file=sys.stderr)
        sys.exit(1)

    data_dir = repo / "datapackages" / "siafi" / "data"
    print(f"Concatenando (streaming): {', '.join(sorted(resource_names))}")
    for name in sorted(resource_names):
        _stream_concat_one(packages, pkg_dirs, name, data_dir / f"{name}.csv")

    print("Gerando datapackage.json (describe + schema)...")
    _write_siafi_datapackage(repo, data_dir)


if __name__ == "__main__":
    main()
