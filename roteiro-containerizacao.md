# Roteiro de Palestra — Containerização na Prática (Hands-on)

> **Público:** devs e ops de nível intermediário (já usam Docker, querem fazer melhor)
> **Duração total:** ~120 minutos (com intervalo de 5 min)
> **Formato:** expositivo curto + hands-on guiado (cada bloco termina com um lab)
> **Ambiente:** máquina do participante (Docker + make) **ou** Play with Docker
> **Material:** [`hands-on/`](hands-on/README.md) · [`hands-on/CHEATSHEET.md`](hands-on/CHEATSHEET.md) · `reports/containerizacao-palestra.pptx`

> 📏 **Números medidos em 29/10/2026** (WSL2 Ubuntu 24.04, Docker 29.9, Trivy 0.58.1). CVEs mudam toda semana: rode `make lab-compare` e `make lab-duel` na véspera e atualize (ver [`hands-on/VALIDACAO.md`](hands-on/VALIDACAO.md)).

---

## Estrutura da Aula

| # | Bloco | Tempo | Lab |
|---|---|---|---|
| 0 | Abertura: **votação "Alpine ou distroless?"** e checagem do ambiente | 8 min | `make lab-prepull` |
| 1 | Fundamentos e **onde encontrar imagens** | 7 min | `docker history`, digest |
| 2 | **Tipos de imagem base** + **duelo Alpine x Distroless** | 15 min | lab03 + `make lab-duel` + lab03b (Go) |
| 3 | **Single-stage x multi-stage** | 15 min | lab01 + lab02 |
| 4 | **Construindo seu Dockerfile**: boas práticas + BuildKit | 15 min | lab05 |
| — | Intervalo | 5 min | — |
| 5 | **Scan de vulnerabilidades** e supply chain | 15 min | lab06 |
| 6 | **Hardening do runtime** | 10 min | lab04 |
| 7 | **Comandos de rotina Docker** | 10 min | cheat sheet |
| 8 | **Docker Swarm** | 15 min | lab07 |
| 9 | Encerramento e Q&A | 5 min | — |

**Fio condutor:** a mesma Calculadora de IMC do repositório AppSec. Começamos com o pior Dockerfile possível e, a cada bloco, a imagem fica menor, mais rápida de construir e mais segura. A tabela do `make lab-compare` é o placar da aula.

---

## Bloco 0 — Abertura (8 min)

### Fala sugerida
> "Todo mundo aqui já escreveu um Dockerfile que funciona. Hoje a pergunta é outra: ele é pequeno? É rápido de construir?
> Quantas vulnerabilidades você está mandando para produção junto com ele? Vamos medir isso ao vivo."

### A pergunta que abre a aula (3 min)
> "Antes de qualquer slide: vocês vão colocar uma API Node em produção amanhã.
> Qual imagem base? **Alpine** ou **distroless**? Levanta a mão quem vai de Alpine... e de distroless?"

- Anote o placar no quadro e peça **um argumento de cada lado** (sem responder ainda)
- Argumentos que costumam aparecer: "Alpine é menor", "Alpine tem shell para debug", "distroless é mais seguro", "distroless é impossível de debugar"
- Prometa: "No bloco 2 a gente mede tudo isso com a mesma app. No final, votamos de novo."

### Pontos a cobrir
- Objetivo: sair com um Dockerfile de referência e um checklist
- Mostrar a app: `docker compose up -d frontend backend` → http://localhost
- Garantir o ambiente: `docker version`, `docker buildx version`, `make --version`
- Quem estiver no Play with Docker: `apk add make bash git` e clonar o repo

### Hands-on
```bash
make lab-prepull        # ideal: pedido por e-mail antes da aula
```

**Transição:** "Antes de escrever Dockerfile, vamos entender do que uma imagem é feita e de onde ela vem."

---

## Bloco 1 — Fundamentos e onde encontrar imagens (7 min)

### 1.1 — Imagem x container x camada (3 min)

```
Imagem    = pilha de camadas read-only (tar) + config JSON (ENTRYPOINT, ENV, USER...)
Container = imagem + 1 camada gravável + namespaces/cgroups
Camada    = resultado de cada RUN / COPY / ADD
```

- Padrão **OCI**: a mesma imagem roda em Docker, containerd, Podman e Kubernetes
- Camadas são compartilhadas entre imagens com a mesma base (cache e disco)
- **Apagar um arquivo numa camada posterior não reduz a imagem**: ele continua na camada anterior

```bash
docker history node:22-alpine
docker image inspect node:22-alpine -f '{{json .RootFS.Layers}}'
```

### 1.2 — Onde encontrar imagens (4 min)

| Registry | O que tem | Atenção |
|---|---|---|
| **Docker Hub — Official Images** | `node`, `nginx`, `postgres`, `golang`... curadas pela Docker | rate limit para pulls anônimos |
| **Docker Hub — Verified Publisher / Sponsored OSS** | mantidas pelo fabricante (`grafana/`, `bitnami/`...) | conferir o selo |
| **Docker Hardened Images** (`dhi.io`) | variantes minimalistas e mantidas pela Docker | conferir licença/plano |
| **GHCR** (`ghcr.io`) | projetos do GitHub (ex.: cosign) | |
| **Quay.io** | ecossistema Red Hat (Keycloak, etc.) | |
| **Amazon ECR Public** (`public.ecr.aws`) | espelho das oficiais sem o rate limit do Hub | |
| **Distroless** (`gcr.io/distroless`) | Google: só runtime, sem shell | |
| **Chainguard** (`cgr.dev/chainguard`) | Wolfi, rebuild diário, 0 CVEs de SO | tier gratuito só com `:latest`, que hoje traz BusyBox/`sh` |
| **Registry interno** (Harbor, Nexus, ECR, ACR, GAR, OCIR) | espelho + scan + política | é onde produção deveria buscar |

**Como escolher uma imagem**
- Oficial ou do fabricante > imagem de usuário aleatório
- Data da última atualização e frequência de rebuild
- Dockerfile público e SBOM/assinatura disponíveis
- **Tag x digest:** `node:22-alpine` muda com o tempo; `node:22-alpine@sha256:...` é imutável
- Por que **não** `latest`: build não reprodutível e rollback impossível

```bash
docker buildx imagetools inspect node:22-alpine    # digest + plataformas
```

**Transição:** "Escolher o registry é a primeira decisão. A segunda é qual *variante* da imagem usar, e isso muda tudo."

---

## Bloco 2 — Tipos de imagem base (15 min)

### Fala sugerida
> "A mesma API, o mesmo código. A única diferença é a linha FROM. Vamos ver o que muda."

### Comparativo

| Variante | Base | libc | Shell / pkg manager | Uso típico |
|---|---|---|---|---|
| `node:22` (full) | Debian + buildpack-deps | glibc | bash, apt, gcc, git, python | **stage de build** |
| `node:22-slim` | Debian mínimo | glibc | bash, apt | runtime quando precisa de glibc/apt |
| `node:22-alpine` | Alpine | **musl** | **busybox** `sh`, `apk` | runtime pequeno com shell |
| `distroless/nodejs22` | Debian sem userland | glibc | **nenhum** | runtime de produção |
| `chainguard/node` | Wolfi | glibc | BusyBox `sh` na `:latest` gratuita | runtime com 0 CVEs de SO |
| `scratch` | vazio | — | nenhum | binário estático (Go, Rust) |

### Alpine: o que é diferente (ponto obrigatório)
- **BusyBox**: um único binário (~1 MB) que implementa `sh`, `ls`, `wget`, `ps`... via symlinks
  ```bash
  docker run --rm alpine ls -l /bin | head
  docker run --rm alpine readlink -f /bin/ls      # → /bin/busybox
  ```
- **musl em vez de glibc**:
  - binários e módulos nativos compilados para glibc não carregam (`Error relocating`, `not found`)
  - resolver DNS diferente (histórico com TCP/`search` em DNS grande, Kubernetes)
  - diferenças de performance em alocação de memória e locale
  ```bash
  docker run --rm node:22-alpine ldd /usr/local/bin/node      # musl
  docker run --rm node:22-slim   ldd /usr/local/bin/node      # glibc
  ```
- `apk add --no-cache` em vez de `apt-get`; versões de pacotes mudam rápido (pin é difícil)
- **Regra:** builder e runtime com a **mesma libc** (ver `hands-on/lab03-base-images/Dockerfile.alpine`)

### Distroless / scratch (e o Chainguard?)
- Sem shell = **sem `docker exec sh`**: debug com `docker debug`, imagem `:debug` ou container efêmero
- Sem `wget`/`curl` = sem HEALTHCHECK por shell → o healthcheck vai para o orquestrador ou para o próprio binário (ver `hands-on/api-go/main.go`, flag `-healthcheck`)
- Usuário `nonroot` (65532) já é o padrão
- **Chainguard:** a `:latest` gratuita testada (build de 28/10/2026) **tem** BusyBox e `sh`. Entre as opções para Node, só o distroless é de fato sem shell

### Hands-on
```bash
make lab-bases lab-go-test lab-go
make lab-compare
docker run --rm -it --entrypoint sh handson/backend:distroless    # falha: não existe shell
```

**Resultado medido (`make lab-compare`):**

| Imagem | Tamanho | Camadas | Usuário | CVEs C / H / M |
|---|---|---|---|---|
| `handson/backend:single` | 2.070 MB | 12 | root | 25 / 537 / 2009 |
| `handson/backend:full` | 1.715 MB | 12 | node | 23 / 493 / 1996 |
| `handson/backend:slim` | 477 MB | 9 | node | 2 / 91 / 125 |
| `handson/backend:alpine` | 394 MB | 8 | node | 1 / 35 / 38 |
| `handson/backend:distroless` | 361 MB | 23 | 65532 | 2 / 31 / 63 |
| `handson/backend:chainguard` | 410 MB | 15 | 65532 | 1 / 25 / 28 |
| `handson/api-go:single` | 1.375 MB | 10 | root | 3 / 146 / 818 |
| `handson/api-go:scratch` | **9 MB** | 1 | 65532 | **0 / 0 / 0** |

> O `node_modules` domina o tamanho nas imagens Node (~360–410 MB em todas as bases mínimas). A versão Go em scratch é ~40x menor.

**De onde vêm as CVEs das imagens Node** (o argumento que mais surpreende):

| Imagem | SO | `node_modules` |
|---|---|---|
| alpine | **0** | C1 / H35: 25 da app + ~10 do **npm que já vem na `node:22-alpine`** |
| distroless | C1 / H6 (Debian) | C1 / H25 (só a app; não traz npm) |
| chainguard | **0** | C1 / H25 (só a app) |
| slim | C1 / H56 | C1 / H35 |
| full | C22 / H458 | C1 / H35 |

> Nas bases mínimas, **a maior parte das CVEs é da sua app** (o CRITICAL é `proxy-addr`, dependência do Express), não da imagem base.

**História real da validação (Go):** com `golang:1.24` (1.24.13, fora de suporte), as 4 imagens Go, **inclusive a scratch**, tinham **23 HIGH**. Era a stdlib do Go embutida no binário. Com Go 1.27: zero. **`scratch` não zera CVE se a toolchain estiver velha.**

### O duelo: Alpine x Distroless (resposta à votação da abertura)
```bash
make lab-duel                    # alpine x distroless x chainguard, mesma app
```
O script ([`hands-on/scripts/duel.sh`](hands-on/scripts/duel.sh)) lista o filesystem com `docker export`, o que funciona até sem shell, e mede: tamanho, nº de arquivos e executáveis, shell, BusyBox, gerenciador de pacotes, libc, usuário, CVEs, tempo até o `/health` responder, memória e se `docker exec sh` funciona.

| | Alpine | Distroless |
|---|---|---|
| Tamanho (medido) | 394 MB | 361 MB (com Node, `node_modules` domina) |
| libc | **musl**: módulos nativos, DNS, alocador; Node em musl é tier *experimental* | **glibc**: o binário oficial do Node, máxima compatibilidade |
| Shell / pacotes | `sh` (BusyBox) + `apk`: ótimo para debug... **e para o atacante** | nenhum: RCE sem `sh`, `wget` ou `apk` para baixar o próximo estágio |
| Debug | `docker exec sh` | `docker debug`, tag `:debug`, container efêmero |
| Healthcheck | `wget` no HEALTHCHECK | probe no orquestrador ou o binário se testa |
| CVEs (medido, C/H/M/L) | 1 / 35 / 38 / 4, todas de npm (0 no SO) | 2 / 31 / 63 / 30, inclui Debian com *unfixed* |
| Versões | qualquer tag `node:X.Y-alpine` | só majors LTS (`nodejs22-debian12`) |
| Usuário | root por padrão (`USER node` manual) | tag `:nonroot` pronta |
| Superfície (medido) | 18.946 arquivos, 314 executáveis | 17.676 arquivos, **0** executáveis em `/bin` |
| Tempo até `/health` | ~1,4–2,0 s | ~1,2 s |
| Memória em uso | ~71 MiB | ~75 MiB |

**Ponto da discussão:** com Node, tamanho **não decide**. A decisão é **libc + superfície de ataque + capacidade de debug**. A "terceira via" é Chainguard/Wolfi: glibc, 0 CVEs de SO e sem npm, **mas a `:latest` gratuita traz BusyBox e `sh`** (medido: `docker exec sh` funciona). Para binário estático (Go), o duelo nem existe: `scratch`/`distroless/static`.

**Transição:** "Escolhemos a base. Mas vocês notaram que todos esses Dockerfiles têm dois FROM? Vamos ver por quê."

---

## Bloco 3 — Single-stage x multi-stage (15 min)

### Hands-on primeiro
```bash
make lab-single lab-multi
make lab-compare
docker history handson/backend:single | head -15
docker run --rm handson/backend:single ls node_modules/.bin | head    # tsc, jest, eslint... em produção
docker run --rm handson/backend:single whoami                          # root
```

### Ler juntos: [`hands-on/lab01-single-stage/Dockerfile`](hands-on/lab01-single-stage/Dockerfile)
Antipadrões: base full, `COPY . .` antes do install, `npm install`, devDependencies, root, CMD via npm (o SIGTERM não chega ao node).

### Ler juntos: [`hands-on/lab02-multi-stage/Dockerfile`](hands-on/lab02-multi-stage/Dockerfile)
Comparar com o original [`backend/Dockerfile`](backend/Dockerfile) e com o frontend (Vite build → nginx: o node nem existe na imagem final).

### Vantagens e desvantagens

| | Single-stage | Multi-stage |
|---|---|---|
| Tamanho | grande (toolchain + fontes) | só o necessário para rodar |
| Superfície de ataque / CVEs | alta | baixa |
| Secrets/fontes no artefato | risco alto | ficam no stage de build |
| Cache | invalida tudo com frequência | stages independentes, cache em paralelo |
| Simplicidade / leitura | ✅ simples | mais linhas, exige entender stages |
| Debug em produção | shell e ferramentas disponíveis | imagem enxuta, às vezes sem shell |
| Uso em dev | um Dockerfile só | `--target builder` para dev/test |

- `docker build --target builder` → imagem para rodar testes no CI com o mesmo Dockerfile
- Stages sem dependência entre si são construídos **em paralelo** pelo BuildKit
- Go: `make lab-go` → `handson/api-go:single` (1.375 MB, root, 146 HIGH) x `:scratch` (9 MB, 0 CVEs) é o argumento definitivo

**Transição:** "Multi-stage resolve o tamanho. Agora vamos escrever o Dockerfile *bem* do começo ao fim."

---

## Bloco 4 — Construindo seu Dockerfile: boas práticas + BuildKit (15 min)

### Passo a passo para containerizar uma app (8 min)
1. **Entenda o runtime:** linguagem, versão, porta, variáveis de ambiente, onde grava arquivos
2. **Escolha a base** (bloco 2) e fixe a versão (`node:22-alpine`, depois o digest)
3. **`.dockerignore` primeiro** (ver [`backend/.dockerignore`](backend/.dockerignore)): `node_modules`, `.git`, `.env`, `dist`
4. **Ordem de camadas**: do que muda menos para o que muda mais
   `FROM → deps do SO → manifest de deps (package*.json, go.mod) → install → código → build`
5. **Install determinístico**: `npm ci`, `go mod download`, `pip install -r` com hashes
6. **Multi-stage**: build num stage, runtime em outro
7. **Usuário não-root**: `USER node` / `USER 65532`; arquivos da app com dono root (só leitura para a app)
8. **Metadados**: `EXPOSE`, `HEALTHCHECK`, `LABEL org.opencontainers.image.source=...`
9. **CMD em exec form** (`["node","dist/main.js"]`): o processo vira PID 1 e recebe SIGTERM
10. **Config por ambiente**, nunca no build: `ENV` para defaults e `ARG` só para build; **secrets nunca** em ARG/ENV/COPY

### Checklist para o participante levar
- [ ] base oficial, versão fixa (idealmente digest)
- [ ] `.dockerignore`
- [ ] manifest de deps copiado antes do código
- [ ] multi-stage
- [ ] `USER` não-root
- [ ] `HEALTHCHECK` (ou probe no orquestrador)
- [ ] exec form no `CMD`/`ENTRYPOINT`
- [ ] nenhum secret em camada
- [ ] passou no hadolint e no `trivy config`

### BuildKit (7 min)
```bash
make lab-cache
```
- **Ordem das camadas** ([`cache-demo.sh`](hands-on/scripts/cache-demo.sh)): altera 1 linha de `backend/src/main.ts` e rebuilda. Medido: **8 s** (deps antes do código, `npm ci` em `CACHED`) x **45 s** (`Dockerfile.bad-order`, reinstala tudo). O script restaura o arquivo no final
- `RUN --mount=type=cache,target=/root/.npm`: o cache do npm sobrevive até a `--no-cache`. Ganha com rede lenta ou muitas deps; **com rede rápida não mudou o tempo** (~40 s nos dois casos, o gargalo é o `tsc`)
- `RUN --mount=type=secret,id=npmrc`: token de registry privado sem virar camada
- `--build-context lab=...`: contexto extra nomeado (usado no `lab04-hardening/Dockerfile`)
- Multi-arch (demo do palestrante):
  ```bash
  docker buildx create --use --name multi
  docker buildx build --platform linux/amd64,linux/arm64 -f hands-on/api-go/Dockerfile.scratch hands-on/api-go
  ```

---

## Intervalo (5 min)

Deixe rodando durante o intervalo: `make lab-scan` (o primeiro download do banco do Trivy demora).

---

## Bloco 5 — Scan de vulnerabilidades e supply chain (15 min)

### Fala sugerida
> "A imagem que você publica tem o seu código e mais centenas de pacotes que você não escreveu. Scan não é opcional: é inventário."

### Camadas de verificação

| Quando | Ferramenta | O que pega |
|---|---|---|
| Ao escrever o Dockerfile | **hadolint**, `trivy config` | root, `latest`, `apt` sem limpeza, falta de HEALTHCHECK |
| Antes do commit | `trivy fs --scanners secret` | chaves e senhas no repo |
| Após o build | **`trivy image`** (ou Docker Scout / Grype) | CVEs do SO e das libs |
| Na publicação | **SBOM** (CycloneDX/SPDX), **cosign** | inventário e procedência |
| Em produção | rescan periódico do registry | CVEs novas em imagem antiga |

### Hands-on
```bash
make lab-lint      # hadolint: single x multi
make lab-scan      # trivy image + config + secret
make lab-sbom      # SBOM CycloneDX
```
- Abrir `reports/trivy-single.html` (template do repo: `infra/trivy/html.tpl`)
- **hadolint x `trivy config` (medido):** o hadolint quase não reclama do lab01 (só `DL3059`); quem acusa falta de USER não-root e de HEALTHCHECK é o `trivy config`. Mas o `trivy config` também acusa `DS-0002` no distroless/Chainguard, que já são nonroot pela base: falso positivo para discutir
- **Secret scan (medido):** **não** acha o `DD_SECRET_KEY` do `docker-compose.yml` da palestra AppSec. Segredo genérico (sem prefixo conhecido como `AKIA`, `ghp_`) precisa de regra customizada ou de outra ferramenta (gitleaks). Bom gancho: "o scanner passou, então está seguro?"
- `--ignore-unfixed` e `--exit-code 1 --severity CRITICAL` para quebrar o pipeline só no que é acionável
- Relembrar o pipeline real: [`.github/workflows/appsec.yml`](.github/workflows/appsec.yml) (Trivy no CI + DefectDojo)

### Supply chain
- **Pin por digest** + Renovate/Dependabot para atualizar via PR
- **SBOM**: "lista de ingredientes"; dá para reescanear sem a imagem (`trivy sbom`)
- **Assinatura** com cosign e verificação na admissão (opcional: [`hands-on/lab06-supply-chain/README.md`](hands-on/lab06-supply-chain/README.md))
- **Rebuild frequente**: CVE corrigido na base só chega até você se você rebuildar

**Transição:** "Imagem limpa é metade do caminho. A outra metade é *como* ela roda."

---

## Bloco 6 — Hardening do runtime (10 min)

### O problema real deste repositório
`frontend/Dockerfile` usa `nginx:1.27-alpine`: o nginx sobe como **root**, ouvindo na porta 80, sem healthcheck.

### Hands-on
```bash
make lab-hardening
docker exec handson-hardening-frontend-1 id                 # uid=101(nginx), não root
docker exec handson-hardening-frontend-1 touch /etc/x       # Read-only file system
docker inspect -f '{{.State.Health.Status}}' handson-hardening-frontend-1
curl -s localhost:8080 | head -5
make lab-hardening-down
```

| Controle | Onde | Mitiga |
|---|---|---|
| `USER` não-root / `nginx-unprivileged` | Dockerfile | escape de container com privilégio |
| `read_only: true` + `tmpfs` | compose/stack | persistência de malware, alteração de binários |
| `cap_drop: [ALL]` | compose | uso de capabilities do kernel |
| `no-new-privileges` | compose | escalada via setuid |
| `mem_limit`, `cpus`, `pids_limit` | compose | DoS e fork bomb, vizinho barulhento |
| Porta só na rede interna | compose (backend sem `ports`) | exposição desnecessária |
| Headers de segurança, `server_tokens off` | `nginx.conf` | fingerprinting, clickjacking |

Arquivos: [`hands-on/lab04-hardening/`](hands-on/lab04-hardening/)

---

## Bloco 7 — Comandos de rotina Docker (10 min)

Roteiro guiado com o stack hardening ou o `docker compose` principal. Distribua o [`CHEATSHEET.md`](hands-on/CHEATSHEET.md).

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs -f --tail 50 <container>
docker exec -it <container> sh
docker stats --no-stream
docker inspect -f '{{.State.Health.Status}} {{.HostConfig.Memory}}' <container>
docker diff <container>
docker network inspect handson-hardening_handson
docker system df
docker system prune         # mostrar o que será removido antes de confirmar
```

**Exercício relâmpago (2 min):** "Descubra quanta memória o backend está usando e qual é o limite dele" → `docker stats` + `docker inspect`.

**Troubleshooting**: exit 137 (OOM), `exec format error` (arquitetura), binário glibc em alpine (ver a tabela no fim do cheat sheet).

---

## Bloco 8 — Docker Swarm (15 min)

### Conceitos (4 min)
```
Swarm   = cluster de nós Docker (managers com Raft + workers)
Service = estado desejado (imagem, réplicas, rede, limites) → o Swarm cria tasks
Task    = 1 container agendado num nó
Stack   = conjunto de services descrito num compose file (docker stack deploy)
```
- Rede **overlay** entre nós + **routing mesh** (a porta publicada responde em qualquer nó)
- Secrets e configs nativos (em `/run/secrets`, tmpfs, criptografados no Raft)
- Swarm x Kubernetes: Swarm é simples e embutido no Docker, bom para ambientes pequenos e médios; K8s é o padrão para escala e ecossistema

### Hands-on (11 min)
```bash
make swarm-init                      # PWD: make swarm-init ADVERTISE_ADDR=$(hostname -i)
make lab-hardening-build lab-go      # imagens usadas pelo stack
make swarm-deploy                    # PWD multi-nó: make swarm-registry e depois REGISTRY=127.0.0.1:5000/
docker stack services bmi
curl -s -X POST localhost:8080/api/bmi/calculate -H 'Content-Type: application/json' -d '{"weight":70,"height":1.75}'

make swarm-scale                     # backend 2 → 4
make swarm-update                    # rolling update: NestJS → Go (mesmo contrato!), start-first
                                     # medido: 237 requisições durante o update, 0 falhas
watch docker service ps bmi_backend  # tasks antigas Shutdown, novas Running
make swarm-rollback                  # volta para NestJS
docker service logs bmi_backend --tail 20
docker exec $(docker ps -q -f name=bmi_backend | head -1) cat /run/secrets/bmi_api_key
make swarm-down
```
- Em multi-nó: `docker node update --availability drain <nó>` e ver as tasks migrarem
- Ler [`hands-on/lab07-swarm/stack.yml`](hands-on/lab07-swarm/stack.yml): `update_config`, `failure_action: rollback`, `resources`, `secrets`
- Pegadinha real da validação: o secret é montado com dono root e modo `0400`, e o backend roda como `node` → `Permission denied`. Por isso o stack declara `uid: "1000"`

> O rolling update troca a implementação (Node → Go) sem downtime porque as duas respeitam o mesmo contrato HTTP e o mesmo healthcheck. Esse é o argumento para APIs com contrato bem definido.

---

## Bloco 9 — Encerramento (5 min)

### Revotação
> "Depois de tudo: Alpine ou distroless?" Compare com o placar da abertura e peça para quem mudou de lado explicar o motivo.

### Recapitulando o placar
Projete a tabela final do `make lab-compare`: de `backend:single` (2.070 MB, root, 25 CRITICAL e 537 HIGH) a `api-go:scratch` (9 MB, não-root, 0 CVEs).

### Próximos passos
- Levar o checklist do bloco 4 para os Dockerfiles do time
- Colocar `hadolint` + `trivy image --exit-code 1` no pipeline
- Explorar: Docker Scout, Chainguard/Docker Hardened Images, Kubernetes (Pod Security, probes, requests/limits)
- Repositório da palestra AppSec: [`roteiro-palestra.md`](roteiro-palestra.md) (DAST, SCA, DefectDojo)

### Perguntas
Sugestões para puxar o debate:
- "Alpine ou distroless para Node em produção?"
- "Quem aqui já teve problema de módulo nativo em Alpine?"
- "Vale a pena Swarm em 2026?"

---

## Plano B

| Problema | Saída |
|---|---|
| Rede lenta / rate limit do Docker Hub | imagens pré-baixadas (`make lab-prepull` na véspera), `docker save`/`docker load` via pendrive, espelho `public.ecr.aws/docker/library/node` |
| Trivy demorando no 1º download do DB | rodar `make lab-scan` no intervalo; ter `reports/` pré-gerado |
| Participante sem Docker | Play with Docker (sessão de 4 h) |
| PWD sem buildx multi-arch / sem `docker debug` | só demo do palestrante |
| Swarm multi-nó falhando | single-node (`REGISTRY` vazio) cobre todos os comandos, exceto o drain |
| Tempo estourado | cortar o 1.2 para uma tabela e o bloco 7 para o exercício relâmpago |
| `lab-duel` lento (scan de 3 imagens) | rodar só `make lab-duel DUEL="handson/backend:alpine handson/backend:distroless"` ou mostrar `reports/duel/` pré-gerado |
