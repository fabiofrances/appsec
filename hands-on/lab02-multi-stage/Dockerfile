# syntax=docker/dockerfile:1
# Lab 02 — Multi-stage (evolução do backend/Dockerfile da palestra AppSec)
# Build: docker build -f hands-on/lab02-multi-stage/Dockerfile -t handson/backend:multi backend
#
# Diferenças em relação ao backend/Dockerfile original:
#  - stage "deps" separado: node_modules de produção é resolvido uma vez e só copiado
#  - código da app fica com dono root → o usuário "node" não consegue alterá-lo em runtime
#  - HEALTHCHECK usando o wget do busybox (existe no alpine)

# ── Stage 1: dependências de produção ───────────────────────────────────────
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ── Stage 2: build (TypeScript → JavaScript) ────────────────────────────────
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ── Stage 3: runtime ────────────────────────────────────────────────────────
FROM node:22-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
COPY package.json ./
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
USER node
EXPOSE 3000 9464
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "dist/main.js"]
