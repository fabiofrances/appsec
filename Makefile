.PHONY: up down build trivy dep-check zap scan-all setup-dojo

## Stack
up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build --no-cache backend frontend

## AppSec scans
trivy:
	bash infra/scripts/trivy.sh

dep-check:
	bash infra/scripts/dependency-check.sh

zap:
	bash infra/scripts/zap.sh

## Run all scans
scan-all: trivy dep-check zap

## Run all scans and import to DefectDojo
#   export DOJO_TOKEN=<token> DOJO_PRODUCT_ID=<id> before running
scan-all-dojo:
	bash infra/scripts/trivy.sh --import-dojo
	bash infra/scripts/dependency-check.sh --import-dojo
	bash infra/scripts/zap.sh --import-dojo

## Configure DefectDojo (get token + product id)
setup-dojo:
	bash infra/defectdojo/setup.sh
