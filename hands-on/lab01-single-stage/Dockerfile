# Lab 01 — Single-stage (ANTIPADRÃO proposital)
# Build: docker build -f hands-on/lab01-single-stage/Dockerfile -t handson/backend:single backend
#
# Problemas que vamos medir/discutir:
#  - imagem base "full" (Debian + toolchain completa: gcc, python, git...)
#  - COPY . . antes de instalar deps → qualquer mudança no código invalida o cache do npm
#  - npm install (não determinístico) em vez de npm ci
#  - devDependencies (TypeScript, Nest CLI, Jest, ESLint) vão para produção
#  - código-fonte .ts junto do build
#  - roda como root
#  - CMD via npm (sinais SIGTERM não chegam direto ao node)
FROM node:22

WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

EXPOSE 3000 9464
CMD ["npm", "run", "start:prod"]
