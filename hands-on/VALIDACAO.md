# Validação do Hands-on — instruções para o agente executor

> **Para quem é:** um agente (ou pessoa) rodando numa máquina **com Docker e make**. Use antes de cada
> apresentação para remedir os números (CVEs mudam toda semana).

## Última validação — 29/10/2026 (WSL2 Ubuntu 24.04, Docker 29.9.2, Trivy 0.58.1)

Todos os labs passaram (itens 0 a 7; o 8 multi-nó e o 9 regressão AppSec não foram executados). O que a validação corrigiu:

| Problema encontrado | Correção |
|---|---|
| `go 1.24` no `go.mod` faz o Go baixar a toolchain inexistente `go1.24` | `go 1.24.0` |
| Go 1.24.13 (fora de suporte): 23 CVEs HIGH na stdlib, **até no scratch** | Dockerfiles e prepull com Go 1.27 → 0 CVEs |
| `compare.sh`/`duel.sh` morriam em silêncio com imagem de 0 CVEs (`grep` + `pipefail`) | `grep -c` com fallback `true` |
| `duel.sh` não via o shell do Chainguard (`/usr` unificado) | detecta `usr/bin/...` |
| Chainguard `:latest` gratuita **tem** BusyBox/`sh` (o material dizia "sem shell") | roteiro, PPT e Dockerfile corrigidos |
| `make` usava `dash` (sem `time`) | `SHELL := /bin/bash` |
| Cache mount não mudou o tempo com rede rápida (~40 s nos dois) | `lab-cache` virou a demo de ordem das camadas: **8 s × 45 s** |
| `HEALTHCHECK` em forma shell disparava `DL3025` no hadolint | forma JSON (`wget --spider`) |
| `swarm-init`: `inactive` casava com `grep -q active` | `grep -qx` |
| `swarm-init` no WSL: duas interfaces, Docker não escolhe o IP | `ADVERTISE_ADDR` detectado pela rota padrão |
| Secret do Swarm ilegível para o usuário `node` (dono root, `0400`) | `uid: "1000"` no `stack.yml` |
| 502 no lab04 enquanto o backend sobe | `depends_on: condition: service_healthy` |
| Docker 29 rejeita `--name t` (1 caractere) | `--name apitest` |
| Secret scan **não** detecta o `DD_SECRET_KEY` genérico | vira ponto de discussão no roteiro |

Pendências conhecidas: os relatórios do Trivy em container saem com dono root (`sudo chown -R $USER reports/`); o banco do Trivy é baixado a cada sessão (melhoria planejada junto da palestra AppSec).

## Objetivo

1. Executar todos os labs e corrigir o que falhar, **sem alterar os arquivos existentes** de `backend/`, `frontend/`, `docker-compose.yml` e `infra/` (pertencem à palestra AppSec; o único arquivo novo em `infra/` é `scripts/generate_pptx_containers.py`).
2. Medir os números e atualizar as tabelas em `roteiro-containerizacao.md` (Blocos 2 e 9) e os dicts `MEASURED`/`DUEL` do gerador do PPT.
3. Regenerar o PPT: `python infra/scripts/generate_pptx_containers.py` (requer `pip install python-pptx`).
4. Responder em pt-BR com o relatório do que passou, do que foi corrigido e da tabela final.

## Preparar o WSL (Windows)

```powershell
wsl --install -d Ubuntu-24.04          # PowerShell como admin; reiniciar se pedir
```
Dentro do Ubuntu (Docker Engine nativo; não depende do Docker Desktop):
```bash
sudo apt-get update && sudo apt-get install -y make git curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER && newgrp docker
# opcional: Go para make lab-go-test
sudo snap install go --classic || sudo apt-get install -y golang-go
git clone <repo> ~/appsec && cd ~/appsec     # clone dentro do Linux (~), não em /mnt/c: build bem mais rápido
```
> Se o `systemd` não estiver ativo (`docker` não sobe), adicione `[boot]
systemd=true` em `/etc/wsl.conf` e rode `wsl --shutdown` no Windows.

## Pré-requisitos

```bash
docker version && docker buildx version && docker compose version && make --version
git status   # árvore limpa; trabalhe numa branch: git checkout -b handson-validacao
```

## Checklist de execução

Rode na raiz do repositório e marque cada item.

### 0. Preparação
- [ ] `make lab-prepull`: todas as imagens baixam. Se alguma tag não existir mais (ex.: `aquasec/trivy:0.58.1`, `golang:1.24`), atualize para a versão estável atual **em todos os lugares** (`grep -rn "<tag>" hands-on Makefile`)

### 1. Builds
- [ ] `make lab-single lab-multi lab-bases`
- [ ] `make lab-go-test lab-go`
- [ ] `make lab-hardening-build`
- [ ] `docker build -f hands-on/lab05-buildkit/Dockerfile.bad-order -t handson/backend:bad-order backend`

### 2. Cada imagem responde à API
```bash
for img in handson/backend:{single,multi,full,slim,alpine,distroless,chainguard} handson/api-go:{single,alpine,distroless,scratch}; do
  docker run -d --rm --name apitest -p 3000:3000 -e OTEL_SDK_DISABLED=true $img >/dev/null
  sleep 6
  printf '%-32s ' "$img"
  curl -s -X POST localhost:3000/bmi/calculate -H 'Content-Type: application/json' -d '{"weight":70,"height":1.75}'
  echo; docker stop apitest >/dev/null
done
```
- [ ] todas retornam `{"bmi":22.86,"classification":"Peso normal",...}`
- [ ] `handson/backend:multi` e `handson/api-go:*` ficam `healthy` (`docker inspect -f '{{.State.Health.Status}}'`) após ~30 s
- [ ] **Pontos de risco conhecidos:**
  - distroless/chainguard: `CMD ["dist/main.js"]` depende do ENTRYPOINT ser o `node`. Se falhar, use `ENTRYPOINT ["/nodejs/bin/node"]` (distroless) ou `["/usr/bin/node"]` (chainguard)
  - `OTEL_SDK_DISABLED=true`: confirmar que o NodeSDK respeita a variável (sem erro de export nos logs). Se não respeitar, troque por `OTEL_EXPORTER_OTLP_ENDPOINT` apontando para um host inexistente e documente no roteiro
  - o builder Debian do lab03 (full/slim/distroless/chainguard) gera `node_modules` glibc. Se houver módulo nativo, confirmar que carrega

### 3. Comparativo
- [ ] `make lab-compare` gera a tabela Markdown e salva os JSONs em `reports/compare/`
- [ ] Copiar a tabela para o **Bloco 2** de `roteiro-containerizacao.md`, com os números novos, e atualizar o placar do **Bloco 9**
- [ ] Atualizar os mesmos números no dict `MEASURED` de `infra/scripts/generate_pptx_containers.py`

### 3b. Duelo Alpine x Distroless (abre a palestra)
- [ ] `make lab-bases` e depois `make lab-duel`: a tabela sai com as 3 colunas (alpine, distroless, chainguard)
- [ ] Conferir: distroless/chainguard com shell `não`, pacotes `não`, `docker exec sh` `falha`; alpine com BusyBox `sim`, libc `musl`
- [ ] "Tempo até /health" preenchido (não `timeout`) nas 3 imagens
- [ ] Copiar a tabela para o Bloco 2 de `roteiro-containerizacao.md` (seção "O duelo") e para o dict `DUEL` do gerador do PPT

### 4. BuildKit
- [ ] `make lab-cache`: tabela com o rebuild após mudar 1 linha; o `Dockerfile` (deps antes do código) bem mais rápido que o `bad-order` (última medição: 8 s × 45 s). Anotar no Bloco 4
- [ ] `git status backend/` limpo depois da demo (o script restaura o `main.ts`)

### 5. Scan e supply chain
- [ ] `make lab-lint`: roda nos dois Dockerfiles (o hadolint quase não reclama do lab01: só `DL3059`; quem pega root/HEALTHCHECK é o `trivy config`)
- [ ] `make lab-scan`: gera `reports/trivy-single.html`; `trivy config` lista misconfigs (`DS-0002`, `DS-0026`); o secret scan roda (e não acha o `DD_SECRET_KEY`)
- [ ] `make lab-sbom`: gera `reports/sbom-*.cdx.json`
- [ ] Testar o wrapper **sem** o trivy nativo (`PATH` sem trivy): precisa cair no `docker run aquasec/trivy`

### 6. Hardening
- [ ] `make lab-hardening` sobe os 2 serviços e mostra `user=... readonly=true capdrop=[ALL]`
- [ ] `docker exec handson-hardening-frontend-1 id` mostra um uid diferente de 0
- [ ] `docker exec handson-hardening-frontend-1 touch /etc/x` falha com read-only
- [ ] `curl -s localhost:8080` devolve o HTML; `curl -s -X POST localhost:8080/api/bmi/calculate ...` funciona
- [ ] frontend e backend ficam `healthy`
- [ ] `make lab-hardening-down`

### 7. Swarm (nó único)
- [ ] `make swarm-init swarm-deploy`: `docker stack services bmi` com `2/2` em ambos
- [ ] `curl -s -X POST localhost:8080/api/bmi/calculate ...` funciona
- [ ] `make swarm-scale` → `4/4`
- [ ] `make swarm-update` → backend vira `handson/api-go:scratch` sem erro; a API continua respondendo durante o update
- [ ] `make swarm-rollback` → volta para `handson/backend:multi`
- [ ] `docker exec $(docker ps -q -f name=bmi_backend | head -1) cat /run/secrets/bmi_api_key`
- [ ] `make swarm-down` remove stack e secret; `docker swarm leave --force`

### 8. Swarm multi-nó (Play with Docker, se possível)
- [ ] Seguir a seção "Swarm com vários nós" de `hands-on/README.md` com 3 instâncias
- [ ] `make swarm-registry` + `make swarm-deploy REGISTRY=127.0.0.1:5000/`: tasks distribuídas entre os nós
- [ ] `docker node update --availability drain <nó>`: as tasks migram

### 9. Regressão da palestra AppSec
- [ ] `make up` sobe o stack original; `make trivy` gera os relatórios; `make down`

## Entrega

- Commit(s) na branch `handson-validacao` com as correções e os números reais
- Relatório: tabela final do `lab-compare`, tempos do `lab-cache` e lista do que foi alterado e por quê
- Não fazer push nem abrir PR sem autorização do usuário
