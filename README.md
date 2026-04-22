# AppSec Palestra — Calculadora de IMC

Repositório didático para palestra sobre **Application Security (AppSec)**, demonstrando como integrar segurança ao ciclo de desenvolvimento de uma aplicação real.

## Visão Geral

Aplicação de cálculo de IMC (Índice de Massa Corporal) construída com boas práticas de desenvolvimento e ferramentas de segurança integradas ao pipeline.

## Etapas do Projeto

| # | Etapa | Status |
|---|-------|--------|
| 1 | Backend NestJS com Swagger, OpenTelemetry e Prometheus | ✅ Concluído |
| 2 | Frontend Vue.js | ✅ Concluído |
| 3 | Testes (backend + frontend) | ✅ Concluído |
| 4 | AppSec (Trivy, OWASP ZAP, Dependency Check, DefectDojo) | ✅ Concluído |

---

## Etapa 1 — Backend

### Stack

- **Runtime:** Node.js 22
- **Framework:** NestJS 11
- **Documentação:** Swagger (`@nestjs/swagger`)
- **Validação:** `class-validator` + `class-transformer`
- **Observabilidade:** OpenTelemetry SDK + Prometheus (`prom-client`)
- **Health check:** `@nestjs/terminus`

### Estrutura

```
backend/
├── src/
│   ├── bmi/
│   │   ├── dto/
│   │   │   ├── calculate-bmi.dto.ts   # Validação de entrada (weight, height)
│   │   │   └── bmi-result.dto.ts      # Shape da resposta
│   │   ├── bmi.controller.ts          # POST /bmi/calculate
│   │   ├── bmi.service.ts             # Lógica de cálculo + métricas
│   │   └── bmi.module.ts
│   ├── health/
│   │   ├── health.controller.ts       # GET /health
│   │   └── health.module.ts
│   ├── telemetry/
│   │   └── telemetry.ts               # Bootstrap OpenTelemetry + OTLP exporter
│   ├── app.module.ts
│   └── main.ts                        # Bootstrap NestJS + Swagger + ValidationPipe
├── Dockerfile                         # Multi-stage build (builder + production)
└── package.json
```

### Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/bmi/calculate` | Calcula o IMC |
| `GET` | `/health` | Health check da aplicação |
| `GET` | `/api/docs` | Swagger UI |
| `GET` | `:9464/metrics` | Métricas Prometheus |

### Exemplo de uso

**Request:**
```json
POST /bmi/calculate
{
  "weight": 70,
  "height": 1.75
}
```

**Response:**
```json
{
  "bmi": 22.86,
  "classification": "Normal weight",
  "weight": 70,
  "height": 1.75
}
```

### Classificações de IMC (OMS)

| IMC | Classificação |
|-----|---------------|
| < 16 | Severe underweight |
| 16 – 18.4 | Underweight |
| 18.5 – 24.9 | Normal weight |
| 25 – 29.9 | Overweight |
| 30 – 34.9 | Obesity class I |
| 35 – 39.9 | Obesity class II |
| ≥ 40 | Obesity class III |

### Métricas Prometheus

| Métrica | Tipo | Descrição |
|---------|------|-----------|
| `bmi_calculations_total` | Counter | Total de cálculos por classificação |
| `bmi_value_distribution` | Histogram | Distribuição dos valores de IMC |

### Executar localmente

```bash
cd backend

# Desenvolvimento (hot reload)
npm run start:dev

# Produção
npm run build
npm run start:prod
```

### Docker

```bash
cd backend
docker build -t appsec-bmi-backend .
docker run -p 3000:3000 -p 9464:9464 appsec-bmi-backend
```

---

## Etapa 2 — Frontend

### Stack

- **Framework:** Vue.js 3 (Composition API)
- **Build tool:** Vite
- **Linguagem:** TypeScript
- **HTTP client:** Axios
- **Roteamento:** Vue Router
- **Testes:** Vitest

### Estrutura

```
frontend/
├── src/
│   ├── components/
│   │   ├── BmiForm.vue        # Formulário de entrada (peso + altura)
│   │   └── BmiResult.vue      # Exibição do resultado com cor por classificação
│   ├── composables/
│   │   └── useBmi.ts          # Estado reativo + chamada à API
│   ├── services/
│   │   └── bmi.service.ts     # Axios client para POST /bmi/calculate
│   ├── types/
│   │   └── bmi.types.ts       # Interfaces TypeScript (BmiRequest, BmiResult)
│   ├── views/
│   │   └── HomeView.vue       # Página principal orquestrando os componentes
│   ├── router/index.ts
│   └── main.ts
├── Dockerfile                 # Multi-stage: Vite build + Nginx
├── nginx.conf                 # SPA fallback + proxy para /api/
├── .env                       # VITE_API_URL=http://localhost:3000
└── .env.production            # VITE_API_URL=http://backend:3000
```

### Executar localmente

```bash
cd frontend
npm run dev        # http://localhost:5173
npm run build      # build de produção
```

### Docker

```bash
cd frontend
docker build -t appsec-bmi-frontend .
docker run -p 80:80 appsec-bmi-frontend
```

---

---

## Etapa 3 — Testes

### Backend (Jest)

| Suíte | Testes | Cobertura |
|-------|--------|-----------|
| `bmi.service.spec.ts` | 9 (todas as 7 classificações + valor + campos) | Lógica de negócio |
| `bmi.controller.spec.ts` | 3 (definição, resultado, delegação) | Camada de controle |
| `app.e2e-spec.ts` | 6 (POST /bmi/calculate: sucesso + 4 erros de validação; GET /health) | Integração |

```bash
cd backend
npm test              # unit tests
npm run test:e2e      # e2e tests
npm run test:cov      # coverage report
```

### Frontend (Vitest)

| Suíte | Testes |
|-------|--------|
| `BmiForm.spec.ts` | Renderização e envio do formulário |
| `BmiResult.spec.ts` | Exibição, cores por classificação, evento reset |
| `bmi.service.spec.ts` | Chamada à API via Axios |
| `useBmi.spec.ts` | Composable: estados loading/error/result |

```bash
cd frontend
npm run test:unit     # run once
npm run test:unit -- --watch  # watch mode
```

---

## Etapa 4 — AppSec

### Arquitetura de Segurança

```
                    ┌─────────────┐
                    │  GitHub CI  │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌──────────────┐ ┌──────────┐ ┌──────────────┐
    │  Dep. Check  │ │  Trivy   │ │  OWASP ZAP   │
    │    (SCA)     │ │(Container│ │   (DAST)     │
    │              │ │  Scan)   │ │              │
    └──────┬───────┘ └────┬─────┘ └──────┬───────┘
           └──────────────┼──────────────┘
                          ▼
                   ┌────────────┐
                   │ DefectDojo │
                   │(Aggregator)│
                   └────────────┘
```

### Ferramentas

| Ferramenta | Tipo | O que analisa |
|-----------|------|---------------|
| **OWASP Dependency Check** | SCA | Vulnerabilidades em dependências npm |
| **Trivy** | Container Scan | CVEs nas imagens Docker |
| **OWASP ZAP** | DAST | Vulnerabilidades em runtime (HTTP) |
| **DefectDojo** | Aggregator | Centraliza e prioriza todos os findings |

### Subir o ambiente completo

```bash
# Na raiz do projeto
docker compose up -d

# Serviços disponíveis:
# http://localhost       → Frontend (Vue.js)
# http://localhost:3000  → Backend (NestJS)
# http://localhost:3000/api/docs → Swagger UI
# http://localhost:9464/metrics  → Prometheus metrics
# http://localhost:9090  → Prometheus
# http://localhost:16686 → Jaeger UI
# http://localhost:8080  → DefectDojo (admin / admin@dojo123)
```

### Configurar DefectDojo para o CI/CD

```bash
# Após subir o DefectDojo localmente:
sh infra/defectdojo/setup.sh

# O script imprime os 3 secrets a configurar no GitHub:
# DEFECTDOJO_URL, DEFECTDOJO_TOKEN, DEFECTDOJO_PRODUCT_ID
```

### Pipeline GitHub Actions (`.github/workflows/appsec.yml`)

O pipeline roda automaticamente em push/PR para `main`:

1. **Tests** — backend (Jest) + frontend (Vitest)
2. **Dependency Check** — analisa `package-lock.json` de backend e frontend
3. **Trivy** — escaneia as imagens `bmi-backend:ci` e `bmi-frontend:ci`
4. **ZAP** — sobe o stack via Docker Compose e faz DAST na aplicação rodando

Todos os relatórios são:
- Salvos como artefatos no GitHub Actions
- Importados automaticamente no DefectDojo (quando secrets configurados)

---

## Princípios Aplicados

- **SOLID:** cada classe tem responsabilidade única (Service, Controller, DTO separados)
- **MVC:** Controller → Service → DTO
- **Validação na borda:** `ValidationPipe` global com `whitelist: true`
- **Observabilidade:** traces via OTLP, métricas via Prometheus
- **Segurança no container:** imagem `node:22-alpine`, usuário `node` (não-root), multi-stage build
