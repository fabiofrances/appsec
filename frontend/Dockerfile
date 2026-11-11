FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.30-alpine AS production
# libxslt 1.1.43-r3 da base tem 2 CVEs HIGH; r4 já existe no Alpine.
# Remover esta linha quando a nginx:1.30-alpine for republicada com o r4.
RUN apk upgrade --no-cache libxslt
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
