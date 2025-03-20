.PHONY: all extract transform publish

#include .env

all: extract transform check

extract:
	dpm install
	Rscript scripts/extract.R
	dpm concat --package datapackages/siafi_2021/datapackage.json \
			   --package datapackages/siafi_2022/datapackage.json \
	           --package datapackages/siafi_2023/datapackage.json \
	           --package datapackages/siafi_2024/datapackage.json \
						 --package datapackages/siafi_2025/datapackage.json \
			   --output-dir datapackages/siafi/data
	cd datapackages/siafi && frictionless describe --stats data/*.csv --type package --json > datapackage.json
	jq '. + {"name": "siafi"}' datapackages/siafi/datapackage.json > datapackage.json.tmp && mv datapackage.json.tmp datapackages/siafi/datapackage.json
	jq '.resources |= map(. + {"profile": "tabular-data-resource"})' datapackages/siafi/datapackage.json > datapackage.json.tmp && mv datapackage.json.tmp datapackages/siafi/datapackage.json

transform:
	Rscript scripts/transform.R

check:
	frictionless validate datapackage.yaml
	Rscript checks/rstats/testthat.R

publish:
	git add -Af datapackage.json datapackages/* data/* 
	git commit --author="Automated <actions@users.noreply.github.com>" -m "Update data package at: $$(date +%Y-%m-%dT%H:%M:%SZ)" || exit 0
	git push
