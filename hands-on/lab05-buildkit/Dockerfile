# syntax=docker/dockerfile:1
# Lab 05 — BuildKit: cache mount + secret mount + ordem de camadas
# Build: docker build -f hands-on/lab05-buildkit/Dockerfile -t handson/backend:buildkit backend
#
# Demonstrações:
#  1. --mount=type=cache   → o cache do npm sobrevive até a um build com --no-cache
#  2. --mount=type=secret  → .npmrc com token de registry privado NUNCA vira camada
#       docker build --secret id=npmrc,src=$HOME/.npmrc ...
#     (opcional: sem o --secret o build continua funcionando)
#  3. ordem: package*.json → npm ci → código. Alterar src/ não reinstala dependências.
ARG NODE_VERSION=22

FROM node:${NODE_VERSION}-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci --omit=dev

FROM node:${NODE_VERSION}-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci
COPY . .
RUN npm run build

FROM node:${NODE_VERSION}-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
COPY package.json ./
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
USER node
EXPOSE 3000 9464
CMD ["node", "dist/main.js"]
