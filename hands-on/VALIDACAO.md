# Validação do Hands-on — instruções para o agente executor

> **Para quem é:** um agente (ou pessoa) rodando num notebook **com Docker e make**.
> O material foi escrito numa máquina sem Docker nem Node: nada aqui foi buildado ainda.
> O que já foi verificado: API em Go (`go vet` + `go test`: 4 testes ok; binário estático linux/amd64 com 6,8 MB),
> `bash -n` nos scripts, parse dos YAMLs, deck gerado e validado (24 slides).

## Objetivo

1. Executar todos os labs e corrigir o que falhar, **sem alterar os arquivos existentes** de `backend/`, `frontend/`, `docker-compose.yml` e `infra/` (pertencem à palestra AppSec; o único arquivo novo em `infra/` é `scripts/generate_pptx_containers.py`).
2. Medir os números reais e substituir os valores `≈` em `roteiro-containerizacao.md` e no deck.
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
- [ ] Copiar a tabela para o **Bloco 2** de `roteiro-containerizacao.md`, substituindo os `≈`, e atualizar o placar do **Bloco 9**
- [ ] Atualizar os mesmos números no dict `MEASURED` de `infra/scripts/generate_pptx_containers.py`

### 3b. Duelo Alpine x Distroless (abre a palestra)
- [ ] `make lab-bases` e depois `make lab-duel`: a tabela sai com as 3 colunas (alpine, distroless, chainguard)
- [ ] Conferir: distroless/chainguard com shell `não`, pacotes `não`, `docker exec sh` `falha`; alpine com BusyBox `sim`, libc `musl`
- [ ] "Tempo até /health" preenchido (não `timeout`) nas 3 imagens
- [ ] Copiar a tabela para o Bloco 2 de `roteiro-containerizacao.md` (seção "O duelo") e para o dict `DUEL` do gerador do PPT

### 4. BuildKit
- [ ] `make lab-cache`: o 2º build do lab05 é visivelmente mais rápido que o 2º do lab02. Anotar os tempos no Bloco 4
- [ ] Ordem de camadas: adicionar um comentário em `backend/src/main.ts`, rebuildar `lab05-buildkit/Dockerfile` (npm ci `CACHED`) e `Dockerfile.bad-order` (npm ci roda). Depois: `git checkout backend/src/main.ts`

### 5. Scan e supply chain
- [ ] `make lab-lint`: hadolint aponta mais problemas no lab01 que no lab02
- [ ] `make lab-scan`: gera `reports/trivy-single.html`; `trivy config` lista misconfigs; o secret scan roda
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
