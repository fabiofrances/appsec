FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.30-alpine AS production
# Pacotes da base com CVE já corrigida no Alpine (apontados pelo scan do Harbor):
#   libxslt 1.1.43-r3 -> r4 (2 HIGH), zlib 1.3.2-r1 -> 1.4-r0 (CVE-2026-4738, MEDIUM).
# Remover esta linha quando a nginx:1.30-alpine for republicada com essas versões.
RUN apk upgrade --no-cache libxslt zlib
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
