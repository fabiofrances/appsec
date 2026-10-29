# Hands-on de Containerização

Material prático da palestra de containerização. O roteiro do palestrante está em [`../roteiro-containerizacao.md`](../roteiro-containerizacao.md).

O app-alvo é a **Calculadora de IMC** deste repositório. Usamos a mesma API em duas versões:

| App | Pasta | Por que usar nos labs |
|---|---|---|
| Backend NestJS (Node 22) | [`../backend`](../backend) | runtime interpretado: imagem base, `node_modules`, musl x glibc |
| API em Go (stdlib) | [`api-go/`](api-go) | binário estático: `distroless/static` e `scratch` |
| Frontend Vue + nginx | [`../frontend`](../frontend) | hardening: nginx sem root, rootfs read-only |

Os arquivos da palestra AppSec (`backend/`, `frontend/`, `docker-compose.yml`, `infra/`) **não são alterados** pelos labs.

## Pré-requisitos

**Opção A — sua máquina**
- Docker Engine 24+ ou Docker Desktop (BuildKit e `docker compose` v2)
- `make` e `bash` (Linux/macOS nativos; no Windows use WSL2)
- ~6 GB livres em disco
- Opcional: Go 1.24+ (para `make lab-go-test`) e Trivy (sem ele o script usa a imagem `aquasec/trivy`)

**Opção B — [Play with Docker](https://labs.play-with-docker.com)** (login Docker Hub, sessão de 4 h)
```bash
apk add --no-cache make bash git          # as instâncias são Alpine
git clone <url-deste-repo> appsec && cd appsec
```
Para o lab de Swarm, crie 3 instâncias (ou use o template "3 Managers and 2 Workers").

## Antes da aula

```bash
make lab-prepull      # imagens base (~3 GB) + banco do Trivy — faça isso numa rede boa
export TRIVY_SKIP_DB_UPDATE=true   # durante a aula: Trivy não baixa o banco de novo

# sem internet na aula? leve o banco num arquivo:
make lab-trivy-db-save   # na véspera → reports/trivy-db.tgz (~130 MB)
make lab-trivy-db-load   # na máquina do participante
```

## Labs

| # | Lab | Comandos | Tópico |
|---|---|---|---|
| 01 | [Single-stage](lab01-single-stage/Dockerfile) | `make lab-single` | antipadrões |
| 02 | [Multi-stage](lab02-multi-stage/Dockerfile) | `make lab-multi` | stages, `--target`, HEALTHCHECK |
| 03 | [Imagens base](lab03-base-images/) | `make lab-bases lab-compare` | full x slim x alpine x distroless x chainguard |
| 03 | [Duelo](scripts/duel.sh) | `make lab-duel` | Alpine x Distroless x Chainguard: superfície, libc, CVEs, startup |
| 03b | [API em Go](api-go/) | `make lab-go-test lab-go lab-compare` | binário estático, scratch |
| 04 | [Hardening](lab04-hardening/) | `make lab-hardening` / `make lab-hardening-down` | não-root, read-only, cap_drop, limites |
| 05 | [BuildKit](lab05-buildkit/) | `make lab-cache` | cache mount, secret mount, ordem de camadas |
| 06 | [Supply chain](lab06-supply-chain/README.md) | `make lab-lint lab-scan lab-sbom` | hadolint, Trivy, SBOM, digest, cosign |
| 07 | [Swarm](lab07-swarm/stack.yml) | `make swarm-init swarm-deploy swarm-scale swarm-update swarm-rollback swarm-down` | services, stack, rolling update, secrets |

Comandos do dia a dia: [`CHEATSHEET.md`](CHEATSHEET.md).

### Testar a API de qualquer imagem

```bash
docker run -d --rm --name api -p 3000:3000 -e OTEL_SDK_DISABLED=true handson/backend:alpine
curl -s -X POST localhost:3000/bmi/calculate -H 'Content-Type: application/json' -d '{"weight":70,"height":1.75}'
docker stop api
```

### Swarm com vários nós (Play with Docker)

```bash
# nó 1 (manager)
make swarm-init ADVERTISE_ADDR=$(hostname -i)
# copie o "docker swarm join --token ..." exibido e rode nos nós 2 e 3

# nó 1: build + registry local, para os outros nós conseguirem baixar as imagens
make lab-multi lab-bases lab-hardening-build lab-go
make swarm-registry
make swarm-deploy REGISTRY=127.0.0.1:5000/
make swarm-update REGISTRY=127.0.0.1:5000/   # troca NestJS → Go em rolling update
```

Com um único nó, `REGISTRY` fica vazio e o stack usa as imagens locais.

## Limpeza

```bash
make lab-hardening-down swarm-down
docker swarm leave --force
docker image rm $(docker images 'handson/*' -q)
docker builder prune -f
```
