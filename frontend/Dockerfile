FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# nginx sem root (uid 101), ouvindo na 8080: o gate de SAST (Semgrep, regra missing-user)
# reprovava a versão anterior, que rodava o nginx como root na porta 80.
# Linha mainline (1.31): a 1.30.6 tinha CVEs CRITICAL com correção só na 1.30.7, ainda não
# publicada na nginx-unprivileged (o próprio nginx.org recomenda a mainline em produção).
FROM nginxinc/nginx-unprivileged:1.31-alpine AS production
# A base demora a ser republicada; o apk upgrade aplica as correções do Alpine já disponíveis
# (curl, libexpat, musl, brotli, zlib, libxslt...). O gate do Trivy no CI pega o que sobrar.
USER root
RUN apk upgrade --no-cache
USER 101
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:8080/"]
