# Lab 06 — Scan de vulnerabilidades e supply chain

Pré-requisito: imagens dos labs 01–03 construídas (`make lab-single lab-multi lab-bases`).

## 1. Lint do Dockerfile (antes do build)

```bash
make lab-lint
```

Rode o hadolint no `lab01-single-stage/Dockerfile` e no `lab02-multi-stage/Dockerfile` e compare os avisos (`DL3016`, `DL3002`, `DL3025`...).

## 2. Vulnerabilidades e misconfigurations

```bash
make lab-scan
```

| Comando | Scanner | O que encontra |
|---|---|---|
| `trivy image handson/backend:single` | vuln | CVEs de pacotes do SO e dependências npm |
| `trivy config hands-on/` | misconfig | Dockerfile rodando como root, sem HEALTHCHECK, `latest`... |
| `trivy fs --scanners secret .` | secret | chaves e senhas commitadas (veja `docker-compose.yml`) |

Relatório HTML com o template do repo (`infra/trivy/html.tpl`):

```bash
hands-on/scripts/trivy.sh image --format template --template @infra/trivy/html.tpl \
  -o reports/trivy-single.html handson/backend:single
```

Quebrar o pipeline só quando houver CRITICAL corrigível:

```bash
hands-on/scripts/trivy.sh image --exit-code 1 --severity CRITICAL --ignore-unfixed handson/backend:multi
```

## 3. SBOM (Software Bill of Materials)

```bash
make lab-sbom                       # reports/sbom-*.cdx.json (CycloneDX)
hands-on/scripts/trivy.sh sbom reports/sbom-multi.cdx.json   # escaneia o SBOM, sem a imagem
```

## 4. Pin por digest

```bash
docker buildx imagetools inspect node:22-alpine     # mostra o digest do índice multi-arch
# FROM node:22-alpine@sha256:<digest>
```

Tag é mutável, digest não. Ferramentas como Renovate/Dependabot atualizam o digest via PR.

## 5. Assinatura com cosign (opcional, requer registry)

```bash
make swarm-registry                                  # registry local em 127.0.0.1:5000
docker tag handson/backend:multi 127.0.0.1:5000/handson/backend:multi
docker push 127.0.0.1:5000/handson/backend:multi
docker run --rm -it -v "$PWD:/w" -w /w --network host ghcr.io/sigstore/cosign/cosign:v2.4.1 generate-key-pair
docker run --rm -it -v "$PWD:/w" -w /w --network host ghcr.io/sigstore/cosign/cosign:v2.4.1 \
  sign --key cosign.key --allow-insecure-registry 127.0.0.1:5000/handson/backend:multi
docker run --rm -v "$PWD:/w" -w /w --network host ghcr.io/sigstore/cosign/cosign:v2.4.1 \
  verify --key cosign.pub --allow-insecure-registry 127.0.0.1:5000/handson/backend:multi
```

> Não commite `cosign.key`.
