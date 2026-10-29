# syntax=docker/dockerfile:1
# Lab 04 — Frontend endurecido (compare com frontend/Dockerfile, onde o nginx roda como root)
# Build (usa um "named context" do BuildKit para pegar o nginx.conf deste lab):
#   docker build -f hands-on/lab04-hardening/Dockerfile \
#     --build-context lab=hands-on/lab04-hardening \
#     -t handson/frontend:hardened frontend

# ── Stage 1: build do Vue com Vite ──────────────────────────────────────────
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

# ── Stage 2: nginx sem root (uid 101), porta 8080 ───────────────────────────
FROM nginxinc/nginx-unprivileged:1.27-alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=lab nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:8080/"]
