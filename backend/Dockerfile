FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine AS production
WORKDIR /app
# zlib 1.3.2-r1 da base tem CVE-2026-4738; 1.4-r0 já está no Alpine (remover quando a base atualizar)
RUN apk upgrade --no-cache zlib
ENV NODE_ENV=production
COPY package*.json ./
# npm/npx/corepack vêm na imagem base mas não são usados em runtime: removê-los tira
# do scan as CVEs do próprio npm (pacote, sigstore, brace-expansion...)
RUN npm ci --omit=dev && npm cache clean --force \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
              /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack
COPY --from=builder /app/dist ./dist
EXPOSE 3000
EXPOSE 9464
USER node
CMD ["node", "dist/main.js"]
