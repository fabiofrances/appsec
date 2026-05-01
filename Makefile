.PHONY: up down build trivy trivy-dojo dep-check dep-check-dojo zap zap-dojo scan-all scan-all-dojo setup-dojo

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

trivy-dojo:
	bash infra/scripts/trivy.sh --import-dojo

dep-check:
	bash infra/scripts/dependency-check.sh

dep-check-dojo:
	bash infra/scripts/dependency-check.sh --import-dojo

zap:
	bash infra/scripts/zap.sh

zap-dojo:
	bash infra/scripts/zap.sh --import-dojo

## Run all scans
scan-all: trivy dep-check zap

## Run all scans e importa no DefectDojo
scan-all-dojo: trivy-dojo dep-check-dojo zap-dojo

## Configure DefectDojo (get token + product id)
setup-dojo:
	bash infra/defectdojo/setup.sh
