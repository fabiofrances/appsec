#!/bin/bash
# Demo de cache de camadas: altera 1 linha de código e rebuilda dois Dockerfiles.
#  - lab05-buildkit/Dockerfile          → package*.json antes do código: npm ci fica em CACHED
#  - lab05-buildkit/Dockerfile.bad-order → COPY . . antes do npm ci: reinstala tudo
# Usage: bash hands-on/scripts/cache-demo.sh   (na raiz do repo)

set -euo pipefail

SRC="backend/src/main.ts"
BACKUP="$(mktemp)"
cp "$SRC" "$BACKUP"
trap 'cp "$BACKUP" "$SRC"; rm -f "$BACKUP"' EXIT   # restaura o código sempre

build() {  # $1 = Dockerfile, $2 = tag → imprime segundos
  local start=$SECONDS
  docker build -q -f "$1" -t "$2" backend >/dev/null
  echo $((SECONDS - start))
}

echo "▶ Aquecendo o cache (1º build de cada)..."
build hands-on/lab05-buildkit/Dockerfile handson/backend:buildkit >/dev/null
build hands-on/lab05-buildkit/Dockerfile.bad-order handson/backend:bad-order >/dev/null

echo "▶ Alterando 1 linha em $SRC e rebuildando..."
echo "// cache-demo $(date +%s)" >> "$SRC"
GOOD=$(build hands-on/lab05-buildkit/Dockerfile handson/backend:buildkit)
BAD=$(build hands-on/lab05-buildkit/Dockerfile.bad-order handson/backend:bad-order)

echo ""
echo "| Dockerfile | Rebuild após mudar 1 linha de código |"
echo "|---|---|"
echo "| \`lab05-buildkit/Dockerfile\` (deps antes do código) | ${GOOD}s |"
echo "| \`lab05-buildkit/Dockerfile.bad-order\` (COPY . . primeiro) | ${BAD}s |"
