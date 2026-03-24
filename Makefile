.PHONY: all extract transform publish

#include .env

# Make uses a minimal shell (no .bashrc); Git Bash may then resolve a different
# Rscript than an interactive login shell. bash -lc + cd fixes PATH and cwd.
# Override, e.g.: make transform RSCRIPT="/c/Program\ Files/R/R-4.4.3/bin/Rscript"
RSCRIPT ?= Rscript

all: extract transform check

extract:
	dpm install
#	Rscript scripts/extract.R
	python scripts/concat_siafi.py

transform:
	bash -lc 'cd "$(CURDIR)" && $(RSCRIPT) scripts/transform.R'

check:
	frictionless validate datapackage.yaml
	bash -lc 'cd "$(CURDIR)" && $(RSCRIPT) checks/rstats/testthat.R'
