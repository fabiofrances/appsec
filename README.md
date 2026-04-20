# AppSec Palestra — Calculadora de IMC

Repositório didático para palestra sobre **Application Security (AppSec)**, demonstrando como integrar segurança ao ciclo de desenvolvimento de uma aplicação real.

## Visão Geral

Aplicação de cálculo de IMC (Índice de Massa Corporal) construída com boas práticas de desenvolvimento e ferramentas de segurança integradas ao pipeline.

## Etapas do Projeto

| # | Etapa | Status |
|---|-------|--------|
| 1 | Backend NestJS com Swagger, OpenTelemetry e Prometheus | ✅ Concluído |
| 2 | Frontend Vue.js | 🔲 Pendente |
| 3 | Testes (backend + frontend) | 🔲 Pendente |
| 4 | AppSec (Trivy, OWASP ZAP, Dependency Check, DefectDojo) | 🔲 Pendente |

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

## Princípios Aplicados

- **SOLID:** cada classe tem responsabilidade única (Service, Controller, DTO separados)
- **MVC:** Controller → Service → DTO
- **Validação na borda:** `ValidationPipe` global com `whitelist: true`
- **Observabilidade:** traces via OTLP, métricas via Prometheus
- **Segurança no container:** imagem `node:22-alpine`, usuário `node` (não-root), multi-stage build
