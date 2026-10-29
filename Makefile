.PHONY: up down build trivy trivy-dojo dep-check dep-check-dojo zap zap-dojo scan-all scan-all-dojo setup-dojo

# bash: as receitas dos labs usam "time" e loops
SHELL := /bin/bash

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

# ═══════════════════════════════════════════════════════════════════════════
## Hands-on de containerização (ver hands-on/README.md e roteiro-containerizacao.md)
# ═══════════════════════════════════════════════════════════════════════════
.PHONY: lab-trivy-db lab-trivy-db-save lab-trivy-db-load lab-duel lab-prepull lab-single lab-multi lab-bases lab-go-test lab-go lab-compare lab-hardening-build lab-hardening lab-hardening-down lab-cache lab-lint lab-scan lab-sbom swarm-init swarm-registry swarm-deploy swarm-scale swarm-update swarm-rollback swarm-down
HO            := hands-on
TRIVY         := bash $(HO)/scripts/trivy.sh
STACK         ?= bmi
REGISTRY      ?=
# IP da rota padrão (WSL e PWD têm mais de uma interface); sobrescreva com ADVERTISE_ADDR=<ip>
ADVERTISE_ADDR ?= $(shell ip route get 1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($$i == "src") print $$(i + 1)}')
DUEL          ?= handson/backend:alpine handson/backend:distroless handson/backend:chainguard
BASE_IMAGES   := node:22 node:22-slim node:22-alpine \
	             gcr.io/distroless/nodejs22-debian12:nonroot cgr.dev/chainguard/node:latest \
	             golang:1.27 golang:1.27-alpine alpine:3.21 gcr.io/distroless/static-debian12:nonroot \
	             nginx:1.27-alpine nginxinc/nginx-unprivileged:1.27-alpine \
	             registry:2 aquasec/trivy:0.58.1 hadolint/hadolint:latest

## Preparação
lab-prepull: lab-trivy-db
	@for img in $(BASE_IMAGES); do docker pull -q $$img; done

## Banco do Trivy: baixa uma vez (volume trivy-cache) e reaproveita nos labs e no make trivy
lab-trivy-db:
	$(TRIVY) image --download-db-only
	@echo "Durante a aula, para não baixar de novo: export TRIVY_SKIP_DB_UPDATE=true"

# Plano B offline: leve o banco num arquivo (pendrive, rede ruim)
lab-trivy-db-save:
	mkdir -p reports
	docker run --rm -v trivy-cache:/cache -v "$(CURDIR)/reports:/out" alpine:3.21 		tar czf /out/trivy-db.tgz -C /cache .
	@ls -lh reports/trivy-db.tgz

lab-trivy-db-load:
	docker run --rm -v trivy-cache:/cache -v "$(CURDIR)/reports:/out" alpine:3.21 		tar xzf /out/trivy-db.tgz -C /cache
	@echo "Banco carregado. Use: export TRIVY_SKIP_DB_UPDATE=true"

## Labs 01-03 — single x multi-stage e imagens base (backend NestJS)
lab-single:
	docker build -f $(HO)/lab01-single-stage/Dockerfile -t handson/backend:single backend

lab-multi:
	docker build -f $(HO)/lab02-multi-stage/Dockerfile -t handson/backend:multi backend

lab-bases:
	@for v in full slim alpine distroless chainguard; do \
	    docker build -f $(HO)/lab03-base-images/Dockerfile.$$v -t handson/backend:$$v backend || exit 1; \
	done

## Lab 03b — mesma API em Go: single x alpine x distroless x scratch
lab-go-test:
	cd $(HO)/api-go && go test ./...

lab-go:
	@for v in single alpine distroless scratch; do \
	    docker build -f $(HO)/api-go/Dockerfile.$$v -t handson/api-go:$$v $(HO)/api-go || exit 1; \
	done

lab-compare:
	bash $(HO)/scripts/compare.sh

## Duelo Alpine x Distroless (abertura e Bloco 2)
lab-duel:
	bash $(HO)/scripts/duel.sh $(DUEL)

## Lab 04 — hardening do runtime
lab-hardening-build:
	docker build -f $(HO)/lab04-hardening/Dockerfile --build-context lab=$(HO)/lab04-hardening \
	    -t handson/frontend:hardened frontend

lab-hardening: lab-multi lab-hardening-build
	docker compose -f $(HO)/lab04-hardening/compose.hardening.yml up -d
	@docker inspect -f '{{.Name}} user={{.Config.User}} readonly={{.HostConfig.ReadonlyRootfs}} capdrop={{.HostConfig.CapDrop}} mem={{.HostConfig.Memory}}' \
	    $$(docker compose -f $(HO)/lab04-hardening/compose.hardening.yml ps -q)

lab-hardening-down:
	docker compose -f $(HO)/lab04-hardening/compose.hardening.yml down

## Lab 05 — BuildKit e cache
lab-cache:
	bash $(HO)/scripts/cache-demo.sh

## Lab 06 — scan e supply chain
lab-lint:
	@for f in $(HO)/lab01-single-stage/Dockerfile $(HO)/lab02-multi-stage/Dockerfile; do \
	    echo "── $$f"; \
	    docker run --rm -i -v "$(CURDIR)/$(HO)/lab06-supply-chain/.hadolint.yaml:/.config/hadolint.yaml" \
	        hadolint/hadolint:latest < $$f || true; \
	done

lab-scan:
	mkdir -p reports
	$(TRIVY) image --severity CRITICAL,HIGH handson/backend:single
	$(TRIVY) image --format template --template @infra/trivy/html.tpl -o reports/trivy-single.html handson/backend:single
	$(TRIVY) config $(HO)
	$(TRIVY) fs --scanners secret .

lab-sbom:
	mkdir -p reports
	$(TRIVY) image --format cyclonedx -o reports/sbom-multi.cdx.json handson/backend:multi
	$(TRIVY) image --format cyclonedx -o reports/sbom-go-scratch.cdx.json handson/api-go:scratch
	$(TRIVY) sbom reports/sbom-multi.cdx.json

## Lab 07 — Docker Swarm
swarm-init:
	@docker info --format '{{.Swarm.LocalNodeState}}' | grep -qx active || \
	    docker swarm init $(if $(ADVERTISE_ADDR),--advertise-addr $(ADVERTISE_ADDR),)
	docker node ls

swarm-registry:
	@docker service inspect registry >/dev/null 2>&1 || \
	    docker service create --name registry --publish 5000:5000 registry:2
	@for img in handson/backend:multi handson/backend:alpine handson/frontend:hardened handson/api-go:scratch; do \
	    docker tag $$img 127.0.0.1:5000/$$img && docker push 127.0.0.1:5000/$$img; \
	done

swarm-deploy:
	@docker secret inspect bmi_api_key >/dev/null 2>&1 || \
	    printf 'demo-%s' "$$(date +%s)" | docker secret create bmi_api_key -
	REGISTRY=$(REGISTRY) docker stack deploy --resolve-image never -c $(HO)/lab07-swarm/stack.yml $(STACK)
	docker stack services $(STACK)

swarm-scale:
	docker service scale $(STACK)_backend=4
	docker service ps $(STACK)_backend

swarm-update:
	docker service update --image $(REGISTRY)handson/api-go:scratch $(STACK)_backend
	docker service ps $(STACK)_backend

swarm-rollback:
	docker service rollback $(STACK)_backend
	docker service ps $(STACK)_backend

swarm-down:
	-docker stack rm $(STACK)
	@for i in 1 2 3 4 5 6 7 8 9 10; do docker secret rm bmi_api_key >/dev/null 2>&1 && break; sleep 2; done
	-docker service rm registry
